<%@ Page Language="C#" %>

<%--单位经费收支分类统计表——稽核--%>
<%  
    if (!Request.IsAuthenticated)
    {%>
<script type="text/javascript">
    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
        parent.location.replace('index.aspx');
    });
</script>
<%}%>
<script type="text/javascript">
    var otsGrid;
    //显示日期
    //var showDate;
    //var myDate =new Date();
    //查询功能
    var searchOtsGrid = function () {
        console.log($('input[name=sdate]','#otsForm').val());
        otsGrid.datagrid('load', $.serializeObject($('#otsForm')));
    };
    //重置查询
    var resetOtsGrid = function () {
        $('#otsForm input').val('');
        otsGrid.datagrid('load', {});
    };
    //导出单位经费收支分类统计表到excel
    var exportDeptOutlayTypeStatistics = function () {
        jsPostForm('../service/DataStatistics.ashx/ExportDeptOutlayTypeStatistics', $.serializeObject($('#otsForm')));
    };
    $(function () {
        /*datagrid生成*/
        otsGrid = $('#otsGrid').datagrid({
            title: '单位经费收支分类统计表',
            url: '../service/DataStatistics.ashx/GetAllDeptOutlayTypeStatisticsForAudit',
            striped: true,
            fit: true,
            rownumbers: true,
            pagination: false,
            showFooter: true,
            noheader: true,
            border: false,
            singleSelect: true,
            showFooter: true,
            idField: 'deptid',
            columns: [
                [
                {
                    width: '150',
                    title: '单位',
                    field: 'deptname',
                    halign: 'center',
                    align: 'center',
                    rowspan:2
                },
                { field: '', title: '收入', colspan: 4, width: 400,halign: 'center'},
    { field: '', title: '支出', colspan: 2, width: 200, halign: 'center' },
                {
                    width: '100',
                    title: '余额',
                    field: 'balance',
                    halign: 'center',
                    align: 'center',
                    rowspan: 2
                }
            ], [
                {
                    width: '100',
                    title: '定额公用',
                    field: 'pbo',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '追加公用',
                    field: 'app_pb',
                    halign: 'center',
                    align: 'center'

                }, {
                    width: '100',
                    title: '追加专项',
                    field: 'app_sp',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '扣减经费',
                    field: 'ddo',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '公用经费支出',
                    field: 'reim_pb',
                    halign: 'center',
                    align: 'center'
                }, {
                    width: '100',
                    title: '专项经费支出',
                    field: 'reim_sp',
                    halign: 'center',
                    align: 'center'
                }]],
            toolbar: '#otstoolbar',
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
    });
</script>
<div id="otstoolbar" style="display: none;">
    <form id="otsForm" style="margin: 0;">
        <table>
            <tr>
                <td width="80" align="right">选择日期：
                </td>
                <td>
                      <input style="width: 90px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')}',maxDate:'%y-%M-%d',dateFmt:'yyyy-MM-dd'})"
                        readonly="readonly" />-<input style="width: 90px;" name="edate" id="edate" class="Wdate"
                            onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d',dateFmt:'yyyy-MM-dd'})" readonly="readonly" />
                </td>
                 <td width="80" align="right">选择单位：
                        </td>
                        <td>
                            <input name="deptId" id="deptId" style="width: 120px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 120,
                    panelHeight: '180',
                    editable:false,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                        </td>
                <td style="margin-left: 10px;">
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchOtsGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetOtsGrid();">重置</a>
                     <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportDeptOutlayTypeStatistics();">导出</a>
                </td>
            </tr>
        </table>
        <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px;
                line-height: 24px; padding-left: 30px;">
                默认显示当年统计数据！
            </div>
    </form>
</div>
<table id="otsGrid">
</table>
