<%@ Page Language="C#" %>

<% 
    /** 
     *AuditApplyOutlayDetail表操作对话框，查看申请报告详情并打印
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    ////通过申请经费确认打印申请报告
    //var printDetail = function () {
    //    window.showModalDialog("/print.htm", $('#printContent').html(),
    //"location:No;status:No;help:No;dialogWidth:800px;dialogHeight:600px;scroll:auto;");
    //};
    //照片展示插件
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
                    $('#ProjectAttList').append('<span style="margin-right:10px;"><a class="ext-icon-attach" style="padding-left:20px;" href="' + item.attfilepath + '"   title="' + item.attfilename + '">' + item.attfilename + '</a></span>');
                });
            }
        }, 'json');
    };
    $(function () {

        if ($('#auditApplyOutlyId').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/AuditApplyOutlayAllocate.ashx/GetAuditApplyOutlayDetailByID', {
                ID: $('#auditApplyOutlyId').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('#deptName').html(result.rows[0].deptname);
                    $('#applyTime').html(result.rows[0].applytime.replace(/\//g, '-'));
                    $('#title').html(result.rows[0].applytitle);
                    $('#content').html(result.rows[0].applycontent);
                    $('#applyUser').html(result.rows[0].applyuser);
                    $('#applyOutlay').html(result.rows[0].applyoutlay);
                    $('#outlayCategory').html(result.rows[0].cname);
                    $('#usefor').html(result.rows[0].usefor);
                    showFileList(result.rows[0].id);
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
    });
   
</script>
<div id="printContent">
    <table class="table table-bordered  table-hover">
        <tr>
            <th colspan="4" style="text-align: center; font-size: 14px;">
                直接拨付经费申请报告
            </th>
        </tr>
        <tr>
            <td style="text-align: right; width: 80px">
                追加单位：
            </td>
            <td>
                <span id="deptName"></span>
            </td>
            <td style="text-align: right; width: 80px">
                申请时间：
            </td>
            <td>
                <span id="applyTime"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right; width: 80px">
                标题：
            </td>
            <td colspan="3">
                <input type="hidden" id="auditApplyOutlyId" name="auditApplyOutlyId" value="<%=id %>" />
                <span id="title"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">
                内容：
            </td>
            <td colspan="3">
                <div id="content">
                </div>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">
                经办人：
            </td>
            <td>
                <span id="applyUser"></span>
            </td>
            <td style="text-align: right">
                申请额度：
            </td>
            <td>
                <span id="applyOutlay"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">
                经费类别：
            </td>
            <td colspan="3">
                <span id="outlayCategory"></span>
            </td>
        </tr>
        <tr>
            <td style="text-align: right">
                经费用途：
            </td>
            <td colspan="3">
                <div id="usefor">
                </div>
            </td>
        </tr>
         <tr>
            <td style="text-align: right">
                上传图片：
            </td>
            <td colspan="3">
                <div id="ProjectAttList">
                </div>
            </td>
        </tr>
    </table>
</div>
