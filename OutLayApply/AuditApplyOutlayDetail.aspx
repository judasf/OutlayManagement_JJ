<%@ Page Language="C#" %>

<%--直接追加经费申请生成后的明细——基层用户查看--%>
<%if(!Request.IsAuthenticated)
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
    var roleid = '<%=roleid%>';
</script>
<%} %>
<script type="text/javascript">
    var auditApplyGird;
    //查看详情，并打印
    var viewAuditApplyFun = function (id) {
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
    var searchAuditApplyGrid = function () {
        auditApplyGird.datagrid('load', $.serializeObject($('#auditApplyForm')));
    };
    //重置查询
    var resetAuditApplyGrid = function () {
        $('#auditApplyForm input').val('');
        auditApplyGird.datagrid('load', {});
    };
    //导出已生成的直接拨付经费明细到excel
    var exportAuditApplyOutlay = function () {
        jsPostForm('../service/AuditApplyOutlayAllocate.ashx/ExportHasCreateAuditApplyOutlay', $.serializeObject($('#auditApplyForm')));
    };
    $(function () {
        /*datagrid生成*/
        auditApplyGird = $('#auditApplyGird').datagrid({
            title: '稽核追加经费申请明细',
            url: '../service/AuditApplyOutlayAllocate.ashx/GetAuditApplyOutlayDetail',
            striped: true,
            rownumbers: true,
            noheader: true,
            border:false,
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
                        case '2':
                            return '已生成';
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
                    if (row.status == 2)//已生成可用额度，可查看打印
                        str += $.formatString('<a href="javascript:void(0);" onclick="viewAuditApplyFun(\'{0}\');">详情</a>', row.id);
                    return str;
                }
            }]],
            toolbar: '#auditApplyToolBar',
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
            }
        });
        //设置分页属性
        var pager = $('#auditApplyGird').datagrid('getPager');
        pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
    });
</script>
<div id="auditApplyToolBar" style="display: none;">
    <form id="auditApplyForm" style="margin: 0;">
    <table>
        <tr>
            <td width="60" align="right">
                月份：
            </td>
            <td>
                <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate" required
                    onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})" readonly="readonly" />
            </td>
            <td width="70" align="right">
                额度编号：
            </td>
            <td>
                <input style="width: 55px; height: 20px" type="text" class="combo" name="outlayid" />
            </td>
            <td width="60" align="right">
                经费类别：
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
            <td>
                <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                    onclick="searchAuditApplyGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                        data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetAuditApplyGrid();">
                        重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                            onclick="exportAuditApplyOutlay();">导出</a>
            </td>
        </tr>
    </table>
    </form>
</div>
<table id="auditApplyGird" data-options="fit:true,border:true">
</table>
