<%@ Page Language="C#" %>

<% 
    /*
     * 显示处理现金支出的每笔凭证，不同角色可进行不同的操作
     */
    //现金支出表Reimburse_CashPay中的id
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
    //通过认证    
    if(Request.IsAuthenticated)
    {
        UserDetail ud = new UserDetail();
        int roleid = ud.LoginUser.RoleId;
%>
<script type="text/javascript">
    var roleid = '<%=roleid%>';
</script>
<%}%>
<script type="text/javascript">
    /*稽核按钮操作begin
    * 设置现金支出记录状态，审核或退回，在提交时要做判断，
    *1、单笔凭证有未做处理的即在提交时仍为待审核状态的要提示不能提交
    *2、单笔全部审核通过的，提交时直接审核该记录为已审核，设置审核金额
    *3、单笔全部退回的，提交时将该记录设置为被退回，退回给基层用户，审核金额为0
    *4、单笔凭证有审核通过有退回的，提交时将该记录设置为部分已审核，设置审核金额，基层用户可取回被退回金额
    */
    var onFormSubmit = function ($dialog, $cg) {
        var url = 'service/ReimburseOutlay.ashx/AuditCashReimburse';
        if ($('form').form('validate')) {
            parent.$.messager.confirm('确认提交', '确认审核现金支出明细？', function (r) {
                if (r) {
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $cg.datagrid('load');
                            $dialog.dialog('close');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        }

    };
    //审核单笔现金支出凭证
    var auditSingleCashFun = function (id) {
        $.post('service/ReimburseOutlay.ashx/AuditSingleCashReimburse', {
            singlecashid: id,
            id: $('#id').val()
        },
        function (result) {
            if (result.success) {
                //刷新每笔凭证
                cashDetailGrid.datagrid('reload');
                //设置已审核的凭证金额之和
                $('#auditOutlay').numberbox('setValue', result.auditoutlay);
            } else {
                parent.$.messager.alert('提示', result.msg, 'error');
            }
        }, 'json');
    };
    //退回单笔现金支出凭证
    var backSingleCashFun = function (id) {
        $.post('service/ReimburseOutlay.ashx/BackSingleCashReimburse', { id: id },
        function (result) {
            if (result.success) {
                //刷新每笔凭证
                cashDetailGrid.datagrid('reload');
            } else {
                parent.$.messager.alert('提示', result.msg, 'error');
            }
        }, 'json');
    };
    //稽核按钮操作end
    //基层用户按钮操作 begin
    //取回被稽核退回的单笔现金凭证金额，更新可用额度并设置单笔状态为：-2:已恢复
    var getSingleBackOutlayFun = function (id) {
        //console.log(window.frames['fname'].spTabs);可以通过这个变量和type的值在取回凭证金额时刷新对应的tab，当前需要手动刷新呢
        $.post('service/ReimburseOutlay.ashx/GetBackSingleCashReimburse', { id: id },
                        function (result) {
                            if (result.success) {
                                //刷新每笔凭证
                                cashDetailGrid.datagrid('reload');
                                /*取回单笔凭证额度后，根据现金支出经费类别type的不同，来刷新相应的datagrid和tab,
                                公用刷新公用经费表publicGrid；专项刷新spTabs的index为0的tab,即专项经费明细*/
                                if ($('#type').val() == "1")
                                    window.frames['pbframe'].publicGrid.datagrid('load');
                                if ($('#type').val() == "2") {
                                    var tab = window.frames['spframe'].spTabs.tabs('getTab', 0);
                                    if (tab)
                                        tab.panel('refresh');
                                }
                            } else {
                                parent.$.messager.alert('提示', result.msg, 'error');
                            }
                        }, 'json');
    };
    //基层用户按钮操作 end
    var cashDetailGrid;
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
            required: false,
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
            $.post('service/ReimburseOutlay.ashx/GetCashReimburseByID', {
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
                        'auditOutlay': result.rows[0].auditcash,
                        'reimburseNo': result.rows[0].reimburseno,
                        'expenseSubject': result.rows[0].expensesubject,
                        'type': result.rows[0].type,
                        'cashstatus': result.rows[0].status,
                        'auditorcomment': result.rows[0].auditorcomment
                    });
                    $('#deptName').html(result.rows[0].deptname);
                    $('#reimburseNo').html(result.rows[0].reimburseno);
                    $('#reimburseOutlay').html(result.rows[0].reimburseoutlay);
                    $('#memo').html(result.rows[0].memo);
                    //初始化现金支出凭证明细
                    cashDetailGrid = $('#cashReimDetailGrid').datagrid({
                        title: '现金支出凭证详情',
                        url: 'service/ReimburseOutlay.ashx/GetCashReimburseDetailByNo?no=' + result.rows[0].reimburseno,
                        striped: true,
                        rownumbers: true,
                        pagination: true,
                        pageSize: 6,
                        pageList: [6, 12],
                        singleSelect: true,
                        idField: 'id',
                        sortName: 'id',
                        sortOrder: 'desc',
                        columns: [
                [{
                    width: '100',
                    title: '金额',
                    field: 'singleoutlay',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '状态',
                    field: 'status',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row, index) {
                        switch (value) {
                            case '-2':
                                return '已恢复';
                                break;
                            case '-1':
                                return '被退回';
                                break;
                            case '1':
                                return '待审核'
                                break;
                            case '2':
                                return '已审核'
                                break;
                            case '3':
                                return '被出纳退回'
                                break;
                        }
                    }
                }, {
                    width: '60',
                    title: '操作',
                    field: 'action',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        if (roleid == 2) { //稽核审核或者退回凭证 针对待审核和出纳退回
                            if (row.status == 1)//待审核
                                str += $.formatString('<img src="js/easyui/themes/icons/key_go.png"  title="审核" onclick="auditSingleCashFun(\'{0}\');"/>&nbsp;&nbsp;', row.id);
                            if (row.status == 1 || row.status == 3)//待审核或被出纳退回
                                str += $.formatString('<img src="js/easyui/themes/icons/no.png" title="退回" onclick="backSingleCashFun(\'{0}\');"/>&nbsp;&nbsp;', row.id);
                        }
                        if (row.status == -1 && roleid == 1) { //基层用户取回退回额度(但支出记录为已退回：-1或者部分审核:4时，可取回)
                            var cashstatus = $('#cashstatus').val();
                            if (cashstatus == '-1' || cashstatus == '4')
                                str += $.formatString('<img src="js/easyui/themes/icons/arrow_undo.png" title="额度退回" onclick="getSingleBackOutlayFun(\'{0}\');"/>', row.id);
                        }

                        return str;
                    }
                }

                ]
              ]
                    });
                    //设置分页属性
                    var pager = $('#cashReimDetailGrid').datagrid('getPager');
                    pager.pagination({ layout: ['first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'manual'] });
                }
            }, 'json');
        }
    });
