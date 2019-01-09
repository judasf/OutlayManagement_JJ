<%@ Page Language="C#" %>

<% 
    /** 
     *SpecialOutlayApplyDetail表操作对话框，基层用户追加经费确认并生成-稽核员确认通过8，9，10审批的追加经费申请，并生成
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //通过申请经费确认并生成
    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            parent.$.messager.confirm('询问', '您确认要生成该项经费？', function (r) {
                if (r) {

                    var url = 'service/SpecialOutlayAllocate.ashx/AuditApproveOutlay';
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
    /*
    //通过申请经费确认
    var AuditApproveOutlat = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            parent.$.messager.confirm('询问', '您确定要确认该项申请？', function (r) {
                if (r) {

                    var url = 'service/SpecialOutlayAllocate.ashx/AuditApproveOutlay';
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
    //退回经费申请到处长
    var BackApprover = function ($dialog, $grid) {
        parent.$.messager.confirm('询问', '您确定要退回该项申请？', function (r) {
            if (r) {
                $.post('service/SpecialOutlayAllocate.ashx/BackApprover',
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
    };*/
    $(function () {
        //加载经费类别树
        $('#outlayCategory').combotree({
            valueField: 'id',
            textField: 'text',
            editable: false,
            required: true,
            lines: true,
            panelHeight: 'auto',
            url: 'service/category.ashx/GetCategory',
            onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            }
        });
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/SpecialOutlayAllocate.ashx/SpecialOutlayApplyDetailByID', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('#deptName').html(result.rows[0].deptname);
                    $('#applyTime').html(result.rows[0].applytime.replace(/\//g, '-'));
                    $('#linkman').html(result.rows[0].linkman);
                    $('#linkmantel').html(result.rows[0].linkmantel);
                    $('#content').html(result.rows[0].applycontent);
                    $('#applyUser').html(result.rows[0].applyuser);
                    $('#applyOutlay').html(result.rows[0].applyoutlay);
                    //显示审核信息
                    $('#dm').append(result.rows[0].deptmanaaudit);
                    if (result.rows[0].deptmanacomment.length > 0)
                        $('#dm').append('，' + result.rows[0].deptmanacomment);
                    $('#dm').append("<br/><p style='text-align:right;'>" + result.rows[0].deptmanaaudittime + "</p>")
                    $('#dl').append(result.rows[0].deptleadaudit);
                    if (result.rows[0].deptleadcomment.length > 0)
                        $('#dl').append('，' + result.rows[0].deptmanacomment);
                    $('#dl').append("<br/><p style='text-align:right;'>" + result.rows[0].deptleadaudittime + "</p>")
                    $('#fm').append(result.rows[0].financemanaaudit);
                    if (result.rows[0].financemanacomment.length > 0)
                        $('#fm').append('，' + result.rows[0].financemanacomment);
                    $('#fm').append("<br/><p style='text-align:right;'>" + result.rows[0].financemanaaudittime + "</p>")
                    $('#fl').append(result.rows[0].financeleadaudit);
                    if (result.rows[0].financeleadcomment.length > 0)
                        $('#fl').append('，' + result.rows[0].financeleadcomment);
                    $('#fl').append("<br/><p style='text-align:right;'>" + result.rows[0].financeleadaudittime + "</p>")
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
            经费申请报告
        </th>
    </tr>
   <tr>
            <td style="text-align: right; width: 80px">申请单位：
            </td>
            <td><input type="hidden"  id="id" name="id" value="<%=id %>" />
                <span id="deptName"></span>
            </td>
            <td style="text-align: right; width: 80px">申请时间：
            </td>
            <td>
                <span id="applyTime"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right; width: 80px">联系人：
            </td>
            <td>
                <span id="linkman"></span>
            </td>
            <td style="text-align: right; width: 80px">联系电话：
            </td>
            <td>
                <span id="linkmantel"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">内容：
            </td>
            <td colspan="3">
                <div id="content">
                </div>
            </td>
        </tr>
        <tr>
             <td style="text-align: right">申请额度：
            </td>
            <td>
                 <span id="applyOutlay"></span>
            </td>
            <td style="text-align: right">经办人：
            </td>
            <td>
                <span id="applyUser"></span>
            </td>
           
        </tr>
        <tr class="auditTr">
            <td style="text-align: right">申报部门负责人意见：
            </td>
            <td id="dm"></td>
            <td style="text-align: right">申报部门主管领导意见：
            </td>
            <td id="dl"></td>

        </tr>
        <tr class="auditTr">
            <td style="text-align: right">财务部门意见：
            </td>
            <td id="fm"></td>
            <td style="text-align: right">财务主管领导意见：
            </td>
            <td id="fl"></td>
        </tr>
     <tr>
    <tr>
        <td style="text-align: right">
            经费类别：
        </td>
        <td colspan="3">
            <input type="text" name="outlayCategory" id="outlayCategory" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经费用途：
        </td>
        <td colspan="3">
            <textarea type="text" name="usefor" style="width: 450px;" id="usefor" rows="2" class="easyui-validatebox"
                data-options="required:true"></textarea>
        </td>
    </tr>
</table>
</form>
