<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>意见信箱</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--基层用户:发信，查看回复--%>
    <%  int roleid = 0;
        if(!Request.IsAuthenticated)
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
            roleid = ud.LoginUser.RoleId;
    %>
    <script type="text/javascript">
        var roleid = '<%=roleid%>';
    </script>
    <%} %>
    <script type="text/javascript">
        var noticeGrid;
        var addNotice = function () {
            var dialog = parent.$.modalDialog({
                title: '添加意见',
                width: 580,
                height: 480,
                iconCls: 'ext-icon-note_add',
                href: 'NoticeInfo/dialogop/NoticetInfo_op.aspx',
                buttons: [{
                    text: '添加',
                    handler: function () {
                        parent.onFormSubmit(dialog, noticeGrid);
                    }
                },
                {
                    text: '取消',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }
                ]
            });
        };
        //查看详情，并打印
        var viewFun = function (id,isreply,ispublisherreadreply) {
            var dialog = parent.$.modalDialog({
                title: '详情',
                width: 400,
                height: 400,
                iconCls: 'ext-icon-page',
                href: 'NoticeInfo/dialogop/ViewNoticeInfoDetail_op.aspx?id=' + id,
                 onLoad: function () {
                    //设置收信人已读
                    if (isreply == '1'&& ispublisherreadreply=='0') {
                        $.post('../service/NoticeInfo.ashx/SetNoticeHasPublisherReadReply', { id: id }, function (result) {
                            if (result.success) {
                                noticeGrid.datagrid('reload');
                            } else
                                parent.$.messager.alert('提示', result.msg, 'error');
                        }, 'json');
                    }
                },
                buttons: [
                {
                    text: '关闭',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }
                 ]
            });
        };
        //查询功能
        var searchGrid = function () {
            noticeGrid.datagrid('load', $.serializeObject($('#noticeForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#noticeForm input').val('');
            noticeGrid.datagrid('load', {});
        };
        $(function () {
            /*datagrid生成*/
            noticeGrid = $('#noticeGrid').datagrid({
                title: '意见信箱管理',
                url: '../service/NoticeInfo.ashx/GetNoticeInfo',
                striped: true,
                rownumbers: true,
                fit: true,
                border: false,
                noheader: true,
                pagination: true,
                showFooter: true,
                pageSize: 20,
                singleSelect: true,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                columns: [[{
                    width: '75',
                    title: '日期',
                    field: 'publishdate',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '65',
                    title: '收信人',
                    field: 'receivername',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '240',
                    title: '标题',
                    field: 'noticetitle',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '60',
                    title: '状态',
                    field: 'isreply',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        return (value == 0) ? '待回复' : '已回复';
                    }
                }, {
                    title: '操作',
                    field: 'action',
                    width: '60',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                       var str='';
                            //，可查看
                            str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\',\'{1}\',\'{2}\');">查看详情</a>', row.id,row.isreply,row.ispublisherreadreply);
                        return str;
                    }
                }]],
                rowStyler: function (index, row) {
                    if (row.isreply == 1 && row.ispublisherreadreply==0)
                        return 'color:#f00;font-weight:700;';
                },
                toolbar: '#toolbar',
                onLoadSuccess: function (data) {
                    parent.$.messager.progress('close');
                    if (!data.success && data.total == -1) {
                        parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                            parent.location.replace('index.aspx');
                        });
                    }
                    if (data.rows.length == 0) {
                        var body = $(this).data().datagrid.dc.body2;
                        body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                    }
                    $(this).datagrid('tooltip', ['noticetitle']);
                }
            });
            //设置分页属性
            var pager = $('#noticeGrid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar" style="display: none;">
            <form id="noticeForm" style="margin: 0;">
            <table>
                <tr>
                    <% if(roleid == 1)
                       { %>
                    <td>
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-email_add',plain:true"
                            onclick="addNotice();">添加意见</a>
                    </td>
                    <td>
                        <div class="datagrid-btn-separator">
                        </div>
                    </td>
                    <%} %>
                    <td width="50" align="right">
                        日期：
                    </td>
                    <td>
                        <input style="width: 85px;" name="publish_sdate" id="publish_sdate" class="Wdate"
                            onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'publish_edate\')}',maxDate:'%y-%M-%d'})"
                            readonly="readonly" />-<input style="width: 85px;" name="publish_edate" id="publish_edate"
                                class="Wdate" onfocus="WdatePicker({minDate:'#F{$dp.$D(\'publish_sdate\')}',maxDate:'%y-%M-%d'})"
                                readonly="readonly" />
                    </td>
                    <td width="60" align="right">
                        状态：
                    </td>
                    <td>
                        <input name="isreply" style="width: 60px;" id="isreply" class="easyui-combobox" style="width: 100px;"
                            data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'0',
			text: '待回复'
		},{
			id: '1',
			text: '已回复'
		}]" />
                    </td>
                    <td>
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                            onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">
                                重置</a>
                    </td>
                </tr>
            </table>
            </form>
        </div>
        <table id="noticeGrid">
        </table>
    </div>
</body>
</html>
