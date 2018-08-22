<%@ Page Language="C#" %>

<% 
    /** 
     *SpecialOutlayApplyDetail表操作对话框，追加经费审批-处长
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
//通过申请经费审批
    var ApproverApplyOutlat = function ($dialog, $grid) {
        parent.$.messager.confirm('询问', '您确定要通过审核该项申请？', function (r) {
            if (r) {
                if ($('form').form('validate')) {
                    var url = 'service/SpecialOutlayAllocate.ashx/ApproverApplyOutlay';
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $grid.datagrid('load');
                            $dialog.dialog('close');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            }
        });
    };
    //退回经费申请到基层用户
    var BackApply = function ($dialog, $grid) {
        parent.$.messager.confirm('询问', '您确定要退回该项申请？', function (r) {
            if (r) {
                $.post('service/SpecialOutlayAllocate.ashx/BackApplyOutlay', 
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
                        'applyOutlay':result.rows[0].applyoutlay
                    });
                    $('#deptName').html(result.rows[0].deptname);
                    $('#applyTime').html(result.rows[0].applytime.replace(/\//g, '-'));
                    $('#title').html(result.rows[0].applytitle);
                    $('#content').html(result.rows[0].applycontent);
                    $('#applyuser').html(result.rows[0].applyuser);
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
        <td colspan="3">
            <span id="applyuser"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            可用额度：
        </td>
        <td colspan="3">
            <input name="applyOutlay" id="applyOutlay" class="easyui-numberbox" data-options="min:0,precision:2,required:true" />
        </td>
    </tr>
</table>
</form>
