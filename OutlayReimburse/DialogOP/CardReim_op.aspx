<%@ Page Language="C#" %>

<%--公务卡支出方式操作对话框中的panel内容--%>
<style type="text/css">
    p.header { text-align: center; font-weight: 700; font-size: 14px; line-height: 25px; margin: 0px; }
</style>
<script type="text/javascript">
    $(function () {
        //初始化公务卡信息
        $("#cardholder").combogrid({
            url: 'service/PaymentBaseInfo.ashx/GetCardInfo',
            panelWidth: 290,
            panelHeight: 183,
            idField: 'cardholder', //form提交时的值
            textField: 'cardholder',
            editable: true,
            pagination: true,
            required: true,
            rownumbers: true,
            mode: 'remote',
            delay: 500,
            sortName: 'cardid',
            sortOrder: 'asc',
            pageSize: 5,
            pageList: [5, 10],
            columns: [[{
                field: 'cardholder',
                title: '持卡人',
                width: 100,
                halign: 'center',
                align: 'center',
                sortable: true
            }, {
                field: 'cardnumber',
                title: '卡号',
                width: 160,
                halign: 'center',
                align: 'center',
                sortable: true
            }]],
            onSelect: function (index, row) {
                if (row) {
                    $('#cardnumber').val(row.cardnumber);
                }
            }
        });
        var g = $('#cardholder').combogrid('grid');
        g.datagrid('getPager').pagination({ layout: ['first', 'prev', 'links', 'next', 'last'], displayMsg: '' });
    });
    
</script>
<p class="header">
    <span>公务卡支出事项</span></p>
<table class="table table-bordered table-condensed" style="margin-bottom: 0;">
    <tr>
        <td style="text-align: right; width: 80px">
            持卡人：
        </td>
        <td>
            <input id="cardholder" name="cardholder" style="width: 250px;" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 80px">
            卡号：
        </td>
        <td>
            <input id="cardnumber" style="width: 250px;" name="cardnumber" class="easyui-validatebox"
                data-options="required:true,	validType:['number','length[1,30]']" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 80px">
            消费时间：
        </td>
        <td>
            <input name="spendingtime" id="spendingtime" class="easyui-validatebox Wdate" required
                style="width: 250px;" onfocus="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss',maxDate:'%y-%M-%d',readOnly:true})"
                />
        </td>
    </tr>
</table>
