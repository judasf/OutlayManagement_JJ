<%@ Page Language="C#" %>

<% 
    /** 
     * PayeeInfo表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/PaymentBaseInfo.ashx/SavePayeeInfo';
            } else {
                url = 'service/PaymentBaseInfo.ashx/UpdatePayeeInfo';
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
    //初始化表单信息
    $(function () {
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/PaymentBaseInfo.ashx/GetPayeeInfoByID', {
                id: $('#id').val()
            }, function (result) {
                if (result.rows[0].payeeid != undefined) {
                    //角色为基层用户时，显示单位信息

                    $('form').form('load', {
                        'id': result.rows[0].payeeid,
                        'payeeName': result.rows[0].payeename,
                        'accountNumber': result.rows[0].accountnumber,
                        'bankName': result.rows[0].bankname
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
        <td style="text-align: right; width: 80px;">
            收款单位：
        </td>
        <td>
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <input id="payeeName" type="text" name="payeeName" class="easyui-validatebox " required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            银行账号：
        </td>
        <td>
            <input id="accountNumber" type="text" name="accountNumber" class="easyui-validatebox "
                data-options="required:true,	validType:['number','length[1,30]']" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            开户行：
        </td>
        <td>
            <input id="bankName" type="text" name="bankName" class="easyui-validatebox " required />
        </td>
    </tr>
</table>
</form>
