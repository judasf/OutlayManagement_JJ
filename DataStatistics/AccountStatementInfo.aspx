<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>单位对账单</title>
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
<!-- 单位对账单——基层用户查看1，稽核员2管理员6 -->
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
    //显示年度
    var yearshow = new Date().getFullYear();
    //查询功能
    var searchGrid = function () {
        yearshow = $('#outlayyear').val().length > 0 ? $('#outlayyear').val() : new Date().getFullYear();
        $('.datagrid-cell-group').html(yearshow + '年');
        accountStatementGrid.datagrid('load', $.serializeObject($('#searchForm')));
    };
    //重置查询
    var resetGrid = function () {
        $('#searchForm input').val('');
        accountStatementGrid.datagrid('load', {});
    };
    //导出明细到excel 
    var exportAccountStatement = function () {
        jsPostForm('../service/DataStatistics.ashx/ExportAccountStatement', $.serializeObject($('#searchForm')));
    };

    //对账单
    var accountStatementGrid;
    $(function () {
        //console.log($('#outlayyear').val());
        //设置显示年度
        //var yearshow = $('#outlayyear').val().length>0 ? $('#outlayyear').val() : new Date().getFullYear();
        //对账单
        accountStatementGrid = $('#accountStatementGrid').datagrid({
            title: '对账单',
            noheader: true,
            collapsible: true,
            url: '../service/DataStatistics.ashx/GetAccountStatementInfo',
            striped: true,
            rownumbers: true,
            singleSelect: true,
            columns: [
          [{
              width: '100',
              title: yearshow + '年',
              field: '',
              halign: 'center',
              align: 'center',
              colspan: 2,
              rowspan: 1
          }, {
              width: '200',
              title: '凭证编号',
              field: 'cn',
              halign: 'center',
              align: 'center',
              rowspan: 2
          }, {
              width: '200',
              title: '摘要',
              field: 'memo',
              halign: 'center',
              align: 'center',
              rowspan: 2
          }, {
              width: '100',
              title: '收入',
              field: 'income',
              halign: 'center',
              align: 'center',
              rowspan: 2
          }, {
              width: '100',
              title: '支出',
              field: 'payout',
              halign: 'center',
              align: 'center',
              rowspan: 2
          }], [{
              width: '50',
              title: '月',
              field: 'm',
              halign: 'center',
              align: 'center',
              rowspan: 1
          }, {
              width: '50',
              title: '日',
              field: 'd',
              halign: 'center',
              align: 'center',
              rowspan: 1
          }]
            ],
            rowStyler: function (index, row) {
                if (row.memo.indexOf('（小计）') > -1) {
                    return 'background-color:#6293BB;color:#fff;';
                }
            },
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
        var pager = $('#accountStatementGrid').datagrid('getPager');
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
                    url: '../service/Department.ashx/GetScopeDeptsCombobox',
                    onSelect:function(rec){   
            $('#deptname').val(rec.text);}" />
                            <input type="hidden" name="deptname" id="deptname" value="" />
                        </td>
                        <%} %>
                        <td width="100" align="right">年度：
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
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:false"
                                onclick="exportAccountStatement();">导出</a>
                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <!--年度结余经费明细-->
        <table id="accountStatementGrid" data-options="fit:false,border:false">
        </table>
    </div>
</body>
</html>
