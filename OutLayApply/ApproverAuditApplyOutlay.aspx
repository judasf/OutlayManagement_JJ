<%@ Page Language="C#" %>

<%--对稽核申请追加经费进行审批并生成经费——处长--%>
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
    //审批经费确认
    var approverAuditApply = function (id) {
        var dialog = parent.$.modalDialog({
            title: '追加经费审批',
            width: 600,
            height: 450,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/ApproveAuditApplyOutlay_OP.aspx?id=' + id,
            buttons: [{
                text: '通过审批并生成',
                handler: function () {
                    parent.ApproveAuditApplyOutlay(dialog, grid);
                }
            },
            {
                text: '退回',
                handler: function () {
                    parent.BackAuditApplyOutlay(dialog, grid);
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
    //批量审批下发
    var approverAllAudit = function () {
        var rows = grid.datagrid('getSelections');
        var ids = [];
        if (rows.length == 0) {
            parent.$.messager.alert('提示', '请选择要审批的经费', 'error');
            return false;
        }
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            ids.push(row.id);
        }
        parent.$.messager.confirm("确认提交", "确认进行批量审批？", function (r) {
            if (r) {
                $.post('../service/AuditApplyOutlayAllocate.ashx/ApproveAllAuditApplyOutlay',
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
    //判断操作列和toolbar的显示状态
    var showOrHide = function () {
        //获取status的值
        var st = $('#status').combobox('getValue');
        //处长，审批下发后
        if (st == 2) {
            $('#toolBtn').hide();
        }
        //处长，审批前
        if (st == 1) {
            $('#toolBtn').show();
        }
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
        $('#toolbar').show();
        grid.datagrid('clearSelections');
    };
    //导出直接拨付经费明细到excel
    var exportApproveAuditApplyOutlay = function () {
        jsPostForm('../service/AuditApplyOutlayAllocate.ashx/ExportApproveAuditApplyOutlayDetail', $.serializeObject($('#allocateForm')));
    };
    $(function () {
        /*datagrid生成*/
        grid = $('#grid').datagrid({
            title: '稽核追加经费申请明细',
            url: '../service/AuditApplyOutlayAllocate.ashx/GetAuditApplyOutlayDetail',
            striped: true,
            rownumbers: true,
            fit: true,
            border: false,
            noheader: true,
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
                width: '80',
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
                width: '50',
                halign: 'center',
                align: 'center',
                formatter: function (value, row) {
                    var str = '';
                    if (row.status == 1 && roleid == 4) {
                        str += $.formatString('<a href="javascript:void(0);" title="审批" onclick="approverAuditApply(\'{0}\');">审批</a>', row.id);
                    }
                    if (row.status == 2)//已生成可用额度，可查看打印
                        str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">详情</a>', row.id);
                    return str;
                }
            }]],
            toolbar: '#tools',
            rowStyler: function (index, row) {
                if (row.status == 1 && roleid == 4)
                    return 'color:#f00;font-weight:700;';
            },
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
                //表格提示
                $(this).datagrid('tooltip', ['applytitle', 'cname', 'usefor']);
            }
        });
        //设置分页属性
        var pager = $('#grid').datagrid('getPager');
        pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
    });
</script>
<div id="tools">
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
                <td width="40" align="right">月份：
                </td>
                <td align="left">
                    <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate" required
                        onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})" readonly="readonly" />
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
                <td width="40" align="right">状态：
                </td>
                <td align="left">
                    <input name="status" id="status" style="width: 60px;" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value', textField:'label',
                        data: [{
			                        label: '待审批',
			                        value: '1'
		                        },{
			                        label: '已生成',
			                        value: '2'
		                        }]" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                onclick="exportApproveAuditApplyOutlay();">导出</a>
                </td>
            </tr>
        </table>
    </form>
    <% if (roleid == 4)
        { %>
    <div id="toolBtn">
        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-key_go',plain:true"
            onclick="approverAllAudit();">批量审批下发</a>
    </div>
    <%} %>
</div>
<table id="grid">
</table>
