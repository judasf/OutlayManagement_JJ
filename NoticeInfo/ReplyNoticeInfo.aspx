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
    <%--非基层用户:回复信息--%>
    <%  int roleid = 0;
        int uid = 0;
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
            uid = ud.LoginUser.UID;
    %>
    <script type="text/javascript">
        var roleid=<%=roleid%>;
        var uid=<%=uid%>;
    </script>
    <%} %>
    <script type="text/javascript">
        var replyNoticeGrid;
        var replyNoticeFun = function (id, isreceiverread) {
            var dialog = parent.$.modalDialog({
                title: '回复意见',
                width: 580,
                height: 480,
                iconCls: 'ext-icon-note_add',
                href: 'NoticeInfo/dialogop/ReplyNoticeInfo_op.aspx?id=' + id,
                onLoad: function () {
                    //设置收信人已读
                    if (isreceiverread == '0' && roleid != 6) {
                        $.post('../service/NoticeInfo.ashx/SetNoticeHasReceiverRead', { id: id }, function (result) {
                            if (result.success) {
                                replyNoticeGrid.datagrid('reload');
                            } else
                                parent.$.messager.alert('提示', result.msg, 'error');
                        }, 'json');
                    }
                },
                buttons: [{
                    text: '回复',
                    handler: function () {
                        parent.onFormSubmit(dialog, replyNoticeGrid);
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
        var viewFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '详情',
                width: 400,
                height: 400,
                iconCls: 'ext-icon-page',
                href: 'NoticeInfo/dialogop/ViewNoticeInfoDetail_op.aspx?id=' + id,
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
        //管理员操作 begin
        //删除已回复并且发信人已读的信息
        var removePublisherHasReadNotice = function (id) {
            parent.$.messager.confirm('删除', '您确认要删除该项意见？', function (r) {
                if (r) {
                    $.post('../service/NoticeInfo.ashx/RemovePublisherHasReadNotice',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            replyNoticeGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //管理员操作 begin
        //查询功能
        var searchGrid = function () {
            replyNoticeGrid.datagrid('load', $.serializeObject($('#noticeForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#noticeForm input').val('');
            replyNoticeGrid.datagrid('load', {});
        };
        $(function () {
            /*datagrid生成*/
            replyNoticeGrid = $('#replyNoticeGrid').datagrid({
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
                    title: '发信人',
                    field: 'publisher',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '80',
                    title: '单位名称',
                    field: 'deptname',
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
                    width: '90',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        if (roleid != 1 && row.isreply == 0 && row.receiveruid==uid) {
                            //非基层用户回复自己的信息
                            str += $.formatString('<a href="javascript:void(0);" onclick="replyNoticeFun(\'{0}\',\'{1}\');">意见回复</a>', row.id, row.isreceiverread);
                        }
                        if (row.isreply == 1)
                        //可查看
                            str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">查看详情</a>&nbsp;', row.id);
                        if (roleid == 6 && row.ispublisherreadreply == 1)
                        //可删除
                            str += $.formatString('<a href="javascript:void(0);" onclick="removePublisherHasReadNotice(\'{0}\');">删除</a>&nbsp;&nbsp;', row.id);
                        return str;
                    }
                }]],
                rowStyler: function (index, row) {
                    if (row.isreceiverread == 0 && row.receiveruid == uid)
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
            var pager = $('#replyNoticeGrid').datagrid('getPager');
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
                    <td width="80" align="right">
                        单位名称：
                    </td>
                    <td>
                        <input name="deptId" id="deptId" style="width: 100px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 100,
                    panelHeight: '180',
                    editable:false,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                    </td>
                    <td width="70" align="right">
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
                        <input name="status" style="width: 60px;" id="isreply" class="easyui-combobox" style="width: 100px;"
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
        <table id="replyNoticeGrid">
        </table>
    </div>
</body>
</html>
