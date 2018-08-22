<%@ Page Language="C#" AutoEventWireup="true" CodeFile="UserInfo.aspx.cs" Inherits="BaseInfo_UserInfo" %>

<!DOCTYPE html>
<html>
<head>
    <title>用户管理</title>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../css/bootstrap.min.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <%--管理员操作--%>
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
        var grid;
        var addFun = function () {
            var dialog = parent.$.modalDialog({
                title: '添加用户',
                width: 400,
                height: 300,
                iconCls: 'ext-icon-note_add',
                href: 'baseinfo/dialogop/UserInfo_op.aspx', //将对话框内容添加到父页面index
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
                title: '编辑用户',
                width: 400,
                height: 300,
                iconCls: 'icon-edit',
                href: 'baseinfo/dialogop/UserInfo_op.aspx?uid=' + id,
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
                    $.post('../service/UserInfo.ashx/RemoveUserInfoByID', {
                        UID: id
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
        var resetPwdFun = function (id) {
            parent.$.messager.confirm('询问', '恢复该用户密码？', function (r) {
                if (r) {
                    $.post('../service/UserInfo.ashx/ResetPwdByID', {
                        UID: id
                    }, function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                            parent.$.messager.show({ title: '成功', msg: '密码恢复成功！' });
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        var setScopeFun = function (id, roleName, scopeDepts) {
            var dialog = parent.$.modalDialog({
                title: '设置审批范围',
                width: 500,
                height: 380,
                iconCls: 'ext-icon-group',
                href: 'baseinfo/dialogop/UserInfo_ScopeDepts_OP.aspx?UID=' + id + '&roleName=' + roleName + '&scopeDepts=' + scopeDepts,
                buttons: [{
                    text: '保存',
                    handler: function () {
                        parent.onFormSubmit(dialog, grid);
                    }
                }]
            });
        };
        //锁定用户
        var lockFun = function (id) {
            parent.$.messager.confirm('询问', '是否锁定该用户？', function (r) {
                if (r) {
                    $.post('../service/UserInfo.ashx/LockUserByID', {
                        UID: id
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
        //锁定全部一般用户
        var lockAllFun = function () {
            parent.$.messager.confirm('询问', '是否锁定全部一般用户？', function (r) {
                if (r) {
                    $.post('../service/UserInfo.ashx/LockAllUser', function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //解锁用户
        var unlockFun = function (id) {
            parent.$.messager.confirm('询问', '是否解锁该用户？', function (r) {
                if (r) {
                    $.post('../service/UserInfo.ashx/UnLockUserByID', {
                        UID: id
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
        //解锁全部一般用户
        var unlockAllFun = function () {
            parent.$.messager.confirm('询问', '是否解锁该全部一般用户？', function (r) {
                if (r) {
                    $.post('../service/UserInfo.ashx/UnLockAllUser',function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //切换用户
        var changeUserFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要切换至此用户进行操作？', function (r) {
                if (r) {
                    $.post('../service/CommonDB.ashx/ChangeUserByID', {
                        UID: id
                    }, function (result) {
                        if (result.success) {
                            parent.location.replace('/index.aspx')
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //导用户信息excel
        var exportUserinfo = function () {
            jsPostForm('../service/UserInfo.ashx/ExportUserInfo', $.serializeObject($('#searchForm')));
        };
        $(function () {
            grid = $('#grid').datagrid({
                title: '用户管理',
                url: '../service/UserInfo.ashx/GetUserInfo',
                striped: true,
                rownumbers: true,
                pagination: true,
                pageSize:20,
                singleSelect: true,
                noheader:true,
                idField: 'uid',
                sortName: 'uid',
                sortOrder: 'desc',
                columns: [[{
                    width: '100',
                    title: '用户编号',
                    field: 'usernum',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '角色名称',
                    field: 'rolename',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '100',
                    title: '用户名',
                    field: 'username',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '100',
                    title: '单位名称',
                    field: 'deptname',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '80',
                    title: '状态',
                    field: 'userstatus',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        if (value == 0)
                            return '正常';
                        else
                            return '锁定';
                    }
                }, {
                    title: '操作',
                    field: 'action',
                    width: '120',
                    halign: 'center',
                    align: 'left',
                    formatter: function (value, row) {
                        var str = '';

                        str += $.formatString('<img src="../js/easyui/themes/icons/pencil.png" title="编辑" onclick="editFun(\'{0}\');"/>&nbsp;&nbsp;', row.uid);
                        str += $.formatString('<img src="../js/easyui/themes/icons/no.png" title="删除" onclick="removeFun(\'{0}\');"/>&nbsp;&nbsp;', row.uid);
                        str += $.formatString('<img src="../css/images/ext_icons/lock/lock_edit.png" title="重置密码" onclick="resetPwdFun(\'{0}\');"/>&nbsp;&nbsp;', row.uid);
                        if (row.roleid != 1 && row.roleid != 8 && row.roleid != 9)
                            str += $.formatString('<img src="../css/images/ext_icons/group/group.png" title="审批范围" onclick="setScopeFun(\'{0}\',\'{1}\',\'{2}\');"/>&nbsp;&nbsp;', row.uid, row.rolename, row.scopedepts);
                        if ((row.roleid == 1||row.roleid == 8||row.roleid == 9) && row.userstatus==0)
                            str += $.formatString('<img src="../css/images/lock.png" width="16" title="锁定" onclick="lockFun(\'{0}\');"/>&nbsp;&nbsp;', row.uid);
                        if ((row.roleid == 1 || row.roleid == 8 || row.roleid == 9) && row.userstatus == 1)
                            str += $.formatString('<img src="../css/images/unlock.png" width="16" title="解锁" onclick="unlockFun(\'{0}\');"/>&nbsp;&nbsp;', row.uid);
                        str += $.formatString('<img src="../css/images/ext_icons/user/user_go.png" title="切换用户" onclick="changeUserFun(\'{0}\');"/>&nbsp;&nbsp;', row.uid);
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
            if(roleid!=6)
                $('#grid').datagrid('hideColumn','action');
        });
    </script>
</head>
<body class="easyui-layout">
    <div id="toolbar">
        <table >
            <tr>
                <td>
                    <form id="searchForm" style="margin:0;">
                    <table>
                        <tr>
                            <td>
                                用户编号：
                            </td>
                            <td>
                                <input name="userNum" class="combo" style="width: 80px;" />
                            </td>
                            <td>
                                用户名：
                            </td>
                            <td>
                                <input name="userName" class="combo" style="width: 80px;" />
                            </td>
                            <td>
                                角色名称：
                            </td>
                            <td>
                                <input name="roleId" style="width: 100px;" class="easyui-combobox" width="100" data-options="valueField:'id',textField:'text',editable:false, panelWidth: 100,panelHeight:'auto',url:'../service/RoleInfo.ashx/GetRoleInfoCombobox'" />
                            </td>
                            <td>
                                单位名称：
                            </td>
                            <td>
                                <input name="deptId" style="width: 100px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 100,
                    panelHeight: '180',
                    mode: 'remote',
                    url: '../service/Department.ashx/GetDepartmentCombobox'" />
                            </td>
                            <td>
                                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-search',plain:true"
                                    onclick="grid.datagrid('load',$.serializeObject($('#searchForm')));">查询</a><a href="javascript:void(0);"
                                        class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                                        onclick="$('#searchForm input').val('');grid.datagrid('load',{});">重置</a>
                            </td>
                             <td>
                                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportUserinfo();">导出</a>
                            </td>
                        </tr>
                    </table>
                    </form>
                </td>
            </tr>
            <%if(roleid == 6)
              { %>
            <tr>
                <td>
                    <table>
                        <tr>
                            <td>
                                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
                                    onclick="addFun();">添加新用户</a>
                                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'icon-lock',plain:true"
                                    onclick="lockAllFun();">锁定全部一般用户</a>
                                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'icon-unlock',plain:true"
                                    onclick="unlockAllFun();">解锁全部一般用户</a>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <%} %>
        </table>
    </div>
    <div data-options="region:'center',fit:true,border:false">
        <table id="grid" data-options="fit:true,border:false">
        </table>
    </div>
</body>
</html>
