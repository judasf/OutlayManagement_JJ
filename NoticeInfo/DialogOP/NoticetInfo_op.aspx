<%@ Page Language="C#" %>

<% 
    /** 
     *意见信箱表(NoticeInfo)操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //提交表单

    var onFormSubmit = function ($dialog, $grid) {
        var url;
        if ($('#id').val().length == 0) {
            url = 'service/NoticeInfo.ashx/SaveNoticeInfo';
        } else {
            url = 'service/NoticeInfo.ashx/UpdateNoticeInfo';
        }
        if ($('form').form('validate')) {
            parent.$.messager.confirm('询问', '您确定要提交该项意见？', function (r) {
                if (r) {
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $grid.datagrid('load');
                            $dialog.dialog('close');
                        } else
                            parent.$.messager.alert('提示', result.msg, 'error');
                    }, 'json');
                }
            });
        }
    };
    $(function () {
        //初始化收信人
        $("#receiverUID").combobox({
            url: 'service/UserInfo.ashx/GetManagerInfoCombobox',
            panelWidth: 100,
            panelHeight: 150,
            valueField: 'id', //form提交时的值
            textField: 'text',
            editable: false,
            required:true,
            onSelect: function (rec) {
                if (rec) {
                    $('#receiverName').val(rec.text);
                }
            }
        });
        //初始化表单数据
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/NoticeInfo.ashx/GetNoticeInfoByID', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'title': result.rows[0].reporttitle,
                        'content': result.rows[0].reportcontent
                    });
                    //存在已上传报表，显示报表信息
                    var val = result.rows[0].reportpath;
                    if (val) {
                        $('#report').val(val);
                        $('#reportName').html(val.substr(val.lastIndexOf('/') + 1));
                        $('#reportTr').show();
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
        <td style="text-align: right;">
            收信人：
        </td>
        <td>
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <input type="hidden" name="receiverName" id="receiverName" />
            <input name="receiverUID" id="receiverUID" style="width:100px" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            标题：
        </td>
        <td>
            <input id="title" name="title" class="easyui-validatebox " style="width: 450px;"
                required />
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            内容：
        </td>
        <td>
            <textarea name="content" id="content" class="easyui-validatebox" required style="width: 450px;
                height: 260px;"></textarea>
        </td>
    </tr>
</table>
</form>
