<%@ Page Language="C#" AutoEventWireup="true" CodeFile="CreatePublicOutlay.aspx.cs"
    Inherits="OutLayApply_CreatePublicOutlay" %>

<!DOCTYPE html>
<html>
<head>
    <title>定额公用经费生成</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <%--<link href="../css/bootstrap.min.css" rel="stylesheet" type="text/css" />--%>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--定额公用经费生成——稽核;管理员将已下发的定额公用经费退回到处长审批--%>
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
        //生成全部定额公用经费，稽核员操作
        var createOutlay = function () {
            if ($('form').form('validate')) {
                $.post('../service/PublicOutlayAllocate.ashx/CreateAllPublicOutlay',
                { outlayMonth: $('#outlayMonth').val() },
                function (result) {
                    if (result.success) {
                        grid.datagrid("load");
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }

        };
        //按单位生成
        var createOutlayByDept = function () {
            if ($('form').form('validate')) {
                if (!$('#deptId').combobox('getValue')) {
                    parent.$.messager.alert('提示', '请选择要生成经费的单位', 'error');
                    return;
                }
                $.post('../service/PublicOutlayAllocate.ashx/CreateAllPublicOutlay',
                { deptId: $('#deptId').combobox('getValue'), outlayMonth: $('#outlayMonth').val() },
                 function (result) {
                     if (result.success) {
                         grid.datagrid("load");
                     } else {
                         parent.$.messager.alert('提示', result.msg, 'error');
                     }
                 }, 'json');
            }

        };
        //送审经费
        var auditFun = function (id) {
            $.post('../service/PublicOutlayAllocate.ashx/AuditPublicOutlay',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
        };
        //删除经费
        var removeFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要删除此记录？', function (r) {
                if (r) {
                    $.post('../service/PublicOutlayAllocate.ashx/RemovePublicOutlay', {
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
        //批量送审
        var auditAll = function () {
            var rows = grid.datagrid('getSelections');
            var ids = [];
            if (rows.length == 0) {
                parent.$.messager.alert('提示', '请选择要送审的经费', 'error');
                return false;
            }
            for (var i = 0; i < rows.length; i++) {
                var row = rows[i];
                ids.push(row.id);
            }
            $.post('../service/PublicOutlayAllocate.ashx/AuditPublicOutlay',
                    { id: ids.join(',') },
                    function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                            grid.datagrid('clearSelections');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');

        };
        //判断操作列和toolbar的显示状态
        var showOrHide = function () {
            //获取status的值
            var st = $('#status').combobox('getValue');
            //稽核，送审后
            if (st > 0) {
                grid.datagrid('hideColumn', 'action');
                $('#auditBtn').hide();
            }
            //稽核，送审前
            if (st <= 0) {
                grid.datagrid('showColumn', 'action');
                $('#auditBtn').show();
            }
        };
        //管理员操作 begin
        //对已生成的稽核直接追加经费退回到处长审批
        var backHasCreatePublicOutlayToApprove = function (id) {
            parent.$.messager.confirm('退回审批', '您确认将该项申请退回到处长审批？', function (r) {
                if (r) {
                    $.post('../service/PublicOutlayAllocate.ashx/BackHasCreatePublicOutlayToApprove',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            grid.datagrid('reload');
                            parent.$.messager.alert('成功', result.msg, 'info');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //管理员操作 end
        //查询功能
        var searchGrid = function () {
            grid.datagrid('load', $.serializeObject($('#allocateForm')));
            showOrHide();
        };
        //重置查询
        var resetGrid = function () {
            $('#allocateForm input').val('');
            grid.datagrid('load', {});
            grid.datagrid('showColumn', 'action');
            $('#auditBtn').show();
        };
        //导出定额公用经费明细到excel
        var exportPublicOutlay = function () {
            jsPostForm('../service/PublicOutlayAllocate.ashx/ExportAuditPublicOutlayDetail', $.serializeObject($('#allocateForm')));
        };
        $(function () {
            /*datagrid生成*/
            grid = $('#grid').datagrid({
                title: '定额公用经费明细',
                url: '../service/PublicOutlayAllocate.ashx/GetPublicOutlayDetail',
                striped: true,
                rownumbers: true,
                pagination: true,
                showFooter: true,
                pageSize: 20,
                singleSelect: false,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                frozenColumns: [[{
                    field: 'ck',
                    checkbox: true
                }]],
                columns: [[{
                    width: '100',
                    title: '月份',
                    field: 'outlaymonth',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '单位名称',
                    field: 'deptname',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '130',
                    title: '经费标准(元/月/每人)',
                    field: 'leveloutlay',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '60',
                    title: '单位人数',
                    field: 'peoplenum',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '100',
                    title: '当月经费(元)',
                    field: 'monthoutlay',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '120',
                    title: '生成时间',
                    field: 'audittime',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        if (value)
                            return value.substr(0,value.indexOf(' ')).replace(/\//g, '-');
                        else
                            return '';
                    }

                }, {
                    width: '120',
                    title: '下发时间',
                    field: 'approvetime',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        if (value)
                            return value.substr(0,value.indexOf(' ')).replace(/\//g, '-');
                    }
                }, {
                    width: '60',
                    title: '状态',
                    field: 'status',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row, index) {
                        switch (value) {
                            case '-1':
                                return '被退回';
                                break;
                            case '0':
                                return '待送审'
                                break;
                            case '1':
                                return '待审批'
                                break;
                            case '2':
                                return '已下发'
                                break;
                        }
                    }

                }, {
                    title: '操作',
                    field: 'action',
                    width: '60',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        if (row.status < 1 && roleid == 2) {//稽核操作,带送审和被退回的
                            str += $.formatString('<a href="javascript:void(0);"  title="送审" onclick="auditFun(\'{0}\');">送审</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);" title="删除" onclick="removeFun(\'{0}\');">删除</a>', row.id);
                        }
                        //管理员退回已下发的定额公用经费到处长重新审批
                        if (row.status == 2 && roleid == 6) {
                            str += $.formatString('<a href="javascript:void(0);"  title="退回审批" onclick="backHasCreatePublicOutlayToApprove(\'{0}\');">退回审批</a>', row.id);
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
                }
            });
            //设置分页属性
            var pager = $('#grid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
            //管理员隐藏复选框
            if (roleid == 6)
                $('#grid').datagrid('hideColumn', 'ck');
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar">
            <form id="allocateForm" style="margin: 0;">
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
                    panelHeight: '150',
                    editable:false,
                    url: '../service/DeptOutlay.ashx/GetDeptLevelCombobox'" />
                    </td>
                    <td width="40" align="right">
                        月份：
                    </td>
                    <td>
                        <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate easyui-validatebox"
                            required onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})" readonly="readonly" />
                    </td>
                    <td width="40" align="right">
                        状态：
                    </td>
                    <td>
                        <input name="status" id="status" style="width: 60px;" data-options="panelHeight:'auto',
                        editable:false,
                        valueField:'value',
                        textField:'label',
                        data: [{
			                        label: '被退回',
			                        value: '-1'
		                        },{
			                        label: '待送审',
			                        value: '0'
		                        },{
			                        label: '待审批',
			                        value: '1'
		                        },{
			                        label: '已下发',
			                        value: '2'
		                        }
        ]" class="easyui-combobox" />
                    </td>
                    <td>
                        <%if(roleid == 2)
                          { %>
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-folder_go',plain:true"
                            onclick="createOutlay();">全部生成</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-folder_go',plain:true" onclick="createOutlayByDept();">
                                按单位生成</a>
                        <%} %>
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                            onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">
                                重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportPublicOutlay();">导出</a>
                    </td>
                </tr>
            </table>
            </form>
            <%if(roleid == 2)
              { %>
            <div id="auditBtn">
                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-key_go',plain:true"
                    onclick="auditAll();">批量送审</a>
            </div>
            <%} %>
        </div>
        <table id="grid" data-options="fit:true,border:true">
        </table>
    </div>
</body>
</html>
