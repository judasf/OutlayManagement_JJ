<%@ Page Language="C#" %>

<% 
    /** 
     * CardInfo表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/PaymentBaseInfo.ashx/SaveCardInfo';
            } else {
                url = 'service/PaymentBaseInfo.ashx/UpdateCardInfo';
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
            $.post('service/PaymentBaseInfo.ashx/GetCardInfoByID', {
                id: $('#id').val()
            }, function (result) {
                if (result.rows[0].cardid != undefined) {
                    //角色为基层用户时，显示单位信息

                    $('form').form('load', {
                        'id': result.rows[0].cardid,
                        'deptId': result.rows[0].deptid,
                        'cardholder': result.rows[0].cardholder,
                        'cardNumber': result.rows[0].cardnumber
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
            单位名称：
        </td>
        <td>
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <input id="deptId" style="height: 29px;" type="text" name="deptId" class="easyui-combobox"
                data-options=" required: true,
                    valueField: 'id',
                    textField: 'text',
                    editable: false,
                    panelHeight: 200,
                    mode: 'local',
                    url: 'service/Department.ashx/GetDepartmentCombobox'" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            持卡人：
        </td>
        <td>
            <input id="cardholder" type="text" name="cardholder" class="easyui-validatebox "
                required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            卡号：
        </td>
        <td>
            <input id="cardNumber" type="text" name="cardNumber" class="easyui-validatebox "  data-options="required:true,	validType:['number','length[1,30]']" />
        </td>
    </tr>
</table>
</form>
