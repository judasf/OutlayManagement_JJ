<%@ Page Language="C#" %>

<%--追加经费申请——基层用户--%>
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
    var userApplyOutlayGrid;
    /*****基层用户操作 begin****/
    //基层用户申请追加经费：1
    var addApply = function () {
        var dialog = parent.$.modalDialog({
            title: '添加经费申请',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/ApplyOutlay_OP.aspx', //将对话框内容添加到父页面index
            buttons: [{
                text: '添加',
                handler: function () {
                    parent.onFormSubmit(dialog, userApplyOutlayGrid);
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
            width: 650,
            height: 500,
            iconCls: 'icon-edit',
            href: 'OutLayApply/dialogop/ApplyOutlay_OP.aspx?id=' + id,
            buttons: [{
                text: '保存',
                handler: function () {
                    parent.onFormSubmit(dialog, userApplyOutlayGrid);
                }
            }
            ]
        });
    };
    //删除经费
    var removeFun = function (id) {
        parent.$.messager.confirm('询问', '您确定要删除该项申请？', function (r) {
            if (r) {
                $.post('../service/SpecialOutlayAllocate.ashx/RemoveApplyOutlay', {
                    id: id
                }, function (result) {
                    if (result.success) {
                        userApplyOutlayGrid.datagrid('reload');
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
                $.post('../service/SpecialOutlayAllocate.ashx/SendApplyOutlay', {
                    id: id
                }, function (result) {
                    if (result.success) {
                        userApplyOutlayGrid.datagrid('reload');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    /*****基层用户操作 end****/
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
    //审批经费,8:部门负责人，9：部门主管领导，4：行财科长，10：行财主管领导
    var approverFun = function (id) {
        var dialog = parent.$.modalDialog({
            title: '经费审批',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/ApproverApplyOutlay_OP.aspx?id=' + id, //将对话框内容添加到父页面index
            buttons: [
                {
                    text: '提交',
                    handler: function () {
                        parent.onFormSubmit(dialog, userApplyOutlayGrid);
                    }
                },
                {
                    text: '关闭',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }
            ]
        });
    };
    //稽核确认审批通过的经费,2:稽核员
    var auditApproverFun = function (id) {
        var dialog = parent.$.modalDialog({
            title: '生成追加经费',
            width: 650,
            height: 500,
            iconCls: 'ext-icon-note_add',
            href: 'OutLayApply/dialogop/AuditApproveOutlay_OP.aspx?id=' + id,
            buttons: [
                {
                    text: '经费确认并生成',
                    handler: function () {
                        parent.onFormSubmit(dialog, userApplyOutlayGrid);
                    }
                },
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
        userApplyOutlayGrid.datagrid('load', $.serializeObject($('#userApplyOutlayForm')));
    };
    //重置查询
    var resetGrid = function () {
        $('#userApplyOutlayForm input').val('');
        userApplyOutlayGrid.datagrid('load', {});
    };
    //导出申请追加经费明细excel
    var exportApplyOutlay = function () {
        jsPostForm('../service/SpecialOutlayAllocate.ashx/ExportUserApplyOutlayDetail', $.serializeObject($('#userApplyOutlayForm')));
    };
    $(function () {
        /*datagrid生成*/
        userApplyOutlayGrid = $('#userApplyOutlayGrid').datagrid({
            title: '追加经费申请明细',
            url: '../service/SpecialOutlayAllocate.ashx/GetApplyOutlayDetail',
            striped: true,
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
            frozenColumns: [[{
                title: '操作',
                field: 'action',
                width: '90',
                halign: 'center',
                align: 'center',
                formatter: function (value, row) {
                    var str = '';
                    if (roleid == 1) {//基础用户
                        if (row.status < 1) {
                            str += $.formatString('<a href="javascript:void(0);" title="编辑" onclick="editFun(\'{0}\');">编辑</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);"  title="删除" onclick="removeFun(\'{0}\');">删除</a>&nbsp;', row.id);
                            str += $.formatString('<a href="javascript:void(0);"  title="送审" onclick="sendFun(\'{0}\');">送审</a>', row.id);
                        } else
                            str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">详情</a>', row.id);

                    }
                    //if (roleid == 8) {//部门负责人
                    //    if(row.status == 1)
                    //        str += $.formatString('<a href="javascript:void(0)" onclick="auditFun(\'{0}\');">费用审批</a>', row.id);
                    //    else
                    //        str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">详情</a>', row.id);
                    //}
                    //if (roleid == 9)//部门主管领导
                    //{
                    //    if(row.status == 2)

                    //}
                    if ((row.status == 1 && roleid == 8) || (row.status == 2 && roleid == 9) || (row.status == 3 && roleid == 4) || (row.status == 4 && roleid == 10) || (row.status >= 1 && row.status <= 4 && roleid == 6)) {//费用审批
                        str += $.formatString('<a href="javascript:void(0)" onclick="approverFun(\'{0}\');">费用审批</a>', row.id);
                    }
                    if ((row.status != 1 && roleid == 8) || (row.status != 2 && roleid == 9) || (row.status != 3 && roleid == 4) || (row.status != 4 && roleid == 10) || (row.status != 5 && roleid == 2) || ((row.status<1 || row.status>5) && roleid == 6) || roleid == 7) {//显示详情
                        str += $.formatString('<a href="javascript:void(0);" onclick="viewFun(\'{0}\');">显示详情</a>', row.id);
                    }
                    if (row.status == 5 && roleid == 2) { //稽核审核生成费用
                        str += $.formatString('<a href="javascript:void(0)" onclick="auditApproverFun(\'{0}\');">费用生成</a>', row.id);
                    }
                    if (row.applytitle == '合计')
                        str = '';
                    return str;
                }
            }, {
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
                width: '120',
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
                            return '部门负责人审核中'
                            break;
                        case '2':
                            return '部门主管领导审批中'
                            break;
                        case '3':
                            return '行财部门审核中'
                            break;
                        case '4':
                            return '行财领导审批中'
                            break;
                        case '5':
                            return '审批通过费用生成中'
                            break;
                        case '6':
                            return '费用已生成'
                            break;
                    }
                }
            }, {
                width: '55',
                title: '额度编号',
                field: 'specialoutlayid',
                halign: 'center',
                align: 'center'

            }, {
                width: '100',
                title: '联系人',
                field: 'linkman',
                halign: 'center',
                align: 'center'
            }, {
                width: '100',
                title: '联系电话',
                field: 'linkmantel',
                halign: 'center',
                align: 'center'
            }, {
                width: '220',
                title: '申请内容',
                field: 'applycontent',
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
            }]],
            toolbar: '#userApplyOutlayToolBar',
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
                $(this).datagrid('tooltip', ['applycontent', 'cname', 'usefor']);
                $(this).datagrid('clearSelections');
            },
            onDblClickRow: function (index, row) {
                viewFun(row.id);
            }

        });
        //设置分页属性
        var pager = $('#userApplyOutlayGrid').datagrid('getPager');
        pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
    });
</script>
<div id="userApplyOutlayToolBar" style="display: none;">
    <form id="userApplyOutlayForm" style="margin: 0;">
        <table>
            <tr>
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
                <tr>
                    <td width="60" align="right">状态：
                    </td>
                    <td colspan="5">
                        <input name="status" style="width: 120px; text-align: center;" id="status" class="easyui-combobox"
                            data-options="panelHeight:'auto',editable:false, valueField:'value',textField:'text',data: [{'value':'99','text':'全部'},{'value':'-1','text':'被退回'},{'value':'0','text':'待送审'},{'value':'1','text':'部门负责人审核中'},{'value':'2','text':'部门主管领导审批中'},{'value':'3','text':'行财部门审核中'},{'value':'4','text':'行财主管领导审批中'},{'value':'5','text':'审批通过费用生成中'},{'value':'6','text':'费用已生成'}]" />

                        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                            onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportApplyOutlay();">导出</a>
                    </td>
                </tr>
        </table>
    </form>
    <div <%=(roleid!=1)?"style='display:none'":"" %>>
        <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-note_add',plain:true"
            onclick="addApply();">添加经费申请</a>
    </div>
</div>
<table id="userApplyOutlayGrid" data-options="fit:true,border:true">
</table>
