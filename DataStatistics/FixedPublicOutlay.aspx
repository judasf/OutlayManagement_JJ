<%@ Page Language="C#" %>

<style type="text/css">
    #allocateForm table td { padding: 8px; }
    #allocateForm table td a { margin: 0 5px; }
</style>
<!-- 公用经费修正——管理员 -->
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
    var searchGrid = function () {
        fixedpublicGrid.datagrid('load', $.serializeObject($('#searchForm')));
    };
    //重置查询
    var resetGrid = function () {
        $('#searchForm input').val('');
        fixedpublicGrid.datagrid('load', {});
    };
    //公用经费修正，通过部门编号
    var fixedPublicOutlay = function (deptid,balance) {
        parent.$.messager.confirm('确认', '您确认要修正该项额度？', function (r) {
            if (r) {
                $.post('../service/DataStatistics.ashx/FixedPublicOutlay',
                { deptid: deptid,balance:balance },
                function (result) {
                    if (result.success) {
                        fixedpublicGrid.datagrid('reload');
                        parent.$.messager.alert('成功', result.msg, 'info');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //公用经费表
    var fixedpublicGrid;
    $(function () {
        //公用经费数据表
        fixedpublicGrid = $('#fixedpublicGrid').datagrid({
            title: '公用经费明细',
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
            url: '../service/DataStatistics.ashx/GetFixedPublicOutlyDetail',
            columns: [
          [{
              width: '110',
              title: '单位名称',
              field: 'deptname',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '定额公用',
              field: 'pbo',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '追加公用',
              field: 'aao_pb',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '申请公用',
              field: 'spo_pb',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '专项合并到公用',
              field: 'smp_sp',
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
              field: 'cash_pb',
              halign: 'center',
              align: 'center'
          }
          , {
              width: '100',
              title: '转账支出',
              field: 'account_pb',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '公务卡支出',
              field: 'card_pb',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '显示可用额度',
              field: 'uno_pb',
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
                  if (row.balance != row.uno_pb)
                      str = $.formatString('<a href="javascript:void(0)" onclick="fixedPublicOutlay(\'{0}\',\'{1}\');">修正额度</a>&nbsp;', row.deptid, row.balance);
                  return str;
              }
          }]
            ],
            toolbar: '#pgTip',
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
        var pager = $('#fixedpublicGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<div id="pgTip">
    <form id="searchForm" style="margin: 0;">
        <table>
            <tr>
                <td width="100" align="right">单位名称：
                </td>
                <td>
                    <input name="deptId" id="deptId" style="width: 200px;" class="easyui-combobox" data-options="
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
                    <select name="status" id="status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false">
                        <option value="1">待修正额度</option>
                        <option value="0">全部额度</option>
                    </select>
                </td>
                <td style="padding-left: 20px;">
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchGrid();">查询</a><a href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">
                                重置</a>

                </td>
            </tr>
        </table>
    </form>
</div>
<!--公用经费明细-->
<table id="fixedpublicGrid" data-options="fit:true,border:false">
</table>


