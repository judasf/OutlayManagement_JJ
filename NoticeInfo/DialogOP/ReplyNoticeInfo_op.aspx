<%@ Page Language="C#" %>

<% 
    /** 
     *非基层单位回复意见
     */
    //NoticeInfo中的id
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //提交表单
    var onFormSubmit = function ($dialog, $grid) {
        var url = 'service/NoticeInfo.ashx/ReplyNoticeInfo';
        if ($('form').form('validate')) {
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $grid.datagrid('load');
                    $dialog.dialog('close');
                } else
                    parent.$.messager.alert('提示', result.msg, 'error');
            }, 'json');
        }
    };
    $(function () {
        //初始化表单数据
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/NoticeInfo.ashx/GetNoticeInfoByID', {
                ID: $('#id').val()
            }, function (result) {
                parent.$.messager.progress('close');
                if (!result.success && result.total == -1) {
                    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                        parent.location.replace('index.aspx');
                    });
                }
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id
                    });
                    $('#deptname').html(result.rows[0].deptname);
                    $('#receivername').html(result.rows[0].receivername);
                    $('#noticetitle').html(result.rows[0].noticetitle);
                    $('#noticecontent').html(result.rows[0].noticecontent);
                    $('#publisher').html(result.rows[0].publisher);
                    $('#publishtime').html(result.rows[0].publishtime.replace(/\//g, '-'));
                }
            }, 'json');
        }

    });
</script>
<form method="post">
<table class="table table-bordered  table-hover">
<tr>
        <td style="text-align: right">
          <input type="hidden" id="id" name="id" value="<%=id %>" />
            单位名称：
        </td>
        <td id="deptname">
        </td>
    </tr>
   <tr>
        <td style="text-align: right">
            发信人：
        </td>
        <td id="publisher">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            发信时间：
        </td>
        <td id="publishtime">
        </td>
    </tr>
     
    <tr>
        <td style="text-align: right; width: 80px;">
          
            标题：
        </td>
        <td id="noticetitle">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            内容：
        </td>
        <td id="noticecontent">
        </td>
    </tr>
     <tr>
        <td style="text-align: right;">
            回复：
        </td>
        <td>
            <textarea name="replycontent" id="replycontent" class="easyui-validatebox" required style="width: 450px;
                height: 160px;"></textarea>
        </td>
    </tr>
</table>
</form>
