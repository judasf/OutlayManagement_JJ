<%@ Page Language="C#" %>

<!-- 公用经费支出管理——现金支付明细——基层用户 -->
<script type="text/javascript">
    //现金支出单笔凭证处理对话框
    var showCashDetail = function (id) {
        var dialog = parent.$.modalDialog({
            title: '现金支出凭证明细',
            width: 400,
            height: 450,
            iconCls: 'ext-icon-note',
            href: 'OutlayReimburse/dialogop/CashReimDetail_op.aspx?id=' + id,
            buttons: [{
                text: '关闭',
                handler: function () {
                    dialog.dialog('close');
                }
            }]
        });
    };
    //送审待送审的公用经费现金支出
    var sendCashReimburse = function (id) {
        parent.$.messager.confirm('送审支出', '您确认要送审该项支出？', function (r) {
            if (r) {
                $.post('../service/ReimburseOutlay.ashx/SendCashReimburse',
                { id: id },
                function (result) {
                    if (result.success) {
                        cashGrid.datagrid('reload');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //删除待送审的公用经费现金支出
    var removeCashReimburse = function (id) {
        parent.$.messager.confirm('删除确认', '您确认要删除该项支出？', function (r) {
            if (r) {
                $.post('../service/ReimburseOutlay.ashx/RemoveCashReimburse',
                { id: id },
                function (result) {
                    if (result.success) {
                        cashGrid.datagrid('reload');
                        publicGrid.datagrid('reload');
                        parent.$.messager.alert('成功', result.msg, 'info');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //导出现金报销excel
    var exportCashReimburse = function () {
        jsPostForm('../service/ReimburseOutlay.ashx/ExportUserPublicCashReimburse?type=1', $.serializeObject($('#searchForm')));
    };
    //现金支出表
    var cashGrid;
    $(function () {
        //cashGrid 现金支出表
        cashGrid = $('#cashGrid').datagrid({
            title: '现金支出明细',
            url: '../service/ReimburseOutlay.ashx/GetCashPay?type=1',
            striped: true,
            rownumbers: true,
            pagination: true,
            noheader: true,
            showFooter: true,
            pageSize: 10,
            singleSelect: true,
            idField: 'id',
            sortName: 'id',
            sortOrder: 'desc',
            columns: [
              [{
                  width: '80',
                  title: '办理编号',
                  field: 'reimburseno',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '单位名称',
                  field: 'deptname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '申请日期',
                  field: 'reimbursedate',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '支出金额',
                  field: 'reimburseoutlay',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '审核金额',
                  field: 'auditcashoutlay',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '支出科目',
                  field: 'expensesubject',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '120',
                  title: '支出摘要',
                  field: 'memo',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '70',
                  title: '经办人',
                  field: 'username',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '70',
                  title: '报销人',
                  field: 'reimburseuser',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '审核状态',
                  field: 'status',
                  sortable: true,
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row, index) {
                      switch (value) {
                          case '-1':
                              return '被稽核退回';
                              break;
                          case '0':
                              return '待送审'
                              break;
                          case '1':
                              return '待审核'
                              break;
                          case '2': //被出纳退回给稽核，基层用户显示为出纳退回，当被稽核退回时status为-1
                              return '被出纳退回'
                              break;
                          case '3':
                              return '已审核'
                              break;
                          case '4':
                              return '已审核部分退回'
                              break;
                      }
                  }
              }, {
                  width: '60',
                  title: '结报状态',
                  field: 'finishstatus',
                  sortable: true,
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row, index) {
                      switch (value) {
                          case '0':
                              return '待受理'
                              break;
                          case '1':
                              return '已受理'
                              break;
                          case '2':
                              return '已办结'
                              break;
                      }
                  }
              }
              , {
                  title: '操作',
                  field: 'action',
                  width: '60',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row) {
                      var str = '';
                      if (row.status == 0) { //基层用户，待送审的支出申请可以送审或删除
                          str += $.formatString('<a href="javascript:void(0)" onclick="sendCashReimburse(\'{0}\');">送审</a>&nbsp;', row.id);
                          str += $.formatString('<a href="javascript:void(0)" onclick="removeCashReimburse(\'{0}\');">删除</a>', row.id);

                      }
                      return str;
                  }
              }, {
                  width: '150',
                  title: '稽核意见',
                  field: 'auditorcomment',
                  halign: 'center',
                  align: 'center'
              }
              ]
            ],
            toolbar: '#cgTip',
            onLoadSuccess: function (data) {
                if (data.rows.length == 0) {
                    var body = $(this).data().datagrid.dc.body2;
                    body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                }
                //提示框
                $(this).datagrid('tooltip', ['memo', 'auditorcomment']);
            },
            onDblClickRow: function (index, row) {
                showCashDetail(row.id);
            }
        });
        //设置分页属性
        var pager = $('#cashGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<div id="cgTip">
    <form id="searchForm" style="margin: 0;">
        <table>
            <tr>
                <td width="60" align="right">日期：
                </td>
                <td>
                    <input style="width: 80px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')}',maxDate:'%y-%M-%d'})"
                        readonly="readonly" />-<input style="width: 80px;" name="edate" id="edate" class="Wdate"
                            onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                </td>
                <td width="60" align="right">审核：
                </td>
                <td>
                    <input style="width: 105px" name="status" id="status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'-1','text':'被稽核退回'},{'value':'0','text':'待送审'},{'value':'1','text':'待审核'},{'value':'2','text':'被出纳退回'},{'value':'3','text':'已审核'},{'value':'4','text':'已审核部分退回'}]" />
                </td>
                <td width="60" align="right">结报：
                </td>
                <td>
                    <input style="width: 60px" name="finishstatus" id="finishstatus" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'0','text':'待受理'},{'value':'2','text':'已办结'}],onSelect:function(rec){(rec.value>0)&&$('#searchForm').find('#status').combobox('setValue','3');}" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="cashGrid.datagrid('load', $.serializeObject($('#searchForm')));">查询</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                        onclick="  $('#searchForm input').val('');cashGrid.datagrid('load', {});">重置</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                        onclick="exportCashReimburse();">导出</a>
                </td>
            </tr>
        </table>
    </form>
    <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px; line-height: 24px; padding-left: 30px;">
        双击现金支出明细查看每笔支出凭证以及每笔凭证的状态，可取回被退回的金额
    </div>
</div>
<table id="cashGrid" data-options="fit:false,border:false">
</table>
