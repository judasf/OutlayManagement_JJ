<%@ Page Language="C#" %>

<% 
    /** 
     *SpecialOutlayApplyDetail表操作对话框，追加经费确认-稽核
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
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
    };
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
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'applyOutlay': result.rows[0].applyoutlay
                    });
                    $('#deptName').html(result.rows[0].deptname);
                    $('#applyTime').html(result.rows[0].applytime.replace(/\//g, '-'));
                    $('#title').html(result.rows[0].applytitle);
                    $('#content').html(result.rows[0].applycontent);
                    $('#applyUser').html(result.rows[0].applyuser);
                    $('#applyOutlay').html(result.rows[0].applyoutlay);
                    $('#approver').html(result.rows[0].approver);
                    $('#approvetime').html(result.rows[0].approvetime.replace(/\//g, '-'));
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
        <td style="text-align: right; width: 80px">
            申请单位：
        </td>
        <td>
            <span id="deptName"></span>
        </td>
        <td style="text-align: right; width: 80px">
            申请时间：
        </td>
        <td>
            <span id="applyTime"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 80px">
            标题：
        </td>
        <td colspan="3">
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <span id="title"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            内容：
        </td>
        <td colspan="3">
            <div id="content">
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
        <td style="text-align: right">
            可用额度：
        </td>
        <td>
            <span id="applyOutlay"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            审批人：
        </td>
        <td>
            <span id="approver"></span>
        </td>
        <td style="text-align: right">
            审批时间：
        </td>
        <td>
            <span id="approvetime"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经费类别：
        </td>
        <td colspan="3">
            <input name="outlayCategory" id="outlayCategory" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经费用途：
        </td>
        <td colspan="3">
            <textarea name="usefor" style="width: 450px;" id="usefor" rows="2" class="easyui-validatebox"
                data-options="required:true"></textarea>
        </td>
    </tr>
</table>
</form>
