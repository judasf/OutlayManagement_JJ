<%@ Page Language="C#" %>

<% 
    /** 
     *SpecialOutlayApplyDetail表操作对话框，追加经费审批。8:部门负责人，9：部门主管领导，4：行财科长，10：行财主管领导
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    var onFormSubmit = function ($dialog, $grid) {
        var url = 'service/SpecialOutlayAllocate.ashx/ApproverApplyOutlay';
        if ($('form').form('validate')) {
            if ($('#audit').val() == '不同意' && $('#comment').val().trim().length == 0) {
                parent.$.messager.alert('提示', '请填写具体意见！', 'info', function () { $('#comment').focus() });
                return;
            }
            parent.$.messager.confirm('询问', '确认提交审批意见？', function (r) {
                if (r) {
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $grid.datagrid('reload');
                            $dialog.dialog('close');
                        } else
                            parent.$.messager.alert('提示', result.msg, 'error');
                    }, 'json');
                }
            });
        }
    };
    /*
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
    */
    $(function () {
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
                    $('#applyOutlay').numberbox('setValue', result.rows[0].applyoutlay)
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
                <input type="text" name="applyOutlay" id="applyOutlay" class="easyui-numberbox" data-options="min:0,precision:2,required:true" />
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
            <td style="text-align: right">行财部门意见：
            </td>
            <td id="fm"></td>
            <td style="text-align: right">行财主管领导意见：
            </td>
            <td id="fl"></td>
        </tr>
     <tr>
            <td colspan="4">审批：<select id="audit" name="audit" style="width: 80px;">
                <option>同意</option>
                <option>不同意</option>
            </select><span style="margin-left: 20px;">意见：</span><input type="text" name="comment" id="comment" style="width: 350px; height: 25px; line-height: 25px;" />

            </td>
        </tr>
</table>
</form>
