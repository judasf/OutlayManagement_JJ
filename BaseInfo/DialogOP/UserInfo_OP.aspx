<%@ Page Language="C#" %>

<% 
    /** 
     * UserInfo表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["UID"]) ? "" : Request.QueryString["UID"].ToString();
%>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#UID').val().length == 0) {
                url = 'service/UserInfo.ashx/SaveUserInfo';
            } else {
                url = 'service/UserInfo.ashx/UpdateUserInfo';
            }
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $grid.datagrid('reload');
                    $dialog.dialog('close');
                } else {
                    parent.$.messager.alert('提示', result.msg, 'error');
                }
            }, 'json');
        }
    };
    $(function () {
        $("#roleId").combobox({ onSelect: function (record) {
            //角色为基层用户、部门负责人、部门主管领导时
            if (record.id == 1 || record.id == 8 || record.id == 9) {
                $('#deptTr').show();
                $('#deptId').combobox('clear');
            } else {
                $('#deptId').combobox('setValue','0');
                $('#deptTr').hide();
            }
        }
        });
        if ($('#UID').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/UserInfo.ashx/GetUserInfoByID', {
                UID: $('#UID').val()
            }, function (result) {
                if (result.rows[0].uid != undefined) {
                    //角色为基层用户、部门负责人、部门主管领导时，显示单位信息

                    $('form').form('load', {
                        'UID': result.rows[0].uid,
                        'userNum': result.rows[0].usernum,
                        'userName': result.rows[0].username,
                        'roleId': result.rows[0].roleid,
                        'deptId': result.rows[0].deptid
                    });
                    if (result.rows[0].roleid == 1 || result.rows[0].roleid == 8 || result.rows[0].roleid == 9) {
                        $('#deptTr').show();
                    }

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
            用户编号：
        </td>
        <td style="width: 200px">
            <input type="hidden" id="UID" name="UID" value="<%=id %>" />
            <input id="userNum" type="text" name="userNum" class="easyui-validatebox " <%=!(id=="")?"readonly":"" %> required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            用户名：
        </td>
        <td>
            <input id="userName" type="text" name="userName" class="easyui-validatebox " required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            角色：
        </td>
        <td>
            <input id="roleId" style="height: 29px;" type="text" name="roleId" class="easyui-combobox" data-options="required:true,valueField:'id',textField:'text',editable:false,panelHeight:'auto',url:'service/RoleInfo.ashx/GetRoleInfoCombobox'" />
        </td>
    </tr>
    <tr id="deptTr" style="display: none">
        <td style="text-align: right">
            单位名称：
        </td>
        <td>
            <input id="deptId" style="height: 29px;" type="text" name="deptId" class="easyui-combobox" data-options=" required: true,
                    valueField: 'id',
                    textField: 'text',
                    editable: false,
                    panelHeight: 200,
                    mode: 'local',
                    url: 'service/Department.ashx/GetDepartmentCombobox'" />
        </td>
    </tr>
</table>
</form>
