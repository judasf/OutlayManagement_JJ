<%@ Page Language="C#" %>

<% 
    /** 
     * OutlayLevel公用经费标准表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["levelid"]) ? "" : Request.QueryString["levelid"].ToString();
%>
 
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {

        if ($('form').form('validate')) {
            var url;
            if ($('#levelid').val().length == 0) {
                url = 'service/OutlayLevel.ashx/SaveOutlayLevel';
            } else {
                url = 'service/OutlayLevel.ashx/UpdateOutlayLevel';
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
        if ($('#levelid').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/OutlayLevel.ashx/getOutlayLevelByID', {
                levelid: $('#levelid').val()
            }, function (result) {
                if (result.rows[0].levelid != undefined) {
                    $('form').form('load', {
                        'levelid': result.rows[0].levelid,
                        'levelName': result.rows[0].levelname,
                        'levelOutlay': result.rows[0].leveloutlay
                    });
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
    });
</script>
<form method="post">
<table class="table table-bordered  table-hover">
    <tr>
        <td align="right">
            公用经费标准名称：
        </td>
        <td style="width: 200px">
            <input type="hidden" id="levelid" name="levelid" value="<%=id %>" />
            <input id="levelName" type="text" name="levelName" class="easyui-validatebox " required />
        </td>
    </tr>
    <tr>
        <td align="right">
            公用经费标准金额：
        </td>
        <td valign="middle" style="width: 100px">
            <input id="levelOutlay"  type="text" name="levelOutlay" class="easyui-numberbox " required data-options="min:0,groupSeparator:',',precision:2,prefix:'￥'" />
        </td>
    </tr>
</table>
</form>
