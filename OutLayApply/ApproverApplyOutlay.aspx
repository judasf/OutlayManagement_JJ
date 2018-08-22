<%@ Page Language="C#" %>

<%--基层用户追加经费审批——处长--%>
<%if (!Request.IsAuthenticated)
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
      int roleid = ud.LoginUser.RoleId;
%>
<script type="text/javascript">
    var roleid=<%=roleid%>
</script>
<%} %>
<script type="text/javascript">
    var approverApplyOutlayGrid;
    //审批经费
    var approverOutlay = function (id) {
        var dialog = parent.$.modalDialog({
            title: '经费审批',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/ApproverApplyOutlay_OP.aspx?id=' + id, //将对话框内容添加到父页面index
            buttons: [{
                text: '通过审批',
                handler: function () {
                    parent.ApproverApplyOutlat(dialog, approverApplyOutlayGrid);
                }
            },
                {
                    text: '退回申请',
                    handler: function () {
                        parent.BackApply(dialog, approverApplyOutlayGrid);
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
    var searchApproverGrid = function () {
        approverApplyOutlayGrid.datagrid('load', $.serializeObject($('#approverOutlayForm')));
    };
    //重置查询
    var resetApproverGrid = function () {
        $('#approverOutlayForm input').val('');
        approverApplyOutlayGrid.datagrid('load', {});
    };
    //导出申请追加经费明细到excel
    var exportApproveApplyOutlay = function () {
        jsPostForm('../service/SpecialOutlayAllocate.ashx/ExportApproveApplyOutlayDetail', $.serializeObject($('#approverOutlayForm')));
    };
    $(function () {
        /*datagrid生成*/
        approverApplyOutlayGrid = $('#approverApplyOutlayGrid').datagrid({
            title: '追加经费申请明细',
            url: '../service/SpecialOutlayAllocate.ashx/GetApplyOutlayDetail',
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
                field: 'specialoutlayid',
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
                width: '100',
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
                        case '1':
                            return '待审批';
                            break;
                        case '2':
                            return '<span style="color:#f00;">被退回</span>';
                            break;
                        case '3':
                            return '待确认';
                            break;
                        case '4':
                            return '已生成';
                            break;
                    }
                }
            }, {
                title: '操作',
                field: 'action',
                width: '30',
                halign: 'center',
                align: 'center',
                formatter: function (value, row) {
                    var str = '';
                    if (row.status < 3 && row.status > 0 && roleid == 4) {
                        str += $.formatString('<a href="javascript:void(0);" title="审批" onclick="approverOutlay(\'{0}\');">审批</a>', row.id);
                    }
                    return str;
                }
            }]],
            rowStyler: function (index, row) {
                if (row.status == 1 && roleid==4)
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
            }
        });
        //设置分页属性
        var pager = $('#approverApplyOutlayGrid').datagrid('getPager');
        pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
    });
</script>
<div id="toolbar">
    <form id="approverOutlayForm" style="margin: 0;">
        <table>
            <tr>
                <td width="60" align="right">单位名称：
                </td>
                <td>
                    <input name="deptId" id="deptId" style="width: 100px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 100,
                    panelHeight: '150',
                    editable:false,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                </td>
                <td width="50" align="right">月份：
                </td>
                <td>
                    <input style="width: 80px;" name="outlayMonth" id="outlayMonth" class="Wdate" required
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
                <td width="50" align="right">状态：
                </td>
                <td>
                    <input name="status" style="width: 60px;" id="status" class="easyui-combobox" style="width: 100px;"
                        data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'1',
			text: '待审批'
		},{
			id: '2',
			text: '被退回'
		},{
			id: '3',
			text: '待确认'
		},{
			id: '4',
			text: '已生成'
		}]" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchApproverGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetApproverGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                onclick="exportApproveApplyOutlay();">导出</a>
                </td>
            </tr>
        </table>
    </form>
</div>
<table id="approverApplyOutlayGrid">
</table>
