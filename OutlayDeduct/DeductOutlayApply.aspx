﻿<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>扣减经费申请</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--扣减经费申请——稽核；管理员将扣减的经费取消扣减并退回到处长重新审批--%>
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
        var deductGrid;
        var addDeduct = function () {
            var dialog = parent.$.modalDialog({
                title: '添加扣减经费申请',
                width: 360,
                height: 380,
                iconCls: 'ext-icon-note_add',
                href: 'OutlayDeduct/dialogop/AuditDudectOutlay_OP.aspx', //稽核扣减经费申请页面
                buttons: [{
                    text: '添加',
                    handler: function () {
                        parent.onFormSubmit(dialog, deductGrid);
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
                title: '编辑扣减经费申请',
                width: 360,
                height: 380,
                iconCls: 'icon-edit',
                href: 'OutlayDeduct/dialogop/AuditDudectOutlay_OP.aspx?id=' + id,
                buttons: [{
                    text: '保存',
                    handler: function () {
                        parent.onFormSubmit(dialog, deductGrid);
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
        //删除经费
        var removeFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要删除该项申请？', function (r) {
                if (r) {
                    $.post('../service/DeductOutlay.ashx/RemoveDeductOutlay', {
                        id: id
                    }, function (result) {
                        if (result.success) {
                            deductGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //送审申请
        var sendFun = function (id) {
            parent.$.messager.confirm('询问', '您确定要送审该项申请？', function (r) {
                if (r) {
                    $.post('../service/DeductOutlay.ashx/SendDeductOutlay', {
                        id: id
                    }, function (result) {
                        if (result.success) {
                            deductGrid.datagrid('reload');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        //查看详情，并打印
        var viewFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '详情',
                width: 350,
                height: 465,
                iconCls: 'ext-icon-page',
                href: 'OutlayDeduct/dialogop/ApproveDeductOutlay_OP.aspx?id=' + id,
                buttons: [
                //    {
                //    text: '打印',
                //    handler: function () {
                //        parent.printDetail();
                //    }
                //},
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
        //对已扣减的稽核扣减经费申请退回到处长审批
        var backHasDeductOutlayApplyToApprove = function (id) {
            parent.$.messager.confirm('退回审批', '您确认将该项经费扣减申请退回到处长审批？', function (r) {
                if (r) {
                    $.post('../service/DeductOutlay.ashx/BackHasDeductOutlayApplyToApprove',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            deductGrid.datagrid('reload');
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
            deductGrid.datagrid('load', $.serializeObject($('#deductForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#deductForm input').val('');
            deductGrid.datagrid('load', {});
        };
        //导出扣减经费明细到excel
        var exportDeductOutlay = function () {
            jsPostForm('../service/DeductOutlay.ashx/ExportDeductOutlayApplyDetail', $.serializeObject($('#deductForm')));
        };
        $(function () {
            /*datagrid生成*/
            deductGrid = $('#deductGrid').datagrid({
                title: '扣减经费管理',
                url: '../service/DeductOutlay.ashx/GetDeductOutlayDetail',
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
                frozenColumns: [[{
                    width: '80',
                    title: '月份',
                    field: 'outlaymonth',
                    halign: 'center',
                    align: 'center'
                }]],
                columns: [[{
                    width: '100',
                    title: '单位名称',
                    field: 'deptname',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '55',
                    title: '扣减编号',
                    field: 'deductno',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '60',
                    title: '经费类别',
                    field: 'cname',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '80',
                    title: '扣减额度',
                    field: 'deductoutlay',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '被扣减额度编号',
                    field: 'specialoutlayid',
                    halign: 'center',
                    align: 'center',
                    formatter: function (val) {
                        var str = val;
                        if (val == '0')
                            str = '无';
                        return str;
                    }
                }, {
                    width: '150',
                    title: '扣减原因',
                    field: 'deductreason',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '50',
                    title: '经办人',
                    field: 'applyuser',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '120',
                    title: '扣减时间',
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
                                return '<span style="color:#f00;">被退回</span>';
                                break;
                            case '0':
                                return '待送审';
                                break;
                            case '1':
                                return '待审批';
                                break;
                            case '2':
                                return '已扣减';
                                break;
                        }
                    }

                }, {
                    title: '操作',
                    field: 'action',
                    width: '90',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        if (row.status < 1 && roleid == 2) {
                            str += $.formatString('<a href="javascript:void(0);" title="编辑" onclick="editFun(\'{0}\');">编辑</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);"  title="删除" onclick="removeFun(\'{0}\');">删除</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);"  title="送审" onclick="sendFun(\'{0}\');">送审</a>', row.id);
                        }
                        if (row.status == 2) {
                            if (roleid == 6)//管理员退回审批
                                str += $.formatString('<a href="javascript:void(0);" onclick="backHasDeductOutlayApplyToApprove(\'{0}\');">退回审批</a>&nbsp;', row.id);
                            //已扣减，可查看打印
                            str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">详情</a>', row.id);
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
                    $(this).datagrid('tooltip', ['deductreason']);
                }
            });
            //设置分页属性
            var pager = $('#deductGrid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar" style="display: none;">
            <form id="deductForm" style="margin: 0;">
            <table>
                <tr>
                    <td width="60" align="right">
                        月份：
                    </td>
                    <td>
                        <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate" required
                            onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})" readonly="readonly" />
                    </td>
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
                    <td width="120" align="right">
                        被扣减额度编号：
                    </td>
                    <td>
                        <input style="width: 55px; height: 20px" type="text" class="combo" name="SpecialOutlayID" />
                    </td>
                    <td width="60" align="right">
                        状态：
                    </td>
                    <td>
                        <input name="status" style="width: 60px;" id="status" class="easyui-combobox" style="width: 100px;"
                            data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'-1',
			text: '被退回'
		},{
			id: '0',
			text: '待送审'
		},{
			id: '1',
			text: '待审批'
		},{
			id: '2',
			text: '已扣减'
		}]" />
                    </td>
                    <td>
                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                            onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">
                                重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportDeductOutlay();">导出</a>
                    </td>
                </tr>
            </table>
            </form>
            <%if(roleid == 2)
              { %>
            <div>
                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
                    onclick="addDeduct();">添加扣减经费申请</a>
            </div>
            <%} %>
        </div>
        <table id="deductGrid">
        </table>
    </div>
</body>
</html>
