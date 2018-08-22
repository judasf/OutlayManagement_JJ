<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Department.aspx.cs" Inherits="BaseInfo_Department" %>

<!DOCTYPE html>
<html>
<head>
    <title>部门管理</title>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../css/bootstrap.min.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <%  int roleid = 0;
        if (!Request.IsAuthenticated)
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
        var roleid='<%=roleid%>'
    </script>
    <%} %>
    <script type="text/javascript">
        var grid;
        var addFun = function () {
            var dialog = parent.$.modalDialog({
                title: '添加单位',
                width: 350,
                height: 160,
                iconCls: 'ext-icon-group_add',
                href: 'baseinfo/dialogop/Department_OP.aspx', //将对话框内容添加到父页面
                buttons: [{
                    text: '添加',
                    handler: function () {
                        parent.onDeptFormSubmit(dialog, grid);
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
        var editFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '编辑单位信息',
                width: 350,
                height: 160,
                iconCls: 'ext-icon-group_edit',
                href: 'baseinfo/dialogop/Department_OP.aspx?DeptID=' + id,
                buttons: [{
                    text: '保存',
                    handler: function () {
                        parent.onDeptFormSubmit(dialog, grid);
                    }
                }]
            });
        };
        var removeFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要删除此记录？', function (r) {
                if (r) {
                    $.post('../service/Department.ashx/RemoveDepartmentByID', {
                        deptID: id
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
        //导单位信息excel
        var exportDepartment = function () {
            jsPostForm('../service/Department.ashx/ExportDepartment');
        };
        $(function () {
            grid = $('#grid').datagrid({
                title: '单位信息表',
                url: '../service/Department.ashx/GetDepartmentInfo',
                striped: true,
                rownumbers: true,
                pagination: true,
                singleSelect: true,
                noheader: true,
                pageSize:20,
                idField: 'deptid',
                sortName: 'deptid',
                sortOrder: 'asc',
                columns: [[{
                    width: '200',
                    title: '单位名称',
                    field: 'deptname',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                },
                {
                    title: '操作',
                    field: 'action',
                    width: '50',
                    halign: 'center',
                    formatter: function (value, row) {
                        var str = '';

                        str += $.formatString('<img src="../js/easyui/themes/icons/pencil.png" title="编辑" onclick="editFun(\'{0}\');"/>&nbsp;&nbsp;', row.deptid);
                        str += $.formatString('<img src="../js/easyui/themes/icons/no.png" title="删除" onclick="removeFun(\'{0}\');"/>', row.deptid);
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
                }
            });
            var pager = $('#grid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
            });
            //非管理员隐藏操作列
            if (roleid != 6)
                $('#grid').datagrid('hideColumn', 'action');
        });
    </script>
</head>
<body class="easyui-layout">
    <div id="toolbar" style="display: none; padding: 5px 10px 0;">
        <table>
            <tr>
                <%if (roleid == 6)
                  { %>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-group_add',plain:true"
                        onclick="addFun();">添加单位</a>
                </td>

                <td>
                    <div class="datagrid-btn-separator">
                    </div>
                </td>
                <%} %>
                <td>
                    <input id="searchBox" class="easyui-searchbox" style="width: 150px;" data-options="searcher:function(value,name){grid.datagrid('load',{where:'DeptName like \'%'+encodeURIComponent(value)+'%\''});},prompt:'请输入单位名称'" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                        onclick="$('#searchBox').searchbox('setValue','');grid.datagrid('load',{});">清空查询</a>
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                        onclick="exportDepartment();">导出</a>
                </td>
            </tr>
        </table>
    </div>
    <div data-options="region:'center',fit:true,border:false">
        <table id="grid" data-options="fit:true,border:false">
        </table>
    </div>
</body>
</html>