</script>
<form method="post" style="margin: 0;">
<table class="table table-bordered table-condensed" style="margin-bottom: 0;">
    <tr>
        <td style="text-align: right; width: 80px">
            单位名称：
        </td>
        <td>
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <!-- 当前现金支出的稽核审核状态，当状态为-1：被稽核退回和4：已审核部分退回时，基层用户可取回单笔凭证 -->
            <input type="hidden" id="cashstatus" name="cashstatus" />
            <!-- 现金支出的经费类别1：公用，2：专项 -->
            <input type="hidden" name="type" id="type" />
            <span id="deptName"></span>
        </td>
        <td style="text-align: right">
            办理编号：
        </td>
        <td>
            <input type="hidden" name="reimburseNo" />
            <span id="reimburseNo"></span>
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
            <span id="memo"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            申请额度：
        </td>
        <td>
            <span id="reimburseOutlay"></span>
        </td>
        <td style="text-align: right">
            已审核额度：
        </td>
        <td>
            <input style="width: 100px;" class="easyui-numberbox" data-options="precision:2"
                id="auditOutlay" name="auditOutlay" readonly="readonly" />
        </td>
    </tr>
     <tr>
        <td style="text-align: right;">
            稽核意见：
        </td>
        <td colspan="3">
           <textarea type="text" name="auditorcomment" style="width: 250px;" id="auditorcomment" rows="2" class="easyui-validatebox" required></textarea>
        </td>
    </tr>
</table>
</form>
<table id="cashReimDetailGrid" data-options="fit:false,border:true">
</table>
