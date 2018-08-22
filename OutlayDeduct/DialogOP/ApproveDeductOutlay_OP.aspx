<%@ Page Language="C#" %>

<% 
    /** 
     *DeductOutlayDetail表操作对话框，对稽核申请的扣减经费进行审批并扣减可用额度——处长
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //审批通过扣减经费申请
    var ApproveDeductOutlay = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            parent.$.messager.confirm('询问', '您确定要通过该项申请？', function (r) {
                if (r) {
                    var url = 'service/DeductOutlay.ashx/ApproveDeductOutlay';
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $grid.datagrid('load');
                            $dialog.dialog('close');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        }
    };
    //退回扣减经费申请到稽核
    var BackDeductOutlay = function ($dialog, $grid) {
        parent.$.messager.confirm('询问', '您确定要退回该项申请？', function (r) {
            if (r) {
                $.post('service/DeductOutlay.ashx/BackDeductOutlay',
                   $.serializeObject($('form'))
                , function (result) {
                    if (result.success) {
                        $grid.datagrid('load');
                        $dialog.dialog('close');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    ////打印申请报告
    //var printDetail = function () {
    //    window.showModalDialog("/print.htm", $('form').html(),
    //"location:No;status:No;help:No;dialogWidth:800px;dialogHeight:600px;scroll:auto;");
    //};
    $(function () {
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/DeductOutlay.ashx/GetDeductOutlayDetailByID', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id
                    });
                    $('#deptName').html(result.rows[0].deptname);
                    $('#deductTime').html(result.rows[0].deducttime.replace(/\//g, '-'));
                    $('#outlayCategory').html(result.rows[0].cname);
                    $('#applyUser').html(result.rows[0].applyuser);
                    $('#deductOutlay').html(result.rows[0].deductoutlay);
                    $('#deductReason').html(result.rows[0].deductreason);
                    if (result.rows[0].outlaycategory == '2') {
                        $('#outlayIdTr').show();
                        $('#specialOutlayID').html(result.rows[0].specialoutlayid);
                    }
                    if (result.rows[0].status == '2') {//已扣减的显示审批人和审批时间
                        $('#approverTr').show();
                        $('#approver').html(result.rows[0].approver);
                        $('#approveTimeTr').show();
                        $('#approveTime').html(result.rows[0].approvetime.replace(/\//g, '-'));
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
        <th colspan="4" style="text-align: center; font-size: 14px;">
            扣减经费申请报告
        </th>
    </tr>
    <tr>
        <td style="text-align: right;width:80px;">
            扣减单位：
        </td>
        <td>
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <span id="deptName"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            申请时间：
        </td>
        <td>
            <span id="deductTime"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            经费类别：
        </td>
        <td>
            <span id="outlayCategory"></span>
        </td>
    </tr>
    <tr id="outlayIdTr" style="display: none">
        <td style="text-align: right">
            额度编号：
        </td>
        <td>
            <span id="specialOutlayID"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            扣减额度：
        </td>
        <td>
            <span id="deductOutlay"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            扣减原因：
        </td>
        <td>
            <div id="deductReason">
            </div>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经办人：
        </td>
        <td>
            <span id="applyUser"></span>
        </td>
    </tr>
     <tr id="approverTr" style="display: none">
        <td style="text-align: right">
           审批人：
        </td>
        <td>
            <span id="approver"></span>
        </td>
    </tr>
     <tr id="approveTimeTr" style="display: none">
        <td style="text-align: right">
            审批时间：
        </td>
        <td>
            <span id="approveTime"></span>
        </td>
    </tr>
</table>
</form>
