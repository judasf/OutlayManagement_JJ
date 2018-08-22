<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>报表报送</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--报表报送管理;稽核、统计员可报送报表,管理员可删除，处长和浏览用户可查看--%>
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
         var roleid=<%=roleid%>;
    </script>
    <%} %>
    <script type="text/javascript">
        var grid;
        var addFun = function () {
            var dialog = parent.$.modalDialog({
                title: '添加报表报送',
                width: 600,
                height: 550,
                iconCls: 'ext-icon-chart_bar_add',
                href: 'ReportInfo/dialogop/ReportInfo_op.aspx',
                buttons: [{
                    text: '添加',
                    handler: function () {
                        parent.onFormSubmit(dialog, grid);
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
        var editFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '编辑报表',
                width: 600,
                height: 550,
                iconCls: 'icon-edit',
                href: 'ReportInfo/dialogop/ReportInfo_op.aspx?id=' + id,
                buttons: [{
                    text: '保存',
                    handler: function () {
                        parent.onFormSubmit(dialog, grid);
                    }
                },
                {
                    text: '取消',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }]
            });
        };
        var removeFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要删除此记录？', function (r) {
                if (r) {
                    $.post('../service/ReportInfo.ashx/RemoveReportInfoByID', {
                        ID: id
                    }, function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //选择单位报送报表
        var sendReportFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '报送报表',
                width: 350,
                height: 380,
                iconCls: 'ext-icon-group',
                href: 'ReportInfo/dialogop/SendReportToDepts_OP.aspx?ID=' + id,
                buttons: [{
                    text: '报送报表',
                    handler: function () {
                        parent.onSendReportFormSubmit(dialog, grid);
                    }
                },
                {
                    text: '取消',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }]
            });
        };
        //查看详情
        var viewFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '详情',
                width: 400,
                height: 500,
                iconCls: 'ext-icon-page',
                href: 'ReportInfo/dialogop/ViewReportDetail_op.aspx?id=' + id,
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
        //删除已报送的报表信息
        var removeFun = function (id) {
            parent.$.messager.confirm('删除', '您确认要删除该项报表？', function (r) {
                if (r) {
                    $.post('../service/ReportInfo.ashx/RemoveHasPublishedReport',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
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
            grid.datagrid('load', $.serializeObject($('#searchForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#searchForm input').val('');
            grid.datagrid('load', {});
        };
        $(function () {
            grid = $('#grid').datagrid({
                title: '报表报送管理',
                url: '../service/ReportInfo.ashx/GetReportInfo',
                striped: true,
                rownumbers: true,
                pagination: true,
                singleSelect: true,
                fit: true,
                border: false,
                noheader: true,
                pageSize:20,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                columns: [[{
                    width: '80',
                    title: '报送日期',
                    field: 'publishdate',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '200',
                    title: '接收单位',
                    field: 'receivers',
                    halign: 'center',
                    align: 'left'
                }, {
                    width: '150',
                    title: '标题',
                    field: 'reporttitle',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '150',
                    title: '报表名称',
                    field: 'reportpath',
                    halign: 'center',
                    align: 'center',
                    formatter: function (val) {
                        var str = '无报送报表';
                        if (val)
                            str = val.substr(val.lastIndexOf('/') + 1);
                        return str;
                    }
                }, {
                    width: '60',
                    title: '报送人',
                    field: 'publisher',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '50',
                    title: '状态',
                    field: 'status',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        return (value == 0) ? '待报送' : '已报送';
                    }
                }, {
                    width: '55',
                    title: '回执情况',
                    field: 'receiptstatus',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        return (value == 1) ? '未完成' : '已完成';
                    }
                }
                , {
                    title: '操作',
                    field: 'action',
                    width: '100',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        //稽核，统计能编辑、删除未发布的信息
                        if ((roleid == 2 || roleid == 5) && row.status == 0) {
                            str += $.formatString('<a href="javascript:void(0);" title="编辑" onclick="editFun(\'{0}\');">编辑</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);"  title="删除" onclick="removeFun(\'{0}\');">删除</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);"  title="报送" onclick="sendReportFun(\'{0}\');">报送</a>', row.id);
                        }
                        //已发布的通知可查看各个单位回执
                        if (row.status == 1) {
                            str += $.formatString('<a href="javascript:void(0);" title="查看详情" onclick="viewFun(\'{0}\');">查看详情</a>&nbsp;', row.id);
                            if (roleid == 6)//管理员可删除
                                str += $.formatString('<a href="javascript:void(0);" title="删除" onclick="removeFun(\'{0}\');">删除</a>&nbsp;', row.id);
                        }
                        return str;
                    }
                }]],
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
                    $(this).datagrid('tooltip', ['receivers', 'reporttitle', 'reportpath']);
                }
            });
            var pager = $('#grid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
            });
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar">
            <form id="searchForm" style="margin: 0;">
            <table>
                <tr>
                    <% if(roleid == 2 || roleid == 5)//稽核，统计
                       { %>
                    <td>
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-email_add',plain:true"
                            onclick="addFun();">添加报表报送</a>
                    </td>
                    <td>
                        <div class="datagrid-btn-separator">
                        </div>
                    </td>
                    <%} %>
                    <td width="70" align="right">
                        报送日期：
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
                        <input name="status" style="width: 60px;" id="status" class="easyui-combobox" style="width: 100px;"
                            data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'0',
			text: '待报送'
		},{
			id: '1',
			text: '已报送'
		}]" />
                    </td>
                    <td width="70" align="right">
                        回执情况：
                    </td>
                    <td>
                        <input name="receiptstatus" style="width: 60px;" id="receiptstatus" class="easyui-combobox"
                            style="width: 100px;" data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'1',
			text: '未完成'
		},{
			id: '2',
			text: '已完成'
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
        <table id="grid">
        </table>
    </div>
</body>
</html>
