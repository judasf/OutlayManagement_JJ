<%@ Page Language="C#" %>

<%--用户修改密码--%>
<%  
    int uid = 0;
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
        uid = ud.LoginUser.UID;
%>
<script type="text/javascript">
       var uid=<%=uid%>
</script>
<%} %>
<script type="text/javascript">

    var onFormSubmit = function ($dialog) {
        if ($('form').form('validate')) {
            var url = 'service/UserInfo.ashx/EditPasswd';
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $dialog.dialog('close');
                    parent.$.messager.alert('提示', result.msg, 'info');
                } else {
                    parent.$.messager.alert('提示', result.msg, 'error');
                }
            }, 'json');
        }
    };
</script>
<form method="post">
<table class="table table-hover table-bordered ">
    <tr>
        <th style="text-align: right">
            原密码：
        </th>
        <td>
            <input type="hidden" name="uid" value="<%=uid %>">
            <input name="oldPwd" type="password" placeholder="请输入原密码" class="easyui-validatebox"
                data-options="required:true" />
        </td>
    </tr>
    <tr>
        <th style="text-align: right">
            新密码：
        </th>
        <td>
            <input name="pwd" id="pwd" type="password" placeholder="请输入新密码" class="easyui-validatebox"
                data-options="required:true" />
        </td>
    </tr>
    <tr>
        <th style="text-align: right">
            重复密码：
        </th>
        <td>
            <input name="rePwd" type="password" placeholder="请再次输入新密码" class="easyui-validatebox"
                data-options="required:true,validType:'equalTo[\'#pwd\']'" />
        </td>
    </tr>
</table>
</form>
