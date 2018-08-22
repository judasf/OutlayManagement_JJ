<%@ Page Language="C#" AutoEventWireup="true" CodeFile="AcceptCardReimburse.aspx.cs"
    Inherits="OutlayReimburse_AcceptCardReimburse" %>

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
    <%--公务卡支出报销管理——出纳操作;管理员取消支出办结,删除被稽核退回的支出申请，删除未送审的支出--%>
    <%  int roleid = 0;
        if(!Request.IsAuthenticated)
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
            roleid = ud.LoginUser.RoleId;
    %>
    <script type="text/javascript">
        var roleid = '<%=roleid%>';
    </script>
    <%} %>
    <script type="text/javascript">
        //受理已审核的公务卡支出
        var acceptCardAudit = function (id) {
            $.post('../service/ReimburseOutlay.ashx/AcceptCardAudit',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            cardGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
        };
        //退回已审核的公务卡支出到稽核
        var backCardAudit = function (id, no) {
            $.post('../service/ReimburseOutlay.ashx/BackCardAudit',
                    { id: id},
                    function (result) {
                        if (result.success) {
                            cardGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
        };
        //办结已受理的公务卡支出
        var finishCardAccept = function (id) {
            $.post('../service/ReimburseOutlay.ashx/FinishCardAccept',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            cardGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
        };
        //管理员操作
        //取消已办结的公务卡支出到出纳待受理
        var cancelFinishCard = function (id) {
            parent.$.messager.confirm('取消办结', '您确认要取消该项支出办结？', function (r) {
                if (r) {
                    $.post('../service/ReimburseOutlay.ashx/CancelFinishCard',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            cardGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
         //删除被稽核退回的转账支出申请
        var removeBackCardReimburseByAudit = function (id) {
            parent.$.messager.confirm('删除', '您确认要删除该项支出申请？', function (r) {
                if (r) {
                    $.post('../service/ReimburseOutlay.ashx/RemoveBackCardReimburseByAudit',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            cardGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //删除待送审的公务卡支出
        var removeCardReimburse = function (id) {
            parent.$.messager.confirm('删除确认', '您确认要删除该项支出？', function (r) {
                if (r) {
                    $.post('../service/ReimburseOutlay.ashx/RemoveCardReimburse',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            cardGrid.datagrid('reload');
                            parent.$.messager.alert('成功', result.msg, 'info');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //管理员操作 end
        //查询功能
        var searchGrid = function () {
            cardGrid.datagrid('load', $.serializeObject($('#searchForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#searchForm input').val('');
            cardGrid.datagrid('load', {});
        };
        //导出转账报销excel
        var exportCardReimburse = function () {
            jsPostForm('../service/ReimburseOutlay.ashx/ExportAcceptCardReimburse', $.serializeObject($('#searchForm')));
        };
        //公务卡支出表
        var cardGrid;
        $(function () {
            //cardGrid 公务卡支出表
           cardGrid = $('#cardGrid').datagrid({
            title: '公务卡支出明细',
            url: '../service/ReimburseOutlay.ashx/GetCardPay',
            striped: true,
            rownumbers: true,
            fit:true,
            border: false,
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
                width: '60',
                title: '支出金额',
                field: 'reimburseoutlay',
                sortable: true,
                halign: 'center',
                align: 'center'
            }
            ]],
            columns: [
              [{
                  width: '70',
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
                  formatter:function (value) {
                    if(value)
                        return value.replace(/\//g,'-');
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
                  hidden:true,
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
                      }
                  }
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
              }, {
                  width: '65',
                  title: '办理日期',
                  field: 'acceptdate',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  title: '操作',
                  field: 'action',
                  width: '60',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row) {
                      var str = '';
                      if(roleid==3){ //出纳
                      if (row.finishstatus == 0) {//待受理显示受理和退回，去掉已受理状态
                          //str += $.formatString('<a href="javascript:void(0)" onclick="acceptCardAudit(\'{0}\');">受理</a>&nbsp;', row.id);
                          str += $.formatString('<a href="javascript:void(0)" onclick="finishCardAccept(\'{0}\');">办结</a>&nbsp;', row.id);
                          str += $.formatString('<a href="javascript:void(0)" onclick="backCardAudit(\'{0}\',\'{1}\');">退回</a>&nbsp;', row.id, row.reimburseno);
                      }
                      //if (row.finishstatus == 1) {//已受理的显示办结
                      //    str += $.formatString('<a href="javascript:void(0)" onclick="finishCardAccept(\'{0}\');">办结</a>&nbsp;', row.id);
                      //}
                      }
                      if(roleid==6){ //管理员,对已办结的取消办结，退回到待受理
                       if (row.finishstatus == 2)
                       str += $.formatString('<a href="javascript:void(0)" onclick="cancelFinishCard(\'{0}\');">取消办结</a>&nbsp;', row.id);
                       if (row.status == -1)//被稽核退回的可以删除
                           str += $.formatString('<a href="javascript:void(0)" onclick="removeBackCardReimburseByAudit(\'{0}\');">删除</a>', row.id);
                       if (row.status == 0)//未送审的可以删除
                           str += $.formatString('<a href="javascript:void(0)" onclick="removeCardReimburse(\'{0}\');">删除</a>', row.id);
                      }
                      return str;
                  }
              }
              ]
          ],
            toolbar: '#cardgTip',
            onLoadSuccess: function (data) {
            parent.$.messager.progress('close');
                if (data.rows.length == 0) {
                    var body = $(this).data().datagrid.dc.body2;
                    body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                }
                //提示框
                $(this).datagrid('tooltip', ['outlaycategory','memo','cardnumber','spendingtime']);
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
         //管理员显示审核状态
            if (roleid == 6)
                $('#cardGrid').datagrid('showColumn', 'status');
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="cardgTip">
            <form id="searchForm" style="margin: 0;">
            <table>
                <tr>
                    <td width="45" align="right">
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
                    <td width="45" align="right">编号：
                        </td>
                        <td>
                            <input style="width: 70px; height: 20px" type="text" class="combo" name="reimburseNo" />
                        </td>
                    <td width="45" align="right">
                        日期：
                    </td>
                    <td>
                        <input style="width: 80px;" name="accept_sdate" id="accept_sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'accept_edate\')}',maxDate:'%y-%M-%d'})"
                            readonly="readonly" />-<input style="width: 80px;" name="accept_edate" id="accept_edate" class="Wdate"
                                onfocus="WdatePicker({minDate:'#F{$dp.$D(\'accept_sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                    </td>
                     <td width="45" align="right">
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
                     <%if(roleid == 6)
                      {%>
                    <td width="45" align="right">
                        审核：
                    </td>
                    <td>
                        <input style="width: 105px" name="status" id="status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'-1','text':'被稽核退回'},{'value':'0','text':'待送审'},{'value':'1','text':'待审核'},{'value':'2','text':'被出纳退回'},{'value':'3','text':'已审核'}],onSelect:function(rec){rec.value<3 && $('#finishstatus').combobox('setValue','0');}" />
                    </td>
                    <%} %>
                    <td width="45" align="right">
                        结报：
                    </td>
                    <td>
                        <input style="width: 60px" name="finishstatus" id="finishstatus" class="easyui-combobox"
                            data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'0','text':'待受理'},{'value':'2','text':'已办结'}]" />
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
        </div>
        <!--公务卡支出明细-->
        <table id="cardGrid">
        </table>
    </div>
</body>
</html>
