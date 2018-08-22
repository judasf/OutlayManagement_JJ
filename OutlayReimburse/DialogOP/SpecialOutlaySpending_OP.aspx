<%@ Page Language="C#" %>

<% 
    /*
     * 显示基层单位专项经费支出明细
     */
    string deptid = string.IsNullOrEmpty(Request.QueryString["deptid"]) ? "" : Request.QueryString["deptid"].ToString();
    string outlayid = string.IsNullOrEmpty(Request.QueryString["outlayid"]) ? "" : Request.QueryString["outlayid"].ToString();
%>
<!-- 专项经费支出明细 -->
<script type="text/javascript">
    //导出专项经费支出明细excel
    var exportSpecialSpending = function () {
        jsPostForm('../service/ReimburseOutlay.ashx/ExportSpecialOutlaySpending?deptid=' + $('#deptid').val() + '&outlayid=' + $('#outlayid').val(), $.serializeObject($('#searchForm')));
    };
    //专项经费支出明细表
    var soSGrid;
    $(function () {
        soSGrid = $('#soSGrid').datagrid({
            title: '专项经费支出明细表',
            url: '../service/ReimburseOutlay.ashx/GetSpecialOutlaySpendingDetail?deptid=' + $('#deptid').val() + '&outlayid=' + $('#outlayid').val(),
            striped: true,
            rownumbers: true,
            pagination: true,
            noheader: true,
            showFooter: true,
            pageSize: 10,
            singleSelect: true,
            idField: 'reimbursedate',
            sortName: 'reimbursedate',
            sortOrder: 'desc',
            columns: [
              [{
                  width: '100',
                  title: '单位名称',
                  field: 'deptname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '支出日期',
                  field: 'reimbursedate',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '办理编号',
                  field: 'reimburseno',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '支出方式',
                  field: 'reimbursetype',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '支出科目',
                  field: 'expensesubject',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '支出金额',
                  field: 'reimburseoutlay',
                  halign: 'center',
                  align: 'center'
              }
              ]
            ],
            toolbar: '#cgTip',
            onLoadSuccess: function (data) {
                if (data.rows.length == 0) {
                    var body = $(this).data().datagrid.dc.body2;
                    body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                }
            }
        });
        //设置分页属性
        var pager = $('#soSGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<div id="cgTip">
    <form id="searchForm" style="margin: 0;">
        <table>
            <tr>
                <td width="60" align="right">支出日期：
                </td>
                <td>
                    <input type="hidden" value="<%=deptid %>" id="deptid" />
                    <input type="hidden" value="<%=outlayid %>" id="outlayid" />
                    <input style="width: 85px; font: normal normal normal 13.3333330154419px/normal Arial" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')||\'%y-%M-%d\'}'})"
                        readonly="readonly" />-<input style="width: 85px; font: normal normal normal 13.3333330154419px/normal Arial" name="edate" id="edate" class="Wdate"
                            onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                </td>
                <td width="60" align="right">支出方式：
                </td>
                <td>
                    <input style="width: 105px" name="reimbursetype" id="reimbursetype" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'','text':'全部'},{'value':'现金支出','text':'现金支出'},{'value':'转账支出','text':'转账支出'},{'value':'公务卡支出','text':'公务卡支出'},{'value':'经费扣减','text':'经费扣减'},{'value':'合并到公用','text':'合并到公用'}]" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="soSGrid.datagrid('load', $.serializeObject($('#searchForm')));">查询</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                        onclick="  $('#searchForm input').val('');soSGrid.datagrid('load', {});">重置</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                        onclick="exportSpecialSpending();">导出</a>
                </td>
            </tr>
        </table>
    </form>
</div>
<table id="soSGrid" data-options="fit:true,border:false">
</table>
