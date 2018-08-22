<%@ Page Language="C#" %>

<% 
    /** 
     *基层用户单位查看回执报表详情
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
            $.post('service/ReportInfo.ashx/GetReceiptReportInfoByID', {
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
                    $('#reportTitle').html(result.rows[0].reporttitle);
                    $('#reportContent').html(result.rows[0].reportcontent);
                    $('#publisher').html(result.rows[0].publisher);
                    $('#publishTime').html(result.rows[0].publishtime.replace(/\//g, '-'));
                    //报送报表路径
                    var val = result.rows[0].reportpath;
                    var reportName = "无报送报表";
                    if (val) {
                        reportName = $.formatString('{0}&nbsp;&nbsp;&nbsp;&nbsp;<a href="{1}"  title="点击下载报表">点击下载报表</a>', val.substr(val.lastIndexOf('/') + 1), val);
                    }
                    $('#reportPath').html(reportName);
                    //存在已回执的报表，显示报表信息
                    var receiptVal = result.rows[0].receiptreport;
                    var receiptReportName = "无回执报表";
                   
                        if (receiptVal) {
                            receiptReportName = $.formatString('{0}&nbsp;&nbsp;&nbsp;&nbsp;<a href="{1}"  title="点击下载报表">点击下载报表</a>', receiptVal.substr(receiptVal.lastIndexOf('/') + 1), receiptVal);
                        }
                        $('#receiptReportName').html(receiptReportName);
                        $('#receiptUser').html(result.rows[0].receiptuser);
                        $('#receiptTime').html(result.rows[0].receipttime.replace(/\//g, '-'));
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
            标题：
        </td>
        <td id="reportTitle">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            内容：
        </td>
        <td id="reportContent">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            报表名称：
        </td>
        <td id="reportPath">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            报送人：
        </td>
        <td id="publisher">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            报送时间：
        </td>
        <td id="publishTime">
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            回执报表：
        </td>
        <td>
            <span id="receiptReportName"></span>
        </td>
    </tr>
     <tr>
        <td style="text-align: right">
            回执人：
        </td>
        <td id="receiptUser">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            回执时间：
        </td>
        <td id="receiptTime">
        </td>
    </tr>
</table>
</form>
