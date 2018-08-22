<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>专项经费合并明细</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--专项经费合并明细--%>
    <% int roleid = 0;
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
        var mergeGrid;
        //查询功能
        var searchGrid = function () {
            mergeGrid.datagrid('load', $.serializeObject($('#mergeForm')));
        };
        //重置查询
        var resetGrid = function () {
            $('#mergeForm input').val('');
            mergeGrid.datagrid('load', {});
        };
        //导出明细到excel 
        var exportSpecialOutlayMerge = function () {
            jsPostForm('../service/SpecialOutlayAllocate.ashx/ExportSpecialOutlayMergeDetail', $.serializeObject($('#mergeForm')));
        };
        //管理员撤销额度合并
        var cancelMerge = function (id) {
            parent.$.messager.confirm('确认', '您确认要撤销该项合并操作？', function (r) {
                if (r) {
                    $.post('../service/SpecialOutlayAllocate.ashx/CancelMergePublic',
                    { id: id },
                    function (result) {
                        if (result.success) {
                            mergeGrid.datagrid('reload');
                            parent.$.messager.alert('成功', result.msg, 'info');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        };
        $(function () {
            /*datagrid生成*/
            mergeGrid = $('#mergeGrid').datagrid({
                title: '专项经费合并',
                url: '../service/SpecialOutlayAllocate.ashx/GetSpecialOutlayMergeDetail',
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
                    width: '100',
                    title: '单位名称',
                    field: 'deptname',
                    sortable: true,
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '120',
                    title: '专项经费额度编号',
                    field: 'outlayid',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '120',
                    title: '合并额度',
                    field: 'specialoutlay',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '80',
                    title: '经办人',
                    field: 'username',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '140',
                    title: '合并时间',
                    field: 'mergetime',
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
                            case '0':
                                return '已合并';
                                break;
                            case '1':
                                return '已撤销';
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
                        if (row.status == 0) { //管理员，可撤销已合并专项额度
                            str += $.formatString('<a href="javascript:void(0)" onclick="cancelMerge(\'{0}\');">撤销合并</a>', row.id);
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
            var pager = $('#mergeGrid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual'] });
            //非管理员隐藏操作列
            if (roleid != 6)
                $('#mergeGrid').datagrid('hideColumn', 'action');
        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="toolbar" style="display: none;">
            <form id="mergeForm" style="margin: 0;">
                <table>

                    <tr>
                        <%if (roleid != 1)
                          { %>
                        <td width="80" align="right">单位名称：
                        </td>
                        <td>
                            <input name="deptId" id="deptId" style="width: 120px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 120,
                    panelHeight: '180',
                    editable:true,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                        </td>
                        <%} %>
                        <td width="50" align="right">日期：
                        </td>
                        <td>
                            <input style="width: 90px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')||\'%y-%M-%d\'}'})"
                                readonly="readonly" />-<input style="width: 90px;" name="edate" id="edate" class="Wdate"
                                    onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                        </td>
                        <td width="100" align="right">专项额度编号：
                        </td>
                        <td>
                            <input style="width: 55px; height: 20px" type="text" class="combo" name="outlayid" />
                        </td>
                        <td>
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                                onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                                    data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a> <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                        onclick="exportSpecialOutlayMerge();">导出</a>
                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <table id="mergeGrid">
        </table>
    </div>
</body>
</html>
