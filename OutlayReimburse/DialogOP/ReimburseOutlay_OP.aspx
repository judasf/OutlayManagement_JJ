<%@ Page Language="C#" %>

<% 
    /** 
     *报销经费支出申请登记
     * 
     */
    //用户经费表id,PublicOutlay或者SpecialOutlay，根据来源的页面(PublicOutlayReimburse.aspx或者SpecialOutlayReimburse.aspx)不同取到的数据也不同
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
    //用来显示基层用户是1：公用经费报销还是2：专项经费报销
    string type = string.IsNullOrEmpty(Request.QueryString["type"]) ? "" : Request.QueryString["type"].ToString();
%>
<script type="text/javascript">
    //设置标识来识别请求来源是公用经费明细还是专项经费明细
    var isPublic = ($('#type').val() == "1");
    var onFormSubmit = function ($dialog, $dg, $tabs) {
        /// <summary>
        ///添加报销经费支出登记
        /// </summary>
        /// <param name="$dialog" type="dialog">
        ///   当前激活的操作对话框
        /// </param>
        /// <param name="$dg" type="datagrid">
        ///    公用/专项经费明细表
        /// </param>
        /// <param name="$tabs" type="tabs">
        ///    加载因为支出方式不同而显示不同类型支出登记的tabs,公用经费报销页面3个tab,专项经费报销页面4个tab,第一个为专项经费明细
        /// </param>
        if ($('form').form('validate')) {
            if (parseFloat($('input[name="reimburseOutlay"]').val()) > parseFloat($('#unusedOutlay').html())) {
                parent.$.messager.alert('错误', '报销金额大于可用额度，请检查！', 'error');
                return false;
            }
            //提交表单的url，要刷新的tab的index
            var url, index;
            //获取支出方式的值,来设置保存表单的url和要刷新的tab的index
            var paymentType = $('#payment').combobox('getValue');
            if (paymentType == 0) {//现金支出
                url = 'service/ReimburseOutlay.ashx/SaveCashReimburse';
                index = isPublic ? 0 : 1;
            } else if (paymentType < 3) {//转账支出：同城和异地
                url = 'service/ReimburseOutlay.ashx/SaveAccountReimburse';
                index = isPublic ? 1 : 2;
                //由于网络原因没有设置成功payeename的值，重新设置一下
                $('#payeename').combogrid('setValue', $('#payeename').combogrid('getText')) 
            } else {//公务卡支出
                url = 'service/ReimburseOutlay.ashx/SaveCardReimburse';
                index = isPublic ? 2 : 3;
                //由于网络原因没有设置成功cardholder的值，重新设置一下
                $('#cardholder').combogrid('setValue', $('#cardholder').combogrid('getText')) 
            }
            //确认提交表单，到不同的函数进行处理
            parent.$.messager.confirm('确认', '确认保存支出申请？', function (r) {
                if (r) {
                    parent.$.messager.progress({
                        title: '提示',
                        text: '数据处理中，请稍后....'
                    });
                    $.post(url, $.serializeObject($('form')), function (result) {
                        parent.$.messager.progress('close');
                        if (result.success) {
                            //更新资金明细表
                            $dg.datagrid('load');
                            //刷新tab的内容，来更新支出明细
                            var tab = $tabs.tabs('getTab', index);
                            if (tab)
                                tab.panel('refresh');
                            //关闭对话框
                            $dialog.dialog('close');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        }
    };
    //初始化不同支出方式对应的panel
    var initPanel = function (options) {
        var opts = $.extend({
            border: false
        }, options);
        $('#reim').panel(opts);
    }
    $(function () {
        //初始化支出方式
        $('#payment').combobox({
            required: true,
            editable: false,
            panelHeight: 'auto',
            panelWidth: '100',
            valueField: 'value',
            textField: 'label',
            data: [
             { label: '现金支出', value: '0' },
             { label: '同城转账', value: '1' },
             { label: '异地转账', value: '2' },
             { label: '公务卡', value: '3'}],
            onSelect: function (record) {
                var url = 'index.aspx';
                if (record.value == 0) {
                    url = 'OutlayReimburse/DialogOP/cashreim_op.aspx';
                    $('#reimburseOutlay').numberbox('disable');
                }
                else {
                    $('#reimburseOutlay').numberbox('enable');
                    if (record.value < 3)
                        url = 'OutlayReimburse/DialogOP/AccountReim_op.aspx';
                    else
                        url = 'OutlayReimburse/DialogOP/CardReim_op.aspx';

                }
                //加载不同的支出方式
                initPanel({ href: url });
                //清空报销金额
                $('#reimburseOutlay').numberbox('setValue', '');
            }
        });
        //初始化支出科目
        $("#expenseSubject").combogrid({
            url: 'service/ExpenseSubject.ashx/GetExpenseSubjectInfo',
            panelWidth: 210,
            panelHeight: 183,
            idField: 'subjectname', //form提交时的值
            textField: 'subjectname',
            editable: true,
            pagination: true,
            required: false,
            rownumbers: true,
            mode: 'remote',
            delay: 500,
            sortName: 'id',
            sortOrder: 'asc',
            pageSize: 5,
            pageList: [5, 10],
            columns: [[{
                field: 'subjectnum',
                title: '科目编号',
                width: 60,
                halign: 'center',
                align: 'center',
                sortable: true
            }, {
                field: 'subjectname',
                title: '支出科目名称',
                width: 120,
                halign: 'center',
                align: 'center',
                sortable: true
            }]]
        });
        var g = $('#expenseSubject').combogrid('grid');
        g.datagrid('getPager').pagination({ layout: ['first', 'prev',  'next', 'last'], displayMsg: '' });
        //加载额度基本信息(公用或者专项)
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            //根据type值设置经费类别url
            var url;
            if (isPublic)//公用
                url = 'service/PublicOutlayAllocate.ashx/GetPublicOutlayByID';
            else//专项
                url = 'service/SpecialOutlayAllocate.ashx/GetSpecialOutlayByID';
            $.post(url, {
                ID: $('#id').val()
            }, function (result) {
                parent.$.messager.progress('close');
                if (!result.success && result.total == -1) {
                    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                        parent.location.replace('index.aspx');
                    });
                }
                if (result.rows && result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'reimburseUser': result.rows[0].username,
                        'outlaycategory': result.rows[0].cname,
                        'outlayid': result.rows[0].outlayid || ''
                    });
                    $('#deptName').html(result.rows[0].deptname);
                    $('#outlayCategory').html(result.rows[0].cname);
                    $('#unusedOutlay').html(result.rows[0].unusedoutlay);
                    $('#userName').html(result.rows[0].username);
                }
            }, 'json');
        }
    });
   
</script>
<form method="post">
<table class="table table-bordered table-condensed" style="margin-bottom: 0;">
    <tr>
        <td style="text-align: right; width: 80px">
            单位名称：
        </td>
        <td colspan="3">
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <input type="hidden" id="type" name="type" value="<%=type %>" />
            <input type="hidden" id="outlayid" name="outlayid" value="" />
            <span id="deptName"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经费类别：
        </td>
        <td>
            <input type="hidden" name="outlaycategory" />
            <span id="outlayCategory"></span>
        </td>
        <td style="text-align: right">
            支出方式：
        </td>
        <td>
            <input name="payment" id="payment" style="width: 100px;" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经办人：
        </td>
        <td>
            <span id="userName"></span>
        </td>
        <td style="text-align: right">
            报销人：
        </td>
        <td>
            <input class="easyui-validatebox" name="reimburseUser" style="width: 100px;" required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            支出科目：
        </td>
        <td colspan="3">
            <input name="expenseSubject" id="expenseSubject" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            支出摘要：
        </td>
        <td colspan="3">
            <textarea rows="2" cols="16" name="memo" style="width: 250px;" class="easyui-validatebox"
                data-options="required:true"></textarea>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            可用额度：
        </td>
        <td>
            <span id="unusedOutlay"></span>
        </td>
        <td style="text-align: right">
            报销额度：
        </td>
        <td>
            <input style="width: 100px;" class="easyui-numberbox" data-options="required:true,precision:2,disabled:true"
                id="reimburseOutlay" name="reimburseOutlay" />
        </td>
    </tr>
</table>
<div id="reim">
</div>
</form>
