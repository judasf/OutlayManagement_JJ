<%@ Page Language="C#" %>

<% 
    /*
     * 显示处理公务卡支出的的审核和退回——稽核
     */
    //公务卡支出表Reimburse_CardPay中的id
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
    //通过认证    
    if (Request.IsAuthenticated)
    {
        UserDetail ud = new UserDetail();
        int roleid = ud.LoginUser.RoleId;
%>
<script type="text/javascript">
    var roleid = '<%=roleid%>';
</script>
<%}%>
<script type="text/javascript">
    //稽核审核通过公务卡支出
    var onFormSubmit = function ($dialog, $ag) {
        var url = 'service/ReimburseOutlay.ashx/AuditCardReimburse';
        if ($('form').form('validate')) {
            parent.$.messager.confirm('确认提交', '确认审核公务卡支出明细？', function (r) {
                if (r) {
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $ag.datagrid('load');
                            $dialog.dialog('close');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        }

    };
    //退回公务卡支出申请给用户，退出时恢复额度
    var onFormBack = function ($dialog, $ag) {
        var url = 'service/ReimburseOutlay.ashx/BackCardReimburse';
        //2018年8月5日增加稽核退回必填意见
        if ($('#auditorcomment').val().trim().length == 0) {
            parent.$.messager.alert('提示', '请填写稽核退回意见！', 'info', function () { $('#auditorcomment').focus() });
            return;
        }
        parent.$.messager.confirm('确认提交', '确认退回该公务卡支出记录？', function (r) {
            if (r) {
                $.post(url, $.serializeObject($('form')), function (result) {
                    if (result.success) {
                        $ag.datagrid('load');
                        $dialog.dialog('close');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //稽核按钮操作end
    $(function () {
        //初始化支出科目
        $("#expenseSubject").combogrid({
            url: 'service/ExpenseSubject.ashx/GetExpenseSubjectInfo',
            panelWidth: 210,
            panelHeight: 433,
            idField: 'subjectname', //form提交时的值
            textField: 'subjectname',
            editable: true,
            pagination: true,
            required: true,
            rownumbers: true,
            mode: 'remote',
            delay: 500,
            sortName: 'id',
            sortOrder: 'asc',
            pageSize: 15,
            pageList: [15, 30],
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
        g.datagrid('getPager').pagination({ layout: ['first', 'prev', 'links', 'next', 'last'], displayMsg: '' });
        //加载数据
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/ReimburseOutlay.ashx/GetCardReimburseByID', {
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
                        'expenseSubject': result.rows[0].expensesubject,
                        'type': result.rows[0].type,
                        'auditorcomment': result.rows[0].auditorcomment
                    });

                    $('#deptName').html(result.rows[0].deptname);
                    $('#reimburseNo').html(result.rows[0].reimburseno);
                    $('#reimburseOutlay').html(result.rows[0].reimburseoutlay);
                    $('#outlayCategory').html(result.rows[0].outlaycategory);
                    $('#memo').html(result.rows[0].memo);
                    $('#cardholder').html(result.rows[0].cardholder);
                    $('#cardNumber').html(result.rows[0].cardnumber);
                    $('#spendingTime').html(result.rows[0].spendingtime);
                }
            }, 'json');
        }
    });
</script>
<form method="post" style="margin: 0;">
    <table class="table table-bordered table-condensed" style="margin-bottom: 0;">
        <tr>
            <td style="text-align: right; width: 80px">单位名称：
            </td>
            <td>
                <input type="hidden" id="id" name="id" value="<%=id %>" />
                <!-- 转账支出的经费类别1：公用，2：专项 -->
                <input type="hidden" name="type" id="type" />
                <span id="deptName"></span>
            </td>
            <td style="text-align: right">办理编号：
            </td>
            <td>
                <span id="reimburseNo"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right; width: 80px">经费类别：
            </td>
            <td colspan="3">
                <span id="outlayCategory"></span>
            </td>

        </tr>
        <tr>
            <td style="text-align: right">支出科目：
            </td>
            <td colspan="3">
                <input name="expenseSubject" id="expenseSubject" />
            </td>
        </tr>
        <tr>
            <td style="text-align: right">支出摘要：
            </td>
            <td colspan="3">
                <span id="memo"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">支出额度：
            </td>
            <td colspan="3">
                <span id="reimburseOutlay"></span>
            </td>
        </tr>
        <tr>
            <td colspan="4" style="text-align: center; font-weight: 700; font-size: 14px; line-height: 25px;">公务卡支出事项
            </td>
        </tr>
        <tr>
            <td style="text-align: right">持卡人：
            </td>
            <td colspan="3">
                <span id="cardholder"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">卡号：
            </td>
            <td colspan="3">
                <span id="cardNumber"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">消费时间：
            </td>
            <td colspan="3">
                <span id="spendingTime"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right;">稽核意见：
            </td>
            <td colspan="3">
                <textarea type="text" name="auditorcomment" style="width: 250px;" id="auditorcomment" rows="2" class="easyui-validatebox"></textarea>
            </td>
        </tr>
    </table>
</form>
