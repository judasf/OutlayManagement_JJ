<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>专项经费支出管理</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
</head>
<style type="text/css">
    #allocateForm table td { padding: 8px; }

    #allocateForm table td a { margin: 0 5px; }
</style>
<!-- 可用额度明细查询——基层用户 -->
<%if (!Request.IsAuthenticated)
  {%>
<script type="text/javascript">
    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
        parent.location.replace('index.aspx');
    });
</script>
<%} %>
<script type="text/javascript">
    //显示公用经费支出明细
    var showPublicOutlaySpending = function (deptid) {
        var dialog = parent.$.modalDialog({
            title: '公用经费支出明细',
            width: 730,
            height: 440,
            iconCls: 'ext-icon-page',
            href: 'OutlayReimburse/dialogop/PublicOutlaySpending_OP.aspx?deptid=' + deptid,
            buttons: [{
                text: '关闭',
                handler: function () {
                    dialog.dialog('close');
                }
            }]
        });
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
    //专项经费额度合并到公用
    var mergeToPublicOutlay = function (id) {
        parent.$.messager.confirm('合并到公用', '您确认要将该项经费合并到公用？', function (r) {
            if (r) {
                specialGrid.datagrid('reload');
                $.post('../service/SpecialOutlayAllocate.ashx/MergeToPublicOutlay',
                { id: id },
                function (result) {
                    if (result.success) {
                        specialGrid.datagrid('reload');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    }
    //查询功能
    var searchGrid = function () {
        publicGrid.datagrid('load', $.serializeObject($('#searchForm')));
        specialGrid.datagrid('load', $.serializeObject($('#searchForm')));
    };
    //公用经费表
    var publicGrid;
    //专项经费表
    var specialGrid;
    $(function () {
        //公用经费数据表
        publicGrid = $('#publicGrid').datagrid({
            title: '公用经费明细',
            noheader: true,
            collapsible: true,
            url: '../service/PublicOutlayAllocate.ashx/GetPublicOutlay',
            columns: [
          [{
              width: '150',
              title: '可用额度',
              field: 'unusedoutlay',
              halign: 'center',
              align: 'center'
          }, {
              width: '200',
              title: '下达额度时间',
              field: 'lastoutlaytime',
              halign: 'center',
              align: 'center',
              formatter: function (value) {
                  return value.substr(0, value.indexOf(' ')).replace(/\//g, '-');
              }
          }, {
              width: '110',
              title: '单位名称',
              field: 'deptname',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '经费类别',
              field: 'cname',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '支出明细',
              field: 'spending',
              halign: 'center',
              align: 'center',
              formatter: function (val, row) {
                  var str = $.formatString('<a href="javascript:void(0)" onclick="showPublicOutlaySpending(\'{0}\');">支出明细</a>&nbsp;', row.deptid);
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
        //专项经费数据表
        specialGrid = $('#specialGrid').datagrid({
            title: '专项经费明细',
            url: '../service/SpecialOutlayAllocate.ashx/GetUnUsedSpecialOutlay',
            striped: true,
            rownumbers: true,
            pagination: true,
            showFooter: true,
            pageSize: 10,
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
                  title: '经费合并',
                  field: 'outlaymerge',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row) {
                      var str = '';
                      //有专项可用额度时可合并到公用额度,为负值时也可合并
                      if (parseFloat(row.unusedoutlay) != 0 && row.outlaytime != '合计') {
                          str = $.formatString('<a href="javascript:void(0)" onclick="mergeToPublicOutlay(\'{0}\');">合并到公用</a>&nbsp;', row.id);
                      }
                      return str;
                  }
              }
              , {
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
            }
        });
        //设置分页属性
        var pager = $('#specialGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
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
                        <td width="70" align="right">可用额度：
                        </td>
                        <td>
                            <select name="unusedOutlay" id="unusedOutlay" class="easyui-combobox" data-options="panelHeight:'auto',editable:false">
                                <option value="1">有可用额度</option>
                                <option value="0">全部额度</option>
                            </select>
                        </td>
                        <td style="padding-left: 20px;">
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:false"
                                onclick="searchGrid();">查询</a>

                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <!--公用经费明细-->
        <table id="publicGrid" data-options="fit:false,border:false">
        </table>
        <!--专项经费明细-->
        <table id="specialGrid" data-options="fit:false,border:false">
        </table>
    </div>
</body>
</html>
