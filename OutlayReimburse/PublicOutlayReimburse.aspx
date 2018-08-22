<%@ Page Language="C#" AutoEventWireup="true" CodeFile="PublicOutlayReimburse.aspx.cs"
    Inherits="OutlayReimburse_PublicOutlayReimburse" %>

<!DOCTYPE html>
<html>
<head>
    <title>公用经费支出管理</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <style type="text/css">
        #allocateForm table td { padding: 8px; }
        #allocateForm table td a { margin: 0 5px; }
    </style>
    <!-- 公用经费支出管理——基层用户 -->
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
          string userstatus = ud.LoginUser.UserStatus;
    %>
    <script type="text/javascript">
        var userstatus = '<%=userstatus%>';
    </script>
    <%} %>
    <script type="text/javascript">
        //在对话框href中加入type,1:公用经费；2：专项经费
        //添加公用经费报销登记对话框
        var addReimburse = function (id) {
            var dialog = parent.$.modalDialog({
                title: '添加经费支出登记',
                width: 400,
                height: 500,
                iconCls: 'ext-icon-note_add',
                href: 'OutlayReimburse/dialogop/ReimburseOutlay_OP.aspx?type=1&id=' + id, //将对话框内容添加到父页面index
                buttons: [{
                    text: '添加',
                    handler: function () {
                        parent.onFormSubmit(dialog, publicGrid, pbTabs);
                    }
                }, {
                    text: '取消',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }]
            });
        };
        //显示公用经费支出明细
        var showPublicOutlaySpending = function (deptid) {
            var dialog = parent.$.modalDialog({
                title: '公用经费支出明细',
                width: 730,
                height: 440,
                iconCls: 'ext-icon-page',
                href: 'OutlayReimburse/dialogop/PublicOutlaySpending_OP.aspx?deptid=' + deptid,
                buttons: [{
                    text: '关闭',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }]
            });
        };
        //公用经费报销的支出方式tabs
        var pbTabs;
        //公用经费表
        var publicGrid;
        $(function () {
            //初始化tabs
            pbTabs = $('#publicTabs').tabs({
                fit: true,
                border: false,
                tools: [{
                    text: '刷新',
                    iconCls: 'ext-icon-arrow_refresh',
                    handler: function () {
                        var href = pbTabs.tabs('getSelected').panel('options').href;
                        if (href) {/*说明tab是以href方式引入的目标页面*/
                            var index = pbTabs.tabs('getTabIndex', pbTabs.tabs('getSelected'));
                            pbTabs.tabs('getTab', index).panel('refresh');
                        }
                    }
                }]
            });
            //公用经费数据表
            publicGrid = $('#publicGrid').datagrid({
                title: '公用经费明细',
                url: '../service/PublicOutlayAllocate.ashx/GetPublicOutlay',
                columns: [
              [{
                  width: '150',
                  title: '可用额度',
                  field: 'unusedoutlay',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '200',
                  title: '下达额度时间',
                  field: 'lastoutlaytime',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value) {
                      return value.substr(0, value.indexOf(' ')).replace(/\//g, '-');
                  }
              }, {
                  width: '110',
                  title: '单位名称',
                  field: 'deptname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '经费类别',
                  field: 'cname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '支出明细',
                  field: 'spending',
                  halign: 'center',
                  align: 'center',
                  formatter: function (val, row) {
                      var str = $.formatString('<a href="javascript:void(0)" onclick="showPublicOutlaySpending(\'{0}\');">支出明细</a>&nbsp;', row.deptid);
                      return str;
                  }
              }]
                ],
                toolbar: '#pgTip',
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
                },
                onDblClickRow: function (index, row) {
                    if (userstatus == 0) {
                        //当可用额度为0时，提示用户无可用额度
                        if (parseFloat(row.unusedoutlay) <= 0)
                            parent.$.messager.alert('提示', '该项经费无可用额度，不能添加支出登记！', 'error');
                        else
                            addReimburse(row.id);
                    }
                    else
                        parent.$.messager.alert('提示', '该账号已被锁定,不能支出费用！', 'error');
                }
            });
        });
    </script>
</head>
<body class="easyui-layout">
    <div id="pgTip" style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px; line-height: 24px; padding-left: 30px;">
        双击经费明细添加经费支出登记
    </div>
    <div data-options="region:'north',fit:false,collapsible: true,border:false" style="overflow: hidden; height: 108px;">
        <!--公用金额明细-->
        <table id="publicGrid" data-options="fit:true,border:false">
        </table>
    </div>
    <div data-options="region:'center',fit:false,border:false">

        <div id="publicTabs">
            <div title="现金支出明细" href="PublicOutlayReimburse_CashPay.aspx">
            </div>
            <div title="转账支出明细" href="PublicOutlayReimburse_AccountPay.aspx">
                转账支出明细
            </div>
            <div title="公务卡支出明细" href="PublicOutlayReimburse_CardPay.aspx">
                公务卡支出明细
            </div>
        </div>
    </div>
</body>
</html>
