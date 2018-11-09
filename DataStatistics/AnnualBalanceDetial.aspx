<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>年度经费结余明细</title>
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
<!-- 年度经费结余明细——基层用户查看1，管理员提取6 -->
<%
    string roleid = "0";
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
        roleid = ud.LoginUser.RoleId.ToString();
    } %>
<script type="text/javascript">

    //查询功能
    var searchGrid = function () {
        annualBalanceGrid.datagrid('load', $.serializeObject($('#searchForm')));
    };
    //重置查询
    var resetGrid = function () {
        $('#searchForm input').val('');
        annualBalanceGrid.datagrid('load', {});
    };
    //提取上年结余经费
    var fetchBalance = function () {
        parent.$.messager.confirm('询问', '您确定要提取上年结余经费数据，提取后不能修改？', function (r) {
            if (r) {
                $.post('../service/DataStatistics.ashx/FetchAnnualBalance', function (result) {
                    if (result.success) {
                        parent.$.messager.alert('提示', '提取成功！', 'info', function () { annualBalanceGrid.datagrid('reload'); });
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //年度结余经费表
    var annualBalanceGrid;
    $(function () {
        //年度结余经费
        annualBalanceGrid = $('#annualBalanceGrid').datagrid({
            title: '年度结余经费',
            noheader: true,
            collapsible: true,
            url: '../service/DataStatistics.ashx/GetAnnualBalanceDetail',
            striped: true,
            rownumbers: true,
            pagination: true,
            pageSize: 10,
            singleSelect: true,
            idField: 'id',
            sortName: 'b.deptid',
            sortOrder: 'asc',
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
              align: 'center',
              formatter: function (value) {
                  return value == 0 ? '无' : value;
              }
          }, {
              width: '200',
              title: '摘要',
              field: 'memo',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '结余额度',
              field: 'unusedoutlay',
              halign: 'center',
              align: 'center'
          }, {
              width: '100',
              title: '结余年度',
              field: 'outlayyear',
              halign: 'center',
              align: 'center'
          }, {
              width: '150',
              title: '数据提取时间',
              field: 'fetchtime',
              halign: 'center',
              align: 'center'
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
        var pager = $('#annualBalanceGrid').datagrid('getPager');
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
                        <%if (roleid != "1")
                            { %>
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
                        <%} %>
                        <td width="100" align="right">经费结余年度：
                        </td>
                        <td>
                            <input style="width: 70px;" name="outlayyear" id="outlayyear" class="Wdate" onfocus="WdatePicker({maxDate:'%y',dateFmt:'yyyy'})"
                                readonly="readonly" />
                        </td>
                        <td style="padding-left: 20px;">
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:false"
                                onclick="searchGrid();">查询</a>
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:false"
                                onclick="resetGrid();">重置</a>
                            <%if (roleid == "6")
                                { %>
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'icon-save',plain:false"
                                onclick="fetchBalance();">提取上年结余经费</a>
                            <%} %>

                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <!--年度结余经费明细-->
        <table id="annualBalanceGrid" data-options="fit:false,border:false">
        </table>
    </div>
</body>
</html>
