<%@ Page Language="C#" %>

<% 
    /** 
     * ExpenseSubject支出科目标准表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {

        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/ExpenseSubject.ashx/SaveExpenseSubject';
            } else {
                url = 'service/ExpenseSubject.ashx/UpdateExpenseSubject';
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
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/ExpenseSubject.ashx/GetExpenseSubjectByID', {
                id: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'subjectNum': result.rows[0].subjectnum,
                        'subjectName': result.rows[0].subjectname
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
        <td style="text-align:right">
            支出科目编号：
        </td>
        <td style="width: 200px">
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <input id="subjectNum" type="text" name="subjectNum" class="easyui-validatebox" required />
        </td>
    </tr>
    <tr>
        <td style="text-align:right">
            支出科目名称：
        </td>
        <td valign="middle" style="width: 100px">
            <input id="subjectName" type="text" name="subjectName" class="easyui-validatebox "
                required />
        </td>
    </tr>
</table>
</form>
