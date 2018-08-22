<%@ Page Language="C#" AutoEventWireup="true" CodeFile="AuditCardReimburse.aspx.cs"
    Inherits="OutlayReimburse_AuditCardReimburse" %>

<!DOCTYPE html>
<html>
<head>
    <title>公务卡支出报销管理</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--公务卡支出报销管理-稽核操作--%>
    <%if(!Request.IsAuthenticated)
      {%>
    <script type="text/javascript">
        parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
            parent.location.replace('index.aspx');
        });
    </script>
    <%}
      else
      {
          UserDetail ud = new UserDetail();
          int roleid = ud.LoginUser.RoleId;
    %>
    <script type="text/javascript">
        var roleid = '<%=roleid%>';
    </script>
    <%} %>
    <script type="text/javascript">
        //公务卡支出处理对话框
        var showCardDetail = function (id, status) {
            var btns = [{
                text: '关闭',
                handler: function () {
                    dialog.dialog('close');
                }
            }];
            //稽核权限操作
            if (roleid == 2) {
                //待审核的可提交和退回，被出纳退回的只能退回
                if (status == 1)
                    btns.unshift({
                        text: '审核',
                        handler: function () {
                            parent.onFormSubmit(dialog, cardGrid);
                        }
                    }, {
                        text: '退回',
                        handler: function () {
                            parent.onFormBack(dialog, cardGrid);
                        }
                    })
                if (status == 2)
                    btns.unshift({
                        text: '退回',
                        handler: function () {
                            parent.onFormBack(dialog, cardGrid);
                        }
                    })
            }
            var dialog = parent.$.modalDialog({
                title: '公务卡支出明细',
                width: 400,
                height: 410,
                iconCls: 'ext-icon-note',
                href: 'OutlayReimburse/dialogop/CardReimDetail_op.aspx?id=' + id,
                buttons: btns
            });
        };
        //查询功能
        var searchGrid = function () {
            cardGrid.datagrid('load', $.serializeObject($('#searchForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#searchForm input').val('');
            cardGrid.datagrid('load', {});
        };
        //导出公务卡报销明细到excel
        var exportCardReimburse = function () {
            jsPostForm('../service/ReimburseOutlay.ashx/ExportAuditCardReimburse', $.serializeObject($('#searchForm')));
        };
        //公务卡支出表
        var cardGrid;
        $(function () {
            //cardGrid 公务卡支出表
            cardGrid = $('#cardGrid').datagrid({
                title: '公务卡支出明细',
                url: '../service/ReimburseOutlay.ashx/GetCardPay',
                striped: true,
                fit: true,
                border: false,
                rownumbers: true,
                pagination: true,
                noheader: true,
                showFooter: true,
                pageSize: 20,
                singleSelect: true,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                frozenColumns: [[
            {
                width: '65',
                title: '办理编号',
                field: 'reimburseno',
                sortable: true,
                halign: 'center',
                align: 'center'
            }, {
                width: '80',
                title: '单位名称',
                field: 'deptname',
                halign: 'center',
                align: 'center'
            }, {
                width: '65',
                title: '申请日期',
                field: 'reimbursedate',
                sortable: true,
                halign: 'center',
                align: 'center'
            }, {
                width: '80',
                title: '支出金额',
                field: 'reimburseoutlay',
                sortable: true,
                halign: 'center',
                align: 'center'
            }
            ]],
                columns: [
              [{
                  width: '80',
                  title: '经费类别',
                  field: 'outlaycategory',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '支出科目',
                  field: 'expensesubject',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '支出摘要',
                  field: 'memo',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '60',
                  title: '持卡人',
                  field: 'cardholder',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '130',
                  title: '卡号',
                  field: 'cardnumber',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '110',
                  title: '消费时间',
                  field: 'spendingtime',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value) {
                      if (value)
                          return value.substr(0, 10).replace(/\//g, '-');
                  }
              }, {
                  width: '50',
                  title: '经办人',
                  field: 'username',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '50',
                  title: '报销人',
                  field: 'reimburseuser',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '65',
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
                          case '1':
                              return '待审核'
                              break;
                          case '2': //被出纳退回给稽核，基层用户显示为出纳退回，当被稽核退回时status为-1
                              return '被出纳退回'
                              break;
                          case '3':
                              return '已审核'
                              break;
                      }
                  }
              }, {
                  width: '65',
                  title: '审核日期',
                  field: 'auditdate',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '55',
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
              ]
          ],
                rowStyler: function (index, row) {
                    if (row.status == 1 && roleid == 2)
                        return 'color:#f00;font-weight:700;';
                },
                toolbar: '#cardTip',
                onLoadSuccess: function (data) {
                    parent.$.messager.progress('close');
                    if (data.rows.length == 0) {
                        var body = $(this).data().datagrid.dc.body2;
                        body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                    }
                    //提示框
                    $(this).datagrid('tooltip', ['memo', 'cardnumber', 'spendingtime']);
                },
                onDblClickRow: function (index, row) {
                    showCardDetail(row.id, row.status);
                }
            });
            //设置分页属性
            var pager = $('#cardGrid').datagrid('getPager');
            pager.pagination({
                layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
            });

        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="cardTip">
            <form id="searchForm" style="margin: 0;">
            <table>
                <tr>
                    <td width="50" align="right">
                        单位：
                    </td>
                    <td>
                        <input name="deptId" id="deptId" style="width: 100px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 100,
                    panelHeight: '180',
                    editable:false,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                    </td>
                    <td width="50" align="right">
                        日期：
                    </td>
                    <td>
                        <input style="width: 80px;" name="audit_sdate" id="audit_sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'audit_edate\')}',maxDate:'%y-%M-%d'})"
                            readonly="readonly" />-<input style="width: 80px;" name="audit_edate" id="audit_edate"
                                class="Wdate" onfocus="WdatePicker({minDate:'#F{$dp.$D(\'audit_sdate\')}',maxDate:'%y-%M-%d'})"
                                readonly="readonly" />
                    </td>
                    <td width="50" align="right">
                        类别：
                    </td>
                    <td align="left">
                        <input type="hidden" name="outlayCategory" id="outlayCategory" />
                        <input name="category" id="category" class="easyui-combotree" data-options="valueField: 'id',textField: 'text', editable: false, lines: true,panelHeight: 'auto',url: '../service/category.ashx/GetCategory',onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            },onSelect:function(node){if(node) $('#outlayCategory').val(node.text);}" />
                    </td>
                    <td width="50" align="right">
                        审核：
                    </td>
                    <td>
                        <input style="width: 105px" name="status" id="status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'-1','text':'被稽核退回'},{'value':'1','text':'待审核'},{'value':'2','text':'被出纳退回'},{'value':'3','text':'已审核'}]" />
                    </td>
                    <td width="50" align="right">
                        结报：
                    </td>
                    <td>
                        <input style="width: 60px" name="finishstatus" id="finishstatus" class="easyui-combobox"
                            data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'0','text':'待受理'},{'value':'2','text':'已办结'}],onSelect:function(rec){(rec.value>0)&&$('#status').combobox('setValue','3');}" />
                    </td>
                    <td colspan="6" align="center">
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                            onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">
                                重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportCardReimburse();">导出</a>
                    </td>
                </tr>
            </table>
            </form>
            <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px;
                line-height: 24px; padding-left: 30px;">
                双击公务卡支出明细查看支出详情并审核！
            </div>
        </div>
        <!--公务卡支出明细-->
        <table id="cardGrid">
        </table>
    </div>
</body>
</html>
