<%@ Page Language="C#" %>

<style type="text/css">
    #allocateForm table td { padding: 8px; }
    #allocateForm table td a { margin: 0 5px; }
</style>
<!-- 专项经费支出管理——专项经费明细——基层用户 -->
<%if (!Request.IsAuthenticated)
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
      string userstatus = ud.LoginUser.UserStatus;
%>
<script type="text/javascript">
    var userstatus = '<%=userstatus%>';
</script>
<%} %>
<script type="text/javascript">
    //在对话框href中加入type,1:公用经费；2：专项经费
    //添加公用经费报销登记对话框
    var addReimburse = function (id) {
        var dialog = parent.$.modalDialog({
            title: '添加经费支出登记',
            width: 400,
            height: 500,
            iconCls: 'ext-icon-note_add',
            href: 'OutlayReimburse/dialogop/ReimburseOutlay_OP.aspx?type=2&id=' + id, //将对话框内容添加到父页面index
            buttons: [{
                text: '添加',
                handler: function () {
                    parent.onFormSubmit(dialog, specialGrid, spTabs);
                }
            }, {
                text: '取消',
                handler: function () {
                    dialog.dialog('close');
                }
            }]
        });
    };
    //导出专项经费明细excel
    var exportSpecialOutlay = function () {
        jsPostForm('../service/SpecialOutlayAllocate.ashx/ExportSpecialOutlayDetail', $.serializeObject($('#searchForm')));
    };
    //显示专项经费支出明细
    var showSpecialOutlaySpending = function (deptid, outlayid) {
        var dialog = parent.$.modalDialog({
            title: '专项经费支出明细',
            width: 730,
            height: 440,
            iconCls: 'ext-icon-page',
            href: 'OutlayReimburse/dialogop/SpecialOutlaySpending_OP.aspx?deptid=' + deptid + '&outlayid=' + outlayid,
            buttons: [{
                text: '关闭',
                handler: function () {
                    dialog.dialog('close');
                }
            }]
        });
    };
    //专项经费表
    var specialGrid;
    $(function () {
        //专项经费数据表
        specialGrid = $('#specialGrid').datagrid({
            title: '',
            url: '../service/SpecialOutlayAllocate.ashx/GetSpecialOutlay',
            striped: true,
            rownumbers: true,
            pagination: true,
            collapsible: true,
            showFooter: true,
            pageSize: 20,
            singleSelect: true,
            idField: 'id',
            sortName: 'unusedoutlay',
            sortOrder: 'desc',
            columns: [
              [{
                  width: '80',
                  title: '可用额度',
                  field: 'unusedoutlay',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '下达额度',
                  field: 'alloutlay',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '120',
                  title: '下达额度时间',
                  field: 'outlaytime',
                  sortable: true,
                  halign: 'center',
                  align: 'center',
                  formatter: function (value) {
                      return value.substr(0, value.indexOf(' ')).replace(/\//g, '-');
                  }
              }, {
                  width: '55',
                  title: '额度编号',
                  field: 'outlayid',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '110',
                  title: '单位名称',
                  field: 'deptname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '110',
                  title: '经费类别',
                  field: 'cname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '150',
                  title: '用途',
                  field: 'usefor',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '资金年度',
                  field: 'outlayyear',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row) {
                      var currentYear = new Date().getFullYear();
                      var thisYear = row.outlaytime.substr(0, 4);
                      if (row.outlaytime == '合计')
                          return '';
                      else {
                          if (currentYear == thisYear)
                              return '当年下达';
                          else
                              return '上年结余';
                      }
                  }
              }, {
                  width: '80',
                  title: '支出明细',
                  field: 'spendingdetail',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row) {
                      var str = '';
                      if (row.outlaytime != '合计')
                          str = $.formatString('<a href="javascript:void(0)" onclick="showSpecialOutlaySpending(\'{0}\',\'{1}\');">支出明细</a>&nbsp;', row.deptid, row.outlayid);
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
                //增加提示
                $(this).datagrid('tooltip', ['usefor']);
            },
            onDblClickRow: function (index, row) {
                if (userstatus == 0) {
                    //当可用额度为0时，提示用户无可用额度
                    if (parseFloat(row.unusedoutlay) <= 0)
                        parent.$.messager.alert('提示', '该项经费无可用额度，不能添加支出登记！', 'error');
                    else
                        addReimburse(row.id);
                }
                else
                    parent.$.messager.alert('提示', '该账号已被锁定,不能支出费用！', 'error');
            }
        });
        //设置分页属性
        var pager = $('#specialGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<div id="pgTip">
    <form id="searchForm" style="margin: 0;">
        <table>
            <tr>
                <td width="50" align="right">日期：
                </td>
                <td>
                    <input style="width: 80px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')}',maxDate:'%y-%M-%d'})"
                        readonly="readonly" />-<input style="width: 80px;" name="edate" id="edate" class="Wdate"
                            onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                </td>
                <td width="50" align="right">编号：
                </td>
                <td>
                    <input style="width: 55px; height: 20px" type="text" class="combo" name="outlayid" />
                </td>
                <td width="50" align="right">类别：
                </td>
                <td align="left">
                    <input name="outlayCategory" id="outlayCategory" class="easyui-combotree" data-options=" valueField: 'id',
            textField: 'text',
            editable: false,
            lines: true,
            panelHeight: 'auto',
            url: '../service/category.ashx/GetCategory?pid=2',
            onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            }" />
                </td>
                <td width="70" align="right">可用额度：
                </td>
                <td>
                    <select name="unusedOutlay" id="unusedOutlay" class="easyui-combobox" data-options="panelHeight:'auto',editable:false">
                        <option value="0">全部</option>
                        <option value="1">有可用额度</option>
                    </select>
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="specialGrid.datagrid('load', $.serializeObject($('#searchForm')));">查询</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                        onclick="  $('#searchForm input').val('');specialGrid.datagrid('load', {});">重置</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                        onclick="exportSpecialOutlay();">导出</a>
                </td>
            </tr>
        </table>
    </form>
    <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px; line-height: 24px; padding-left: 30px;">
        双击经费明细添加经费支出登记
    </div>
</div>
<!--专项经费明细-->
<table id="specialGrid" data-options="fit:false,border:false">
</table>
