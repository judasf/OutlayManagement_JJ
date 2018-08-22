<%@ Page Language="C#" AutoEventWireup="true" CodeFile="ExpenseSubject.aspx.cs" Inherits="BaseInfo_OutlayLevel" %>

<!DOCTYPE html>
<html>
<head>
    <title>支出科目管理</title>
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
                title: '添加支出科目',
                width: 400,
                height: 220,
                iconCls: 'ext-icon-note_add',
                href: 'baseinfo/dialogop/ExpenseSubject_OP.aspx', //将对话框内容添加到父页面
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
                title: '编辑支出科目',
                width: 400,
                height: 220,
                iconCls: 'icon-edit',
                href: 'baseinfo/dialogop/ExpenseSubject_OP.aspx?ID=' + id,
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
                    $.post('../service/ExpenseSubject.ashx/RemoveExpenseSubjectByID', {
                        id: id
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
        //导出支出科目信息excel
        var exportExpenseSubject = function () {
            jsPostForm('../service/ExpenseSubject.ashx/ExportExpenseSubject');
        };
        $(function () {
            grid = $('#grid').datagrid({
                title: '支出科目表',
                url: '../service/ExpenseSubject.ashx/GetExpenseSubjectInfo',
                striped: true,
                rownumbers: true,
                pagination: true,
                singleSelect: true,
                pageSize:20,
                noheader: true,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'asc',
                columns: [[{
                    width: '100',
                    title: '支出科目编号',
                    field: 'subjectnum',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '150',
                    title: '支出科目名称',
                    field: 'subjectname',
                    sortable: true,
                    halign: 'center',
                    align: 'center'

                }, {
                    title: '操作',
                    field: 'action',
                    width: '50',
                    halign: 'center',
                    formatter: function (value, row) {
                        var str = '';

                        str += $.formatString('<img src="../js/easyui/themes/icons/pencil.png" title="编辑" onclick="editFun(\'{0}\');"/>&nbsp;&nbsp;', row.id);
                        str += $.formatString('<img src="../js/easyui/themes/icons/no.png" title="删除" onclick="removeFun(\'{0}\');"/>', row.id);
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
    <div id="toolbar" style="display: none;padding:5px 10px 0;">
        <table>
            <tr>
                <%if(roleid == 6)
                  { %>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
                        onclick="addFun();">添加支出科目</a>
                </td>
                <td>
                    <div class="datagrid-btn-separator">
                    </div>
                </td>
                <%} %>
                <td>
                    <input id="searchBox" class="easyui-searchbox" style="width: 150px" data-options="searcher:function(value,name){grid.datagrid('load',{where:'subjectName like \'%'+encodeURIComponent(value)+'%\''});},prompt:'请输入支出科目名称'"></input>
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                        onclick="$('#searchBox').searchbox('setValue','');grid.datagrid('load',{});">清空查询</a>
                </td>
                 <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                        onclick="exportExpenseSubject();">导出</a>
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
