<%@ Page Language="C#" %>

<style type="text/css">
    #allocateForm table td { padding: 8px; }
    #allocateForm table td a { margin: 0 5px; }
</style>
<!-- 专项经费修正——管理员 -->
<%if (!Request.IsAuthenticated)
  {%>
<script type="text/javascript">
    $(function () {
        parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
            parent.location.replace('index.aspx');
        });
    });
</script>
<%} %>
<script type="text/javascript">
    //查询功能
    var sp_searchGrid = function () {
        fixedSpecialGrid.datagrid('load', $.serializeObject($('#spsearchForm')));
    };
    //重置查询
    var sp_resetGrid = function () {
        $('#spsearchForm input').val('');
        fixedSpecialGrid.datagrid('load', {});
    };
    //专项经费修正，通过额度编号
    var fixedSpecialOutlay = function (deptid,outlayid, balance) {
        parent.$.messager.confirm('确认', '您确认要修正该项额度？', function (r) {
            if (r) {
                $.post('../service/DataStatistics.ashx/FixedSpecialOutlay',
                { deptid: deptid, outlayid: outlayid, balance: balance },
                function (result) {
                    if (result.success) {
                        fixedSpecialGrid.datagrid('reload');
                        parent.$.messager.alert('成功', result.msg, 'info');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //专项经费表
    var fixedSpecialGrid;
    $(function () {
        //专项经费数据表
        fixedSpecialGrid = $('#fixedSpecialGrid').datagrid({
            title: '专项经费明细',
            noheader: true,
            collapsible: true,
            striped: true,
            rownumbers: true,
            pagination: true,
            showFooter: true,
            pageSize: 20,
            singleSelect: true,
            idField: 'deptid',
            sortName: 'deptid',
            sortOrder: 'desc',
            url: '../service/DataStatistics.ashx/GetFixedSpecialOutlyDetail',
            columns: [
          [{
              width: '110',
              title: '单位名称',
              field: 'deptname',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '额度编号',
              field: 'outlayid',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '下达额度',
              field: 'alloutlay',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '额度扣减',
              field: 'ddo',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '现金支出',
              field: 'cash_sp',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '转账支出',
              field: 'account_sp',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '公务卡支出',
              field: 'card_sp',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '合并到公用',
              field: 'smp_sp',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '显示可用额度',
              field: 'unusedoutlay',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '待修正额度',
              field: 'balance',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '操作',
              field: 'action',
              halign: 'center',
              align: 'center',
              formatter: function (val, row) {
                  var str = '无需修正';
                  if (row.balance != row.unusedoutlay)
                      str = $.formatString('<a href="javascript:void(0)" onclick="fixedSpecialOutlay(\'{0}\',\'{1}\',\'{2}\');">修正额度</a>&nbsp;', row.deptid,row.outlayid,row.balance);
                  return str;
              }
          }]
            ],
            toolbar: '#spgTip',
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
        var pager = $('#fixedSpecialGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<div id="spgTip">
    <form id="spsearchForm" style="margin: 0;">
        <table>
            <tr>
                <td width="100" align="right">单位名称：
                </td>
                <td>
                    <input name="sp_deptId" id="sp_deptId" style="width: 200px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 200,
                    panelHeight: '180',
                    editable:true,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                </td>
                <td width="70" align="right">额度修正：
                </td>
                <td>
                    <select name="sp_status" id="sp_status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false">
                        <option value="1">待修正额度</option>
                        <option value="0">全部额度</option>
                    </select>
                </td>
                <td style="padding-left: 20px;">
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="sp_searchGrid();">查询</a><a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="sp_resetGrid();">
                                重置</a>

                </td>
            </tr>
        </table>
    </form>
</div>
<!--公用经费明细-->
<table id="fixedSpecialGrid" data-options="fit:true,border:false">
</table>


