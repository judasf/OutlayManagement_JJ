<%@ Page Language="C#" %>

<% 
    /** 
     *基层用户单位回执报表信息
     */
    //报表信息表ReportInfo中的id
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //提交表单

    var onFormSubmit = function ($dialog, $grid) {
          var   url = 'service/ReportInfo.ashx/UpdateReceiptReportInfo';
        if ($('form').form('validate')) {
            //判断是否有报表上传
            if ($('#reportNum').val() == "1" && $('#report').val() == "") {
                parent.$.messager.alert('提示', '请上传报表后再进行回执！', 'error');
                return;
            }
            else {
                $.post(url, $.serializeObject($('form')), function (result) {
                    if (result.success) {
                        $grid.datagrid('load');
                        $dialog.dialog('close');
                    } else
                        parent.$.messager.alert('提示', result.msg, 'error');
                }, 'json');
            }
        }
    };
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
                    //报表路径
                    var val = result.rows[0].reportpath;
                    var reportName = "无报送报表";
                    if (val) {
                        reportName = $.formatString('{0}&nbsp;&nbsp;&nbsp;&nbsp;<a href="{1}"  title="点击下载报表">点击下载报表</a>', val.substr(val.lastIndexOf('/') + 1), val);
                    }
                    $('#reportPath').html(reportName);
                    //存在已回执的报表，显示报表信息
                    var receiptVal = result.rows[0].receiptreport;
                    if (receiptVal) {
                        $('#report').val(receiptVal);
                        $('#reportName').html(receiptVal.substr(receiptVal.lastIndexOf('/') + 1));
                        $('#reportTr').show();
                  }

                }
            }, 'json');
        }
        //初始化上传插件
        $("#file_upload").uploadify({
            //开启调试
            'debug': false,
            //是否自动上传
            'auto': false,
            //上传成功后是否在列表中删除
            'removeCompleted': false,
            //在文件上传时需要一同提交的数据
            'formData':{'floderName':'ReportInfo'},
            'buttonText': '选择报表',
            //flash
            'swf': "js/uploadify/uploadify.swf",
            //文件选择后的容器ID
            'queueID': 'uploadfileQueue',
            'uploader': 'js/uploadify/uploadify.ashx',
            'width': '75',
            'height': '24',
            'multi': false,
            'fileTypeDesc': '支持的格式：',
            'fileTypeExts': '*.xls;*.doc;*.rar;*.zip',
            'fileSizeLimit': '50MB',
            'removeTimeout': 1,
            'queueSizeLimit': 1,
            'uploadLimit': 1,
            'overrideEvents': ['onDialogClose', 'onSelectError', 'onUploadError'],
            'onDialogClose': function (queueData) {
                $('#reportNum').val(queueData.queueLength);
            },
            'onCancel': function (file) {
                $('#reportNum').val(0);
            },
            //返回一个错误，选择文件的时候触发
            'onSelectError': function (file, errorCode, errorMsg) {
                switch (errorCode) {
                    case -100:
                        parent.$.messager.alert('出错', '只能上传' + $('#file_upload').uploadify('settings', 'queueSizeLimit') + '个报表文件！', 'error');
                        break;
                    case -110:
                        parent.$.messager.alert('出错', '文件“' + file.name + '”大小超出系统限制的' + $('#file_upload').uploadify('settings', 'fileSizeLimit') + '大小！', 'error');
                        break;
                    case -120:
                        parent.$.messager.alert('出错', '文件“' + file.name + '”大小异常！', 'error');
                        break;
                    case -130:
                        parent.$.messager.alert('出错', '文件“' + file.name + '”类型不正确，请选择正确的Excel文件,Word文件或者压缩包文件！', 'error');
                        break;
                }
            },
            //返回一个错误，文件上传出错的时候触发
            'onUploadError': function (file, errorCode, errorMsg) {
                switch (errorCode) {
                    case -200:
                        parent.$.messager.alert('出错', '网络错误请重试,错误代码：'+errorMsg, 'error');
                        break;
                    case -210:
                        parent.$.messager.alert('出错', '上传地址不存在，请检查！', 'error');
                        break;
                    case -220:
                        parent.$.messager.alert('出错', '系统IO错误！', 'error');
                        break;
                    case -230:
                        parent.$.messager.alert('出错', '系统安全错误！', 'error');
                        break;
                    case -240:
                        parent.$.messager.alert('出错', '请检查文件格式！', 'error');
                        break;
                }
            },
            //检测FLASH失败调用
            'onFallback': function () {
                parent.$.messager.alert('出错', '您未安装FLASH控件，无法上传图片！请安装FLASH控件后再试!', 'error');
            },
            //上传到服务器，服务器返回相应信息到data里
            'onUploadSuccess': function (file, data, response) {
                if (data) {
                    var result = $.parseJSON(data);
                    if (result.success) {
                        $('#report').val(result.filepath);
                        $('#reportName').html(file.name);
                        $('#reportTr').show();
                    }
                    else
                        parent.$.messager.alert('出错', result.msg, 'error');
                }
            }
        });
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
    <tr id="reportTr" style="display: none;">
        <td style="text-align: right;">
            回执报表：
        </td>
        <td>
            <span id="reportName"></span>
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            报表上传：
        </td>
        <td>
            <input type="hidden" name="report" id="report" />
            <input type="hidden" name="reportNum" id="reportNum" value="0" />
            <div class="clearfix">
                <div id="uploadfileQueue" style="float: right; width: 380px;">
                </div>
                <div style="width: 75px; float: left; text-align: center;">
                    <input id="file_upload" name="file_upload" type="file" />
                    <div class="uploadify-button" style="height: 24px; cursor: pointer; line-height: 24px;
                        width: 75px;" onclick="$('#file_upload').uploadify('upload', '*');">
                        <span class="uploadify-button-text">上传报表</span></div>
                </div>
            </div>
        </td>
    </tr>
</table>
</form>
