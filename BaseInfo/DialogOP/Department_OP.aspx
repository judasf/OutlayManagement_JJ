<%@ Page Language="C#" %>

<% 
    /** 
     * Department操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["deptid"]) ? "" : Request.QueryString["deptid"].ToString();
%>
<script type="text/javascript">
    var onDeptFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#deptId').val().length == 0) {
                url = 'service/Department.ashx/SaveDepartment';
            } else {
                url = 'service/Department.ashx/UpdateDepartment';
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
        $('#deptName').focus().validatebox({ required: true });
        if ($('#deptId').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/Department.ashx/GetDepartmentByID', {
                deptid: $('#deptId').val()
            }, function (result) {
                if (result.rows[0].deptid != undefined) {
                    $('form').form('load', {
                        'deptId': result.rows[0].deptid,
                        'deptName': result.rows[0].deptname
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
            <td style="text-align: right">单位名称：
            </td>
            <td style="width: 200px">
                <input type="hidden" id="deptId" name="deptId" value="<%=id %>" />
                <input id="deptName" type="text" name="deptName" class="easyui-validatebox" />
            </td>
        </tr>
    </table>
</form>
