<%@ Page Language="C#" %>

<%--对处长审批通过申请追加经费进行确认——稽核;管理员将生成的经费退回到处长重新审批--%>
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
    var auditApproverGrid;
    //审批经费确认
    var auditApprover = function (id) {
        var dialog = parent.$.modalDialog({
            title: '追加经费确认',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/AuditApproveOutlay_OP.aspx?id=' + id, //将对话框内容添加到父页面index
            buttons: [{
                text: '经费确认并生成',
                handler: function () {
                    parent.AuditApproveOutlat(dialog, auditApproverGrid);
                }
            },
                {
                    text: '退回审批',
                    handler: function () {
                        parent.BackApprover(dialog, auditApproverGrid);
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
    //查看详情，并打印
    var viewFun = function (id) {
        var dialog = parent.$.modalDialog({
            title: '详情',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-page',
            href: 'OutLayApply/dialogop/ViewApplyOutlay_OP.aspx?id=' + id,
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
    //对已生成的申请追加经费退回到处长审批
    var backHasCreateAppendOutlayToApprove = function (id) {
        parent.$.messager.confirm('退回审批', '您确认将该项申请退回到处长审批？', function (r) {
            if (r) {
                $.post('../service/SpecialOutlayAllocate.ashx/BackHasCreateAppendOutlayToApprove',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            auditApproverGrid.datagrid('reload');
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
    var searchAuditApproverGrid = function () {
        auditApproverGrid.datagrid('load', $.serializeObject($('#auditApproverForm')));
    };
    //重置查询
    var resetAuditApproverGrid = function () {
        $('#auditApproverForm input').val('');
        auditApproverGrid.datagrid('load', {});
    };
    //导出申请追加经费明细excel
    var exportAuditApproveOutlay = function () {
        jsPostForm('../service/SpecialOutlayAllocate.ashx/ExportAuditApproveOutlayDetail', $.serializeObject($('#auditApproverForm')));
    };
    $(function () {
        //加载经费类别树
        $('#outlayCategory').combotree({
            valueField: 'id',
            textField: 'text',
            editable: false,
            lines: true,
            panelHeight: 'auto',
            url: '../service/category.ashx/GetCategory',
            onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            }
        });
        /*datagrid生成*/
        auditApproverGrid = $('#auditApproverGrid').datagrid({
            title: '追加经费申请明细',
            url: '../service/SpecialOutlayAllocate.ashx/GetApplyOutlayDetail',
            striped: true,
            fit: true,
            rownumbers: true,
            pagination: true,
            showFooter: true,
            noheader: true,
            border: false,
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
                            return '待送审';
                            break;
                        case '1':
                            return '待审批';
                            break;
                        case '2':
                            return '待审批'; //稽核退回给处长
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
                width: '90',
                halign: 'center',
                align: 'center',
                formatter: function (value, row) {
                    var str = '';
                    if (row.status == 3 && roleid == 2) {
                        str += $.formatString('<a href="javascript:void(0);" title="确认" onclick="auditApprover(\'{0}\');">确认</a>', row.id);
                    }
                    if (row.status == 4) {
                        if (roleid == 6)//管理员退回审批
                            str += $.formatString('<a href="javascript:void(0);" onclick="backHasCreateAppendOutlayToApprove(\'{0}\');">退回审批</a>&nbsp;', row.id);
                        //已生成可用额度，可查看打印
                        str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">详情</a>', row.id);
                    }
                    return str;
                }
            }]],
            rowStyler: function (index, row) {
                if (row.status == 3 && roleid == 2)
                    return 'color:#f00;font-weight:700;';
            },
            toolbar: '#tools',
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
        var pager = $('#auditApproverGrid').datagrid('getPager');
        pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
    });
</script>
<div id="tools">
    <form id="auditApproverForm" style="margin: 0;">
    <table>
        <tr>
            <td width="70" align="right">
                单位名称：
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
            <td width="40" align="right">
                月份：
            </td>
            <td align="left">
                <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate" required
                    onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})" readonly="readonly" />
            </td>
            <td width="60" align="right">
                经费类别：
            </td>
            <td align="left">
                <input name="outlayCategory" id="outlayCategory" />
            </td>
            <td width="40" align="right">
                状态：
            </td>
            <td align="left">
                <input name="status" id="status" style="width: 60px;" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'id', textField:'text',
                        data: [
                        <%if(roleid==6){ %>
                        {id:'-1',text: '被退回'},{id: '0',text: '待送审'},{id: '1',text: '待审批'},
                        <%} %>
                        {text: '待确认',id: '3'},{text: '已生成',id: '4'}
                        ]" />
            </td>
            
            <td>
                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                    onclick="searchAuditApproverGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                        data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetAuditApproverGrid();">
                        重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                            onclick="exportAuditApproveOutlay();">导出</a>
            </td>
        </tr>
    </table>
    </form>
</div>
<table id="auditApproverGrid">
</table>
