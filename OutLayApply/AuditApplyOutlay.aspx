<%@ Page Language="C#" %>

<%--直接追加经费申请——稽核;管理员将生成的经费退回到处长重新审批--%>
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
    var roleid = '<%=roleid%>';
</script>
<%} %>
<script type="text/javascript">
    var grid;
    var addApply = function () {
        var dialog = parent.$.modalDialog({
            title: '添加经费申请',
            width: 680,
            height: 640,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/AuditApplyOutlay_OP.aspx', //稽核追加经费申请页面
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
            ],
            onBeforeClose: function () {
                //销毁ueditor
                parent.UE.getEditor('editor').destroy();
            }
        });
    };
    //批量添加经费
    var addBatchApply = function () {
        var dialog = parent.$.modalDialog({
            title: '批量添加经费申请',
            width: 670,
            height: 580,
            iconCls: 'ext-icon-application_form_add',
            href: 'OutLayApply/dialogop/AuditBatchApplyOutlay_OP.aspx', //稽核批量追加经费申请页面
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
            title: '编辑',
            width: 670,
            height: 580,
            iconCls: 'icon-edit',
            href: 'OutLayApply/dialogop/AuditApplyOutlay_OP.aspx?id=' + id,
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
                }
            ], onBeforeClose: function () {
                //销毁ueditor
                parent.UE.getEditor('editor').destroy();
            }
        });
    };
    //删除经费
    var removeFun = function (id) {
        parent.$.messager.confirm('询问', '您确定要删除该项申请？', function (r) {
            if (r) {
                $.post('../service/AuditApplyOutlayAllocate.ashx/RemoveAuditApplyOutlay', {
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
    //送审申请
    var sendFun = function (id) {
        parent.$.messager.confirm('询问', '您确定要送审该项申请？', function (r) {
            if (r) {
                $.post('../service/AuditApplyOutlayAllocate.ashx/SendAuditApplyOutlay', {
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
    //批量送审申请
    var approverAllAudit = function () {
        var rows = grid.datagrid('getSelections');
        var ids = [];
        if (rows.length == 0) {
            parent.$.messager.alert('提示', '请选择要送审的经费申请', 'error');
            return false;
        }
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            ids.push(row.id);
        }
        parent.$.messager.confirm("确认提交", "确认进行批量送审？", function (r) {
            if (r) {
                $.post('../service/AuditApplyOutlayAllocate.ashx/SendAuditApplyOutlay',
                { id: ids.join(',') },
                function (result) {
                    if (result.success) {
                        grid.datagrid('reload');
                        grid.datagrid('clearSelections');
                        parent.$.messager.alert('提示', result.msg, 'info');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        })
    };
    //判断批量送审按钮的显示状态
    var showOrHide = function () {
        //获取status的值
        var st = $('#status').combobox('getValue');
        //稽核待送审和被退回状态下显示批量送审按钮
        if (st&&(st == 0||st == -1))
            $('#toolBtn').show();
        else
            $('#toolBtn').hide();
    };
    //查看详情，并打印
    var viewFun = function (id) {
        var dialog = parent.$.modalDialog({
            title: '详情',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-page',
            href: 'OutLayApply/dialogop/ViewAuditApplyOutlay_OP.aspx?id=' + id,
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
    //对已生成的稽核直接追加经费退回到处长审批
    var backHasCreateAuditApplyOutlayToApprove = function (id) {
        parent.$.messager.confirm('退回审批', '您确认将该项申请退回到处长审批？', function (r) {
            if (r) {
                $.post('../service/SpecialOutlayAllocate.ashx/BackHasCreateAuditApplyOutlayToApprove',
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
        grid.datagrid('clearSelections');
        showOrHide();
    };
    //重置查询
    var resetGrid = function () {
        $('#allocateForm input').val('');
        grid.datagrid('load', {});
        grid.datagrid('clearSelections');
    };
    //导出直接拨付经费明细到excel
    var exportAuditApplyOutlay = function () {
        jsPostForm('../service/AuditApplyOutlayAllocate.ashx/ExportAuditApplyOutlayDetail', $.serializeObject($('#allocateForm')));
    };
    $(function () {
        /*datagrid生成*/
        grid = $('#grid').datagrid({
            title: '追加经费申请明细',
            url: '../service/AuditApplyOutlayAllocate.ashx/GetAuditApplyOutlayDetail',
            striped: true,
            fit: true,
            rownumbers: true,
            pagination: true,
            showFooter: true,
            noheader: true,
            border: false,
            pageSize: 20,
            singleSelect: false,
            idField: 'id',
            sortName: 'id',
            sortOrder: 'desc',
            frozenColumns: [[{
                field: 'ck',
                checkbox: true
            },
            {
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
                title: '额度编号',
                field: 'outlayid',
                halign: 'center',
                align: 'center'

            }, {
                width: '220',
                title: '标题',
                field: 'applytitle',
                halign: 'center',
                align: 'center'

            }, {
                width: '100',
                title: '可用额度',
                field: 'applyoutlay',
                halign: 'center',
                align: 'center'
            }, {
                width: '80',
                title: '经费类别',
                field: 'cname',
                halign: 'center',
                align: 'center'
            }, {
                width: '110',
                title: '用途',
                field: 'usefor',
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
                title: '申请时间',
                field: 'applytime',
                halign: 'center',
                align: 'center',
                formatter: function (value) {
                    if (value)
                        return value.substr(0, value.indexOf(' ')).replace(/\//g, '-');
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
                            return '已生成';
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
                            str += $.formatString('<a href="javascript:void(0);" onclick="backHasCreateAuditApplyOutlayToApprove(\'{0}\');">退回审批</a>&nbsp;', row.id);
                        //已生成可用额度，可查看打印
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
                $(this).datagrid('tooltip', ['applytitle', 'cname', 'usefor']);
                showOrHide();
            }
        });
        //设置分页属性
        var pager = $('#grid').datagrid('getPager');
        pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
    });
</script>
<div id="toolbar" style="display: none;">
    <form id="allocateForm" style="margin: 0;">
        <table>
            <tr>
                <td width="70" align="right">单位名称：
                </td>
                <td align="left">
                    <input name="deptId" id="deptId" style="width: 100px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 100,
                    panelHeight: '150',
                    editable:false,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                </td>
                <td width="60" align="right">月份：
                </td>
                <td>
                    <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate" required
                        onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})" readonly="readonly" />
                </td>
                <td width="70" align="right">额度编号：
                </td>
                <td>
                    <input style="width: 55px; height: 20px" type="text" class="combo" name="outlayid" />
                </td>
                <td width="60" align="right">经费类别：
                </td>
                <td align="left">
                    <input name="outlayCategory" id="outlayCategory" class="easyui-combotree" data-options=" valueField: 'id',
            textField: 'text',
            editable: false,
            lines: true,
            panelHeight: 'auto',
            url: '../service/category.ashx/GetCategory',
            onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            }" />
                </td>
                <td width="60" align="right">状态：
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
			text: '已生成'
		}]" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                onclick="exportAuditApplyOutlay();">导出</a>
                </td>
            </tr>
        </table>
    </form>
    <%if (roleid == 2)
      { %>
    <div>
        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
            onclick="addApply();">添加经费申请</a>
        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-application_form_add',plain:true"
            onclick="addBatchApply();">批量添加经费申请</a>
        <a id="toolBtn" href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-key_go',plain:true"
            onclick="approverAllAudit();">批量送审</a>
    </div>
    </div>
    <%} %>
</div>
<table id="grid">
</table>
