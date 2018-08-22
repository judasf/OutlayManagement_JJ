<%@ Page Language="C#" %>

<% 
    /** 
     *查看意见详情
     */
    //报表信息表ReportInfo中的id
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
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
                    $('#receivername').html(result.rows[0].receivername);
                    $('#noticetitle').html(result.rows[0].noticetitle);
                    $('#noticecontent').html(result.rows[0].noticecontent);
                    $('#publisher').html(result.rows[0].publisher);
                    $('#publishtime').html(result.rows[0].publishtime.replace(/\//g, '-'));
                    //报送报表路径 replyConTr
                    if (result.rows[0].isreply == 1) {
                        $('#replyConTr').show();
                        $('#replycontent').html(result.rows[0].replycontent);
                        $('#replyTimeTr').show();
                        $('#replytime').html(result.rows[0].replytime.replace(/\//g, '-'));
                    }
                  
                }
            }, 'json');
        }
    });
</script>
<form method="post">
<table class="table table-bordered  table-hover">
    <tr>
        <td style="text-align: right">
            收信人：
        </td>
        <td id="receivername">
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 80px;">
            <input type="hidden" id="id" name="id" value="<%=id %>" />
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
    <tr id="replyConTr" style="display:none;">
        <td style="text-align: right">
            回复内容：
        </td>
        <td id="replycontent">
        </td>
    </tr>
    <tr id="replyTimeTr" style="display:none;">
        <td style="text-align: right">
            回复时间：
        </td>
        <td id="replytime">
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
</table>
</form>
