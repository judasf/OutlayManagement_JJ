<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Category.aspx.cs" Inherits="BaseInfo_Category" %>

<!DOCTYPE html>
<html>
<head>
    <title>经费类别管理</title>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../css/bootstrap.min.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
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
        var roleid=<%=roleid%>
    </script>
    <%} %>
    <script type="text/javascript">
        var grid;
        var addFun = function () {
            var dialog = parent.$.modalDialog({
                title: '添加经费类别',
                width: 370,
                height: 200,
                iconCls: 'ext-icon-note_add',
                href: 'baseinfo/dialogop/Category_op.aspx', //将对话框内容添加到父页面index
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

        var editFun = function (id, level) {
            var dialog = parent.$.modalDialog({
                title: '编辑经费类别',
                width: 370,
                height: 200,
                iconCls: 'icon-edit',
                href: 'baseinfo/dialogop/Category_op.aspx?cid=' + id + '&level=' + level,
                buttons: [{
                    text: '保存',
                    handler: function () {
                        parent.onFormSubmit(dialog, grid);
                    }
                }]
            });
        };
        var removeFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要删除此记录？', function (r) {
                if (r) {
                    $.post('../service/category.ashx/RemoveCategory', {
                        cid: id
                    }, function (result) {
                        if (result.success) {
                            grid.treegrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        var redoFun = function () {
            var node = grid.treegrid('getSelected');
            if (node) {
                grid.treegrid('expandAll', node.id);
            } else {
                grid.treegrid('expandAll');
            }
        };
        var undoFun = function () {
            var node = grid.treegrid('getSelected');
            if (node) {
                grid.treegrid('collapseAll', node.id);
            } else {
                grid.treegrid('collapseAll');
            }
        };
        $(function () {
            grid = $('#grid').treegrid({
                title: '经费类别管理',
                method: 'get',
                url: '../service/category.ashx/GetCategory',
                idField: 'id',
                treeField: 'text',
                rownumbers: true,
                pagination: false,
                noheader: true,
                sortName: 'id',
                sortOrder: 'desc',
                columns: [[{
                    width: '200',
                    title: '经费类别名称',
                    field: 'text',
                    halign: 'center'
                }, {
                    title: '操作',
                    field: 'action',
                    halign: 'center',
                    width: '50',
                    formatter: function (value, row) {
                        var str = '';
                        if (row.level != '1') {
                            str += $.formatString('<img src="../js/easyui/themes/icons/pencil.png" title="编辑" onclick="editFun(\'{0}\',\'{1}\');"/>&nbsp;&nbsp;&nbsp;', row.id, row.level);
                            str += $.formatString('<img src="../js/easyui/themes/icons/no.png" title="删除" onclick="removeFun(\'{0}\');"/>', row.id);
                        }
                        return str;
                    }
                }]],
                toolbar: '#toolbar',
                onLoadSuccess: function (row, data) {
                    parent.$.messager.progress('close');
                    if (!data.success && data.total == -1) {
                        parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                            parent.location.replace('index.aspx');
                        });
                    }
                    if (data.length == 0) {
                        var body = $(this).data().datagrid.dc.body2;
                        body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                    }
                }
            });
            //非管理员隐藏操作列
            if (roleid != 6)
                $('#grid').datagrid('hideColumn', 'action');
        });
    </script>
</head>
<body class="easyui-layout">
    <div id="toolbar" style="display: none;padding:5px 10px 0;">
        <table>
            <tr>
                <%if(roleid == 6)
                  { %>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
                        onclick="addFun();">添加经费类别</a>
                </td>
                <td>
                    <div class="datagrid-btn-separator">
                    </div>
                </td>
                <%} %>
                <td>
                    <a onclick="redoFun();" href="javascript:void(0);" class="easyui-linkbutton" data-options="plain:true,iconCls:'ext-icon-resultset_next'">
                        展开</a><a onclick="undoFun();" href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="plain:true,iconCls:'ext-icon-resultset_previous'">折叠</a>
                </td>
                <td>
                    <div class="datagrid-btn-separator">
                    </div>
                </td>
                <td>
                    <a onclick="grid.treegrid('reload');" href="javascript:void(0);" class="easyui-linkbutton"
                        data-options="plain:true,iconCls:'ext-icon-arrow_refresh'">刷新</a>
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
