<%@ Page Language="C#" AutoEventWireup="true" CodeFile="AuditCashReimburse.aspx.cs"
    Inherits="OutlayReimburse_AuditCashReimburse" %>

<!DOCTYPE html>
<html>
<head>
    <title>现金支出报销管理</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--现金支出报销管理-稽核操作--%>
    <%if (!Request.IsAuthenticated)
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
        //现金支出单笔凭证处理对话框
        var showCashDetail = function (id, status) {
            var btns = [{
                text: '关闭',
                handler: function () {
                    dialog.dialog('close');
                }
            }];
            //稽核权限操作
            if (roleid == 2) {
                //待审核和被出纳退回的可提交
                if (status < 3)
                    btns.unshift({
                        text: '提交',
                        handler: function () {
                            parent.onFormSubmit(dialog, cashGrid);
                        }
                    })
            }
            var dialog = parent.$.modalDialog({
                title: '现金支出单笔凭证明细',
                width: 400,
                height: 450,
                iconCls: 'ext-icon-note',
                href: 'OutlayReimburse/dialogop/CashReimDetail_op.aspx?id=' + id + '&cashstatus=' + status,
                buttons: btns
            });
        };
        //查询功能
        var searchGrid = function () {
            cashGrid.datagrid('load', $.serializeObject($('#searchForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#searchForm input').val('');
            cashGrid.datagrid('load', {});
        };
        //导出现金报销excel
        var exportCashReimburse = function () {
            jsPostForm('../service/ReimburseOutlay.ashx/ExportAuditCashReimburse', $.serializeObject($('#searchForm')));
        };
        //现金支出表
        var cashGrid;
        $(function () {
            //cashGrid 现金支出表
            cashGrid = $('#cashGrid').datagrid({
                title: '现金支出报销明细',
                url: '../service/ReimburseOutlay.ashx/GetCashPay',
                fit: true,
                border: false,
                striped: true,
                rownumbers: true,
                pagination: true,
                showFooter: true,
                noheader: true,
                pageSize: 20,
                singleSelect: true,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                columns: [
              [{
                  width: '70',
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
                  width: '70',
                  title: '申请日期',
                  field: 'reimbursedate',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '70',
                  title: '支出金额',
                  field: 'reimburseoutlay',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '70',
                  title: '审核金额',
                  field: 'auditcashoutlay',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '资金类别',
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
                  width: '90',
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
                          case '2': //被出纳退回给稽核
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
                  width: '70',
                  title: '审核日期',
                  field: 'auditdate',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
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
              ]
                ],
                rowStyler: function (index, row) {
                    if (row.status == 1 && roleid == 2)
                        return 'color:#f00;font-weight:700;';
                },
                toolbar: '#cgTip',
                onLoadSuccess: function (data) {
                    parent.$.messager.progress('close');
                    if (!data.success && data.total == -1) {
                        parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                            parent.location.replace('index.aspx');
                        });
                    }
                    if (data.rows.length == 0) {
                        var body = $(this).data().datagrid.dc.body2;
                        body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                    }
                    //提示框
                    $(this).datagrid('tooltip', ['outlaycategory', 'expensesubject', 'memo']);
                },
                onDblClickRow: function (index, row) {
                    showCashDetail(row.id, row.status);
                }
            });
            //设置分页属性
            var pager = $('#cashGrid').datagrid('getPager');
            pager.pagination({
                layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
            });

        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="cgTip">
            <form id="searchForm" style="margin: 0;">
                <table>
                    <tr>
                        <td width="50" align="right">单位：
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
                        <td width="50" align="right">日期：
                        </td>
                        <td>
                            <input style="width: 80px;" name="audit_sdate" id="audit_sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'audit_edate\')}',maxDate:'%y-%M-%d'})"
                                readonly="readonly" />-<input style="width: 80px;" name="audit_edate" id="audit_edate"
                                    class="Wdate" onfocus="WdatePicker({minDate:'#F{$dp.$D(\'audit_sdate\')}',maxDate:'%y-%M-%d'})"
                                    readonly="readonly" />
                        </td>
                        <td width="50" align="right">类别：
                        </td>
                        <td align="left">
                            <input type="hidden" name="outlayCategory" id="outlayCategory" />
                            <input name="category" id="category" class="easyui-combotree" data-options="valueField: 'id',textField: 'text', editable: false, lines: true,panelHeight: 'auto',url: '../service/category.ashx/GetCategory',onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            },onSelect:function(node){if(node) $('#outlayCategory').val(node.text);}" />
                        </td>
                        <td width="50" align="right">审核：
                        </td>
                        <td>
                            <input style="width: 105px" name="status" id="status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'-1','text':'被稽核退回'},{'value':'1','text':'待审核'},{'value':'2','text':'被出纳退回'},{'value':'3','text':'已审核'},{'value':'4','text':'已审核部分退回'}]" />
                        </td>
                        <td width="50" align="right">结报：
                        </td>
                        <td>
                            <input id="finishstatus" class="easyui-combobox"
                                data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'0','text':'待受理'},{'value':'2','text':'已办结'}],onSelect:function(rec){(rec.value>0)&&$('#searchForm').find('#status').combobox('setValue','3');}"
                                name="finishstatus" style="width: 60px" />
                        </td>
                        <td colspan="6" align="center">
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                                onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                    data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                        onclick="exportCashReimburse();">导出</a>
                        </td>
                    </tr>
                </table>
            </form>
            <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px; line-height: 24px; padding-left: 30px;">
                双击现金支出明细查看每笔支出凭证详情，逐笔进行审核
            </div>
        </div>
        <!--现金支出明细-->
        <table id="cashGrid">
        </table>
    </div>
</body>
</html>
