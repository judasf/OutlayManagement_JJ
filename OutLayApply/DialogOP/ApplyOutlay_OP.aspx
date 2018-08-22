<%@ Page Language="C#" %>

<% 
    /** 
     *费用申请
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<!-- 项目管理 -->
<%  //roleid  
    string deptname;
    if (!Request.IsAuthenticated)
    {%>
<script type="text/javascript">
    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
        parent.location.replace('index.aspx');
    });
</script>
<%}
    else
    {
        UserDetail ud = new UserDetail();
        deptname = ud.LoginUser.UserDept;
%>
<script type="text/javascript">
    /// <summary>单位名称</summary>
    var deptname = '<%=deptname%>';
</script>
<%} %>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/SpecialOutlayAllocate.ashx/SaveSpecialOutlayApplyDetail';
            } else {
                url = 'service/SpecialOutlayAllocate.ashx/UpdateSpecialOutlayApplyDetail';
            }
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $grid.datagrid('load');
                    $dialog.dialog('close');
                } else {
                    parent.$.messager.alert('提示', result.msg, 'error');
                }
            }, 'json');
        }
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
                        'deptname': result.rows[0].deptname,
                        'linkman': result.rows[0].linkman,
                        'linkmantel': result.rows[0].linkmantel,
                        'applycontent': result.rows[0].applycontent
                    });
                    $('#applyOutlay').numberbox('setValue', result.rows[0].applyoutlay);
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
        else {
            $('#deptname').val(deptname);
        }
    });

</script>
<style>
    #applyform table tr td { vertical-align: middle; }
    #applyform table tr td input, #applyform table tr td select { padding: 0 5px; line-height: 25px; height: 25px; }
</style>
<form method="post" id="applyform">
    <table class="table table-bordered  table-hover row-fluid">
        <tr>
        <th colspan="2" style="text-align: center; font-size: 14px;">
            经费申请报告
        </th>
    </tr>
        <tr>
            <td style="text-align: right; width:100px;">申报部门：
            </td>
            <td>
                <input type="hidden" id="id" name="id" value="<%=id %>" />
                <input type="text" id="deptname" name="deptname" readonly class="easyui-validatebox"
                    required />
            </td>
        </tr>
        <tr>
            <td style="text-align: right;">联系人：</td>
            <td>
                <input type="text" name="linkman" id="linkman" class="easyui-validatebox" data-options="required:true" /></td>
        </tr>
        <tr>
            <td style="text-align: right;">联系电话：</td>
            <td>
                <input type="text" name="linkmantel" id="linkmantel" class="easyui-validatebox" data-options="required:true" /></td>
        </tr>
        <tr>
            <td style="text-align: right;">申请内容：</td>
            <td>
                <textarea name="applycontent" id="applycontent" rows="4" class="easyui-validatebox span11" style="border-color: #ccc; background-color: #fff;" data-options="required:true"></textarea>
            </td>
        </tr>
        <tr>
            <td style="text-align: right;">申请额度：</td>
            <td>
                <input type="text" name="applyOutlay" id="applyOutlay" class="easyui-numberbox" data-options="min:0,precision:2,required:true" /></td>
        </tr>
    </table>
</form>
