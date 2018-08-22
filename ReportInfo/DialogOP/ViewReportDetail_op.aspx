<%@ Page Language="C#" %>

<% 
    /*
     * 显示报表详情以及接收单位回执信息
     */
    //报表信息表ReportInfo中的id
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
    //通过认证    
    if(Request.IsAuthenticated)
    {
        UserDetail ud = new UserDetail();
        int roleid = ud.LoginUser.RoleId;
%>
<script type="text/javascript">
     var roleid=<%=roleid%>
</script>
<%}%>
<script type="text/javascript">
    //查看各单位报表回执详情
    var viewReceiptGrid = function (id) {
        var viewdialog = $('<div id="receiptGrid" />').dialog({
            title: '各单位报表回执详情',
            width: 630,
            height: 565,
            modal: true,
            iconCls: 'ext-icon-page',
            href: 'ReportInfo/dialogop/ViewReceiptGrid_op.aspx?reportid=' + $('#id').val(),
            onClose: function () {
                $(this).dialog('destroy');
            },
            buttons: [
            {
                text: '关闭',
                handler: function () {
                    viewdialog.dialog('close');
                }
            }
            ]
        });
    };
    $(function () {
        //加载数据
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/ReportInfo.ashx/GetReportInfoByID', {
                ID: $('#id').val()
            }, function (result) {
                if (!result.success && result.total == -1) {
                    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                        parent.location.replace('index.aspx');
                    });
                }
                if (result.rows && result.rows[0].id != undefined) {
                    parent.$.messager.progress('close');
                    $('#id').val(result.rows[0].id);
                    $('#receivers').html(result.rows[0].receivers);
                    $('#reportTitle').html(result.rows[0].reporttitle);
                    $('#reportContent').html(result.rows[0].reportcontent);
                    $('#publisher').html(result.rows[0].publisher);
                    $('#publishTime').html(result.rows[0].publishtime.replace(/\//g, '-'));
                    //报表路径
                    var val = result.rows[0].reportpath;
                    var reportName = "无报送报表";
                    if (val) {
                        reportName = $.formatString('{0}&nbsp;&nbsp;&nbsp;&nbsp;<a href="{1}"  title="点击下载报表">点击下载报表</a>', val.substr(val.lastIndexOf('/') + 1), val);
                    }
                    $('#reportPath').html(reportName);
                }
            }, 'json');
        }
    });
</script>
<table class="table table-bordered table-condensed" style="margin-bottom: 0;">
    <tr>
        <td style="text-align: right; width: 80px">
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            接收单位：
        </td>
        <td id="receivers">
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
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
        <td style="text-align: right">
            回执详情：
        </td>
        <td>
            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table',plain:true"
                            onclick="viewReceiptGrid();">点击查看报表回执详情</a>
        </td>
    </tr>
</table>