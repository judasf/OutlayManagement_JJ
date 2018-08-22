<%@ Page Language="C#" %>

<%--转账支出方式操作对话框中的panel内容--%>
<style type="text/css">
    p.header { text-align: center; font-weight: 700; font-size: 14px; line-height: 25px; margin: 0px; }
</style>
<script type="text/javascript">
    $(function () {
        //初始化转账信息
        $("#payeename").combogrid({
            url: 'service/PaymentBaseInfo.ashx/GetPayeeInfo',
            panelWidth: 422,
            panelHeight: 183,
            idField: 'payeename', //form提交时的值
            textField: 'payeename',
            editable: true,
            pagination: true,
            required: true,
            rownumbers: true,
            mode: 'remote',
            delay: 500,
            sortName: 'payeeid',
            sortOrder: 'asc',
            pageSize: 5,
            pageList: [5, 10],
            columns: [[{
                field: 'payeename',
                title: '收款单位',
                width: 100,
                halign: 'center',
                align: 'center',
                sortable: true
            }, {
                field: 'accountnumber',
                title: '银行账号',
                width: 140,
                halign: 'center',
                align: 'center',
                sortable: true
            }, {
                field: 'bankname',
                title: '开户行',
                width: 150,
                halign: 'center',
                align: 'left'
            }]],
            onSelect: function (index, row) {
                if (row) {
                    $('#accountnumber').val(row.accountnumber);
                    $('#bankname').val(row.bankname);
                }
            }
        });
        var g = $('#payeename').combogrid('grid');
        g.datagrid('getPager').pagination({ layout: ['first', 'prev', 'links', 'next', 'last'], displayMsg: '' });
    });
    
</script>
<p class="header">
    <span>转账支出事项</span></p>
<table class="table table-bordered table-condensed" style="margin-bottom: 0;">
    <tr>
        <td style="text-align: right; width: 80px">
            收款单位：
        </td>
        <td>
            <input id="payeename" name="payeename" style="width: 250px;" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 80px">
            银行账号：
        </td>
        <td>
            <input id="accountnumber" style="width: 250px;" name="accountnumber" class="easyui-validatebox"
                data-options="required:true,	validType:['number','length[1,30]']" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 80px">
            开户行：
        </td>
        <td>
            <input name="bankname" id="bankname" class="easyui-validatebox" required style="width: 250px;" />
        </td>
    </tr>
</table>
