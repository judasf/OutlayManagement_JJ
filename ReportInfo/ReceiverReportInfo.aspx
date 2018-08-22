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
    <%--基层用户查看，处理，反馈自己的报表--%>
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
        //回执报表
        var receiptReportFun = function (id, isread) {
            var dialog = parent.$.modalDialog({
                title: '回执报表',
                width: 580,
                height: 500,
                iconCls: 'ext-icon-page',
                href: 'ReportInfo/dialogop/receiptReport_op.aspx?id=' + id,
                onLoad: function () {
                    //设置已读
                    if (isread == '0') {
                        $.post('../service/ReportInfo.ashx/SetReportHasRead', { id: id }, function (result) {
                            if (result.success) {
                                grid.datagrid('reload');
                            } else
                                parent.$.messager.alert('提示', result.msg, 'error');
                        }, 'json');
                    }
                },
                buttons: [{
                    text: '回执',
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
        //查询功能
        var searchGrid = function () {
            grid.datagrid('load', $.serializeObject($('#searchForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#searchForm input').val('');
            grid.datagrid('load', {});
        };
        //查看回执报表详情
        var viewReceiptReportFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '详情',
                width: 630,
                height: 500,
                iconCls: 'ext-icon-page',
                href: 'ReportInfo/dialogop/ViewReceiptReportDetail_op.aspx?id=' + id,
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
        $(function () {
            grid = $('#grid').datagrid({
                title: '报表报送管理',
                url: '../service/ReportInfo.ashx/GetDeptReportInfoByDeptId',
                striped: true,
                fit: true,
                rownumbers: true,
                pagination: true,
                singleSelect: true,
                border: false,
                noheader: true,
                pageSize:20,
                idField: 'a.id',
                sortName: 'a.id',
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
                    title: '标题',
                    field: 'reporttitle',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '200',
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
                    field: 'isreceipted',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        return (value == 0) ? '待回执' : '已回执';
                    }
                }
                , {
                    title: '操作',
                    field: 'action',
                    width: '60',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        //基层用户回执已报送的报表
                        if (row.status == 1&& row.isreceipted == 0 && roleid == 1) {
                            str += $.formatString('<a href="javascript:void(0);" title="回执报表" onclick="receiptReportFun(\'{0}\',\'{1}\');">回执报表</a>&nbsp;', row.id, row.isread);
                        }
                        if (row.isreceipted == 1)
                            str += $.formatString('<a href="javascript:void(0);" title="查看详情" onclick="viewReceiptReportFun(\'{0}\');">查看详情</a>&nbsp;', row.id);
                        return str;
                    }
                }]],
                rowStyler: function (index, row) {
                    if (row.isread == 0)
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
                    $(this).datagrid('unselectAll');
                    $(this).datagrid('tooltip', ['receivers', 'reporttitle']);
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
                        <input name="IsReceipted" style="width: 60px;" id="IsReceipted" class="easyui-combobox"
                            style="width: 100px;" data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'0',
			text: '待回执'
		},{
			id: '1',
			text: '已回执'
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
