<%@ Page Language="C#" %>

<% 
    /** 
     *SpecialOutlayApplyDetail表操作对话框，查看申请报告详情
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //通过申请经费确认
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
                    $('#applyOutlay').html(result.rows[0].applyoutlay);
                    $('#auditor').html(result.rows[0].auditor);
                    $('#audittime').html(result.rows[0].audittime.replace(/\//g, '-'));
                    $('#outlayCategory').html(result.rows[0].cname);
                    $('#outlayId').html(result.rows[0].specialoutlayid);
                    $('#usefor').html(result.rows[0].usefor);
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
<style>
    .auditTr td { height: 30px; vertical-align: text-top; }
</style>
<input type="hidden" id="id" value="<%=id %>" />
<div id="printContent">
    <table class="table table-bordered  table-hover">
        <tr>
            <th colspan="4" style="text-align: center; font-size: 14px;">经费申请报告
            </th>
        </tr>
        <tr>
            <td style="text-align: right; width: 80px">申请单位：
            </td>
            <td>
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
            <td style="text-align: right">行财部门意见：
            </td>
            <td id="fm"></td>
            <td style="text-align: right">行财主管领导意见：
            </td>
            <td id="fl"></td>

        </tr>
        <tr>
            <td style="text-align: right">经费类别：
            </td>
            <td>
                <span id="outlayCategory"></span>
            </td>
            <td style="text-align: right">经费编号：
            </td>
            <td>
                <span id="outlayId"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">经费用途：
            </td>
            <td colspan="3">
                <div id="usefor"></div>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">稽核员：
            </td>
            <td>
                <span id="auditor"></span>
            </td>
            <td style="text-align: right">确认生成时间：
            </td>
            <td>
                <span id="audittime"></span>
            </td>
        </tr>
    </table>
</div>
