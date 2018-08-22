<%@ Page Language="C#" %>

<%--经费收支余额总表——一般用户--%>
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
    var aosGrid;
    //查询功能
    var searchAosGrid = function () {
        aosGrid.datagrid('load', $.serializeObject($('#aosForm')));
    };
    //重置查询
    var resetAosGrid = function () {
        $('#aosForm input').val('');
        aosGrid.datagrid('load', {});
    };
    //导出一般用户经费收支余额总表到excel
    var exportBaseUserAllOutlayStatistics = function () {
        jsPostForm('../service/DataStatistics.ashx/ExportBaseUserAllOutlayStatistics', $.serializeObject($('#aosForm')));
    };
    $(function () {
        /*datagrid生成*/
        aosGrid = $('#aosGrid').datagrid({
            title: '经费收支余额总表',
            url: '../service/DataStatistics.ashx/GetDeptAllOutlayDetail',
            striped: true,
            fit: true,
            rownumbers: true,
            pagination: false,
            showFooter: true,
            noheader: true,
            border: false,
            singleSelect: true,
            showFooter: true,
            idField: 'id',
            columns: [[{
                width: '100',
                title: '日期',
                field: 'outlaymonth',
                halign: 'center',
                align: 'center',
                formatter: function (value) {
                    if (value != '合计')
                        return value.replace('-', '年') + '月';
                    else
                        return value;
        }
            }, {
                width: '100',
                title: '收入',
                field: 'income',
                halign: 'center',
                align: 'center'

            }, {
                width: '100',
                title: '支出',
                field: 'spending',
                halign: 'center',
                align: 'center'

            }, {
                width: '100',
                title: '可用额度',
                field: 'unusedoutlay',
                halign: 'center',
                align: 'center'
            }]],
            toolbar: '#aostoolbar',
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
<div id="aostoolbar" style="display: none;">
    <form id="aosForm" style="margin: 0;">
        <table>
            <tr>
                <td width="80" align="right">选择日期：
                </td>
                <td>
                    <input style="width: 90px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')}',maxDate:'%y-%M',dateFmt:'yyyy年MM月'})"
                        readonly="readonly" />-<input style="width: 90px;" name="edate" id="edate" class="Wdate"
                            onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-{%M+1}',dateFmt:'yyyy年MM月'})" readonly="readonly" />
                </td>
                <td style="margin-left: 10px;">
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchAosGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetAosGrid();">重置</a>
                     <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                    onclick="exportBaseUserAllOutlayStatistics();">导出</a>
                </td>
            </tr>
        </table>
          <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px;
                line-height: 24px; padding-left: 30px;">
                默认显示当年统计数据！
            </div>
    </form>
</div>
<table id="aosGrid">
</table>
