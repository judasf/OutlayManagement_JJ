<%@ Page Language="C#" AutoEventWireup="true" CodeFile="AllAuditApplyOutlayTabs.aspx.cs"
    Inherits="OutlayReimburse_AllAuditApplyOutlayTabs" %>

<!DOCTYPE html>
<html>
<head>
    <title>追加经费管理</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
</head>
    <%--追加经费明细tabs——稽核，管理员，浏览用户，行财主管领导--%>
<%  int roleid = 0;
    if (!Request.IsAuthenticated)
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
    //稽核：追加经费明细tabs，包括申请追加(基层用户追加需要确认生成的)和直接追加(稽核直接追加)
    var aoTabs; //变量的作用域
    $(function () {
        spTabs = $('#applyOutlayTabs').tabs({
            fit: true,
            border: false,
            tools: [{
                text: '刷新',
                iconCls: 'ext-icon-arrow_refresh',
                handler: function () {
                    var href = spTabs.tabs('getSelected').panel('options').href;
                    if (href) {/*说明tab是以href方式引入的目标页面*/
                        var index = spTabs.tabs('getTabIndex', spTabs.tabs('getSelected'));
                        spTabs.tabs('getTab', index).panel('refresh');
                    }
                }
            }]
        });
    });
</script>
<body class="easyui-layout">
    <!--追加经费明细包括基层用户申请的和稽核直接追加的 -->
    <div data-options="region:'center',fit:true,border:false">
        <div id="applyOutlayTabs">
            <div title="直接拨付经费管理" style="overflow: hidden;" href="AuditApplyOutlay.aspx">
            </div>
            <%if (roleid == 10)
                {//行财主管领导 %>
            <div title="申请追加经费管理" style="overflow: hidden;" href="ApplyOutlay.aspx">
            </div>
            <%}
    else
    { %>   <div title="申请追加经费管理" style="overflow: hidden;" href="ApplyOutlay.aspx">
            </div>
            <%} %>
        </div>
    </div>
</body>
</html>
