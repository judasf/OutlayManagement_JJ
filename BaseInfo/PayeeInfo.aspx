<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>转账信息管理</title>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../css/bootstrap.min.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <%--管理员、出纳操作--%>
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
                title: '添加转账信息',
                width: 350,
                height: 240,
                iconCls: 'ext-icon-note_add',
                href: 'baseinfo/dialogop/PayeeInfo_op.aspx', //将对话框内容添加到父页面index
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
                title: '编辑转账信息',
                width: 350,
                height: 240,
                iconCls: 'icon-edit',
                href: 'baseinfo/dialogop/PayeeInfo_op.aspx?id=' + id,
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
                    $.post('../service/PaymentBaseInfo.ashx/RemovePayeeInfoByID', {
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
                title: '转账信息表',
                url: '../service/PaymentBaseInfo.ashx/GetPayeeInfo',
                striped: true,
                rownumbers: true,
                pagination: true,
                fit: true,
                border: false,
                singleSelect: true,
                pageSize:20,
                noheader: true,
                idField: 'payeeid',
                sortName: 'payeeid',
                sortOrder: 'asc',
                columns: [[{
                    field: 'payeename',
                    title: '收款单位',
                    width: 150,
                    halign: 'center',
                    align: 'center',
                    sortable: true
                }, {
                    field: 'accountnumber',
                    title: '银行账号',
                    width: 200,
                    halign: 'center',
                    align: 'center',
                    sortable: true
                }, {
                    field: 'bankname',
                    title: '开户行',
                    width: 300,
                    halign: 'center',
                    align: 'left'
                }, {
                    title: '操作',
                    field: 'action',
                    width: '50',
                    halign: 'center',
                    align: 'left',
                    formatter: function (value, row) {
                        var str = '';
                        if (roleid == 6 || roleid == 3)
                            str += $.formatString('<img src="../js/easyui/themes/icons/pencil.png" title="编辑" onclick="editFun(\'{0}\');"/>&nbsp;&nbsp;', row.payeeid);
                        str += $.formatString('<img src="../js/easyui/themes/icons/no.png" title="删除" onclick="removeFun(\'{0}\');"/>&nbsp;&nbsp;', row.payeeid);
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
            if (roleid != 6 && roleid != 3)
                $('#grid').datagrid('hideColumn', 'action');
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar">
            <form id="searchForm" style="margin: 0; padding: 5px 0;">
            <table>
                <tr>
                    <td width="70" align="right">
                        收款单位：
                    </td>
                    <td>
                        <input name="payeename" id="payeename" class="combo" style="width: 100px;" />
                    </td>
                    <td width="70" align="right">
                        银行账号：
                    </td>
                    <td>
                        <input style="width: 200px;" class="combo" name="accountnumber" id="accountnumber" />
                    </td>
                    <td colspan="6" align="center">
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                            onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">
                                重置</a>
                    </td>
                </tr>
            </table>
            </form>
            <%if(roleid == 6 || roleid == 3)
              { %>
            <div>
                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
                    onclick="addFun();">添加转账信息</a>
            </div>
            <%} %>
        </div>
        <table id="grid">
        </table>
    </div>
</body>
</html>
