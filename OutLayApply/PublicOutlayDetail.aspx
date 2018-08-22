<%@ Page Language="C#" AutoEventWireup="true" CodeFile="PublicOutlayDetail.aspx.cs"
    Inherits="OutLayApply_PublicOutlayDetail" %>

<!DOCTYPE html>
<html>
<head>
    <title>定额公用经费下发明细</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--定额公用经费下发明细——基层用户--%>
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
        var roleid=<%=roleid%>
    </script>
    <%} %>
    <script type="text/javascript">
        var grid;
        //查询功能
        var searchGrid = function () {
            grid.datagrid('load', $.serializeObject($('#allocateForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#allocateForm input').val('');
            grid.datagrid('load', {});
        };
        //导出定额公用经费下发明细到excel
        var exportPublicOutlay = function () {
            jsPostForm('../service/PublicOutlayAllocate.ashx/ExportUserPublicOutlayDetail', $.serializeObject($('#allocateForm')));
        };
        $(function () {
            /*datagrid生成*/
            grid = $('#grid').datagrid({
                title: '公用经费下发明细',
                url: '../service/PublicOutlayAllocate.ashx/GetPublicOutlayDetail',
                striped: true,
                rownumbers: true,
                fit:true,
                border: false,
                noheader:true,
                pagination: true,
                showFooter: true,
                pageSize: 20,
                singleSelect: false,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
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
                    title: '下发时间',
                    field: 'approvetime',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value) {
                        if (value)
                            return value.substr(0,value.indexOf(' ')).replace(/\//g, '-');
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
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar">
            <form id="allocateForm" style="margin: 0;">
                <table>
                    <tr>
                        <td width="80" align="right">下发月份：
                        </td>
                        <td>
                            <input style="width: 85px;" name="outlayMonth" id="outlayMonth" class="Wdate" onfocus="WdatePicker({dateFmt:'yyyy年MM月',maxDate:'%y-{%M+1}'})"
                                readonly="readonly" />
                        </td>
                        <td>
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                                onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                    data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                        onclick="exportPublicOutlay();">导出</a>
                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <table id="grid">
        </table>
    </div>
</body>
</html>
