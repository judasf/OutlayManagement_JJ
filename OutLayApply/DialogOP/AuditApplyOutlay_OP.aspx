<%@ Page Language="C#" %>

<% 
    /** 
     *AuditOutlayApplyDetail表操作对话框，稽核追加经费申请
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/AuditApplyOutlayAllocate.ashx/SaveAuditApplyOutlayDetail';
            } else {
                url = 'service/AuditApplyOutlayAllocate.ashx/UpdateAuditApplyOutlayDetail';
            }
            if ($('#report').val() == "" && $('#reportNum').val() > 0) {
                parent.$.messager.alert('提示', '请上传附件后再提交信息！', 'error');
                return;
            }
            parent.$.messager.confirm('询问', '您确定提交该项费用申请？', function (r) {
                if (r) {
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $grid.datagrid('load');
                            $dialog.dialog('close');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
          
        }
    };
    //维修过程照片展示插件
    $('#ProjectAttList').magnificPopup({
        delegate: 'a',
        type: 'image',
        tLoading: 'Loading image #%curr%...',
        mainClass: 'mfp-img-mobile',
        gallery: {
            enabled: true,
            navigateByImgClick: true,
            preload: [0, 1] // Will preload 0 - before current, and 1 after the current image
        },
        image: {
            tError: '<a href="%url%">The image #%curr%</a> could not be loaded.',
            titleSrc: function (item) {
                return item.el.attr('title') + '<small> 上传图片 </small>';
            }
        }
    });
    var showFileList = function (id) {
        /// <summary>显示已上传附件</summary>
        /// <param name="pjno" type="String">项目编号</param>
        $('#ProjectAttList').empty();
        $.post('service/AuditApplyOutlayAllocate.ashx/GetAttachmentByAAOID', { id: id }, function (fileRes) {
            if (fileRes.total > 0) {
                $.each(fileRes.rows, function (i, item) {
                    $('#ProjectAttList').append('<span style="margin-right:10px;"><a class="ext-icon-attach" style="padding-left:20px;" href="' + item.attfilepath + '"   title="' + item.attfilename + '">' + item.attfilename + '</a><img src="css/images/cross.png" title="删除" onclick="javascript:delPJAttach(' + item.id + ');"/></span>');
                });
            }
        }, 'json');
    };
    //删除已上传附件
    var delPJAttach = function (id) {
        parent.$.messager.confirm('询问', '您确定要删除该图片？', function (r) {
            if (r) {
                $.post('service/AuditApplyOutlayAllocate.ashx/RemoveAttachmentByID', {
                    id: id
                }, function (result) {
                    if (result.success) {
                        showFileList($('#id').val());
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    $(function () {
        //初始化追加单位
        $('#deptId').combobox({
            valueField: 'id',
            textField: 'text',
            required: true,
            panelWidth: 200,
            panelHeight: '180',
            editable: false,
            url: 'service/Department.ashx/GetScopeDeptsCombobox',
            onSelect: function (rec) {
                $('#deptName').val(rec.text);
            }
        });
        //初始化经费类别树
        $('#outlayCategory').combotree({
            valueField: 'id',
            textField: 'text',
            editable: false,
            required: true,
            lines: true,
            panelHeight: 'auto',
            url: 'service/category.ashx/GetCategory',
            onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            }
        });
    
        $('#applyOutlay').numberbox({
            min: 0, precision: 2, required: true,
            formatter: function (val) {
                
                $('#upperNum').html(digitUppercase(val));
                return val;
            }
        });
        //初始化编辑器
        var editor = UE.getEditor('editor');
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/AuditApplyOutlayAllocate.ashx/GetAuditApplyOutlayDetailByID', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'title': result.rows[0].applytitle,
                        'deptName': result.rows[0].deptname,
                        'usefor': result.rows[0].usefor
                    });
                    editor.ready(function () {
                        editor.setContent(result.rows[0].applycontent);
                    });
                    $('#deptId').combobox('setValue', result.rows[0].deptid);
                    $('#outlayCategory').combotree('setValue', result.rows[0].outlaycategory);
                    $('#applyOutlay').numberbox('setValue', result.rows[0].applyoutlay);
                    showFileList(result.rows[0].id);
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
        $("#file_upload").uploadify({
            //开启调试
            'debug': false,
            //是否自动上传
            'auto': false,
            //上传成功后是否在列表中删除
            'removeCompleted': false,
            //在文件上传时需要一同提交的数据
            'formData': { 'floderName': 'OutLayApply' },
            'buttonText': '浏览',
            //flash
            'swf': "js/uploadify/uploadify.swf?var=" + (new Date()).getTime(),
            //文件选择后的容器ID
            'queueID': 'uploadfileQueue',
            'uploader': 'js/uploadify/uploadify_AAO.ashx',
            'width': '75',
            'height': '24',
            'multi': true,
            'fileTypeDesc': '支持的格式：',
            'fileTypeExts': '*.jpg;*.jpeg;*.bmp;*.gif;*.png;',
            'fileSizeLimit': '5MB',
            'removeTimeout': 1,
            'queueSizeLimit': 3,
            'uploadLimit': 3,
            'overrideEvents': ['onDialogClose', 'onSelectError', 'onUploadError'],
            'onDialogClose': function (queueData) {
                $('#reportNum').val(queueData.queueLength);
            },
            'onCancel': function (file) {
                $('#reportNum').val($('#reportNum').val() - 1);
            },
            //返回一个错误，选择文件的时候触发
            'onSelectError': function (file, errorCode, errorMsg) {
                switch (errorCode) {
                    case -100:
                        parent.$.messager.alert('出错', '只能上传' + $('#file_upload').uploadify('settings', 'queueSizeLimit') + '个附件！', 'error');
                        break;
                    case -110:
                        parent.$.messager.alert('出错', '文件“' + file.name + '”大小超出系统限制的' + $('#file_upload').uploadify('settings', 'fileSizeLimit') + '大小！', 'error');
                        break;
                    case -120:
                        parent.$.messager.alert('出错', '文件“' + file.name + '”大小异常！', 'error');
                        break;
                    case -130:
                        parent.$.messager.alert('出错', '文件“' + file.name + '”类型不正确，请选择文件格式！', 'error');
                        break;
                }
            },
            //返回一个错误，文件上传出错的时候触发
            'onUploadError': function (file, errorCode, errorMsg) {
                switch (errorCode) {
                    case -200:
                        parent.$.messager.alert('出错', '网络错误请重试,错误代码：' + errorMsg, 'error');
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
                parent.$.messager.alert('出错', '您未安装FLASH控件，无法上传！请安装FLASH控件后再试!', 'error');
            },
            //上传到服务器，服务器返回相应信息到data里
            'onUploadSuccess': function (file, data, response) {
                if (data) {
                    var result = $.parseJSON(data);
                    if (result.success) {
                        var fp = $('#report').val();
                        if (fp)
                            fp += ',' + result.filepath
                        else
                            fp = result.filepath;
                        $('#report').val(fp);
                        $('#reportName').val(function () {
                            return ($(this).val().length > 0) ? this.value + ',' + file.name : file.name;
                        });
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
            <td style="text-align: right; width: 80px">追加单位：
            </td>
            <td colspan="3">
                <input type="hidden" id="id" name="id" value="<%=id %>" />
                <input type="hidden" name="deptName" id="deptName" />
                <input name="deptId" id="deptId" style="width: 200px;" />
            </td>
        </tr>
        <tr>
            <td style="text-align: right; width: 70px">标题：
            </td>
            <td colspan="3">
                <input id="title" name="title" class="easyui-validatebox " style="width: 500px;"
                    required />
            </td>
        </tr>
        <tr>
            <td style="text-align: right">内容：
            </td>
            <td colspan="3">
                <script type="text/plain" id="editor" style="width: 500px; height: 160px;">
                </script>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">经费类别：
            </td>
            <td colspan="3">
                <input name="outlayCategory" id="outlayCategory" style="width: 200px;" />
            </td>
        </tr>
        <tr>
            <td style="text-align: right;">申请额度：
            </td>
            <td>
                <input name="applyOutlay" id="applyOutlay" style="width: 200px;" />
            </td>
            <td style="text-align: right;">大写金额：
            </td>
            <td id="upperNum"></td>
        </tr>
        <tr>
            <td style="text-align: right">经费用途：
            </td>
            <td colspan="3">
                <textarea name="usefor" style="width: 490px;" id="usefor" rows="2" class="easyui-validatebox"
                    data-options="required:true"></textarea>
            </td>
        </tr>
          <tr>
            <td style="text-align: right">图片上传：</td>
            <td colspan="3">
                <div id="ProjectAttList"></div>
                <input type="hidden" name="report" id="report" />
                <input type="hidden" name="reportName" id="reportName" />
                <input type="hidden" name="reportNum" id="reportNum" value="0" />
                <div class="clearfix">
                    <div id="uploadfileQueue" style="width: 370px;">
                    </div>
                    <div style="width: 75px; float: left; text-align: center;">
                        <input id="file_upload" name="file_upload" type="file" style="text-align: left;" />
                        <div class="uploadify-button" style="height: 24px; cursor: pointer; line-height: 24px; width: 75px;"
                            onclick="$('#file_upload').uploadify('upload', '*');">
                            <span class="uploadify-button-text">上传</span>
                        </div>
                    </div>
                </div>
            </td>

        </tr>
    </table>
</form>
