<%@ Page Language="C#" %>

<% 
    /** 
     * RoleInfo表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["roleId"]) ? "" : Request.QueryString["roleId"].ToString();
%>
 
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {

        if ($('form').form('validate')) {
            var url;
            if ($('#roleId').val().length == 0) {
                url = 'service/RoleInfo.ashx/SaveRoleInfo';
            } else {
                url = 'service/RoleInfo.ashx/UpdateRoleInfo';
            }
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $grid.datagrid('load');
                    $dialog.dialog('close');
                } else {
                    parent.$.messager.alert('提示', result.msg, 'error');
                }
            }, 'json');
        }
    };
    $(function () {
        if ($('#roleId').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/RoleInfo.ashx/GetRoleInfoByID', {
                roleid: $('#roleId').val()
            }, function (result) {
                if (result.rows[0].roleid != undefined) {
                    $('form').form('load', {
                        'roleId': result.rows[0].roleid,
                        'roleName': result.rows[0].rolename,
                        'roleDesc': result.rows[0].roledesc
                    });
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
    });
</script>
<form method="post">
<table class="table table-bordered  table-hover">
    <tr>
        <td style="text-align: right">
            角色名称：
        </td>
        <td style="width: 200px">
            <input type="hidden" id="roleId" name="roleId" value="<%=id %>" />
            <input id="roleName" type="text" name="roleName" class="easyui-validatebox " required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            角色描述：
        </td>
        <td>
            <textarea rows="2" id="roleDesc" name="roleDesc"></textarea>
        </td>
    </tr>
</table>
</form>
