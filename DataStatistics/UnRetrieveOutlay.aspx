<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>未取回单笔现金支出额度</title>
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
<!-- 未取回单笔现金支出额度——管理员 -->
<%if (!Request.IsAuthenticated)
  {%>
<script type="text/javascript">
    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
        parent.location.replace('index.aspx');
    });
</script>
<%} %>
<script type="text/javascript">
    
    //查询功能
    var searchGrid = function () {
        singleCashGrid.datagrid('load', $.serializeObject($('#searchForm')));
    };
    //重置查询
    var resetGrid = function () {
        $('#searchForm input').val('');
        singleCashGrid.datagrid('load', {});
    };
    //单笔现金
    var singleCashGrid;
    $(function () {
        //单笔现金
        singleCashGrid = $('#singleCashGrid').datagrid({
            title: '未取回单笔现金明细',
            url: '../service/DataStatistics.ashx/GetUnRetrieveSingleOutlay',
            striped: true,
            rownumbers: true,
            pagination: true,
            showFooter: true,
            pageSize: 10,
            singleSelect: true,
            idField: 'id',
            sortName: 'aa.deptid',
            sortOrder: 'asc',
            columns: [
              [{
                  width: '120',
                  title: '单位名称',
                  field: 'deptname',
                  halign: 'center',
                  align: 'center'
              },  {
                  width: '80',
                  title: '经费类别',
                  field: 'outlaytype',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '100',
                  title: '额度编号',
                  field: 'outlayid',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value) {
                      if (value == 0)
                          return '';
                      else
                          return value;
                  }
              }, {
                  width: '150',
                  title: '办理编号',
                  field: 'reimburseno',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '120',
                  title: '待取回金额',
                  field: 'singleoutlay',
                  halign: 'center',
                  align: 'center'
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
            }
        });
        //设置分页属性
        var pager = $('#singleCashGrid').datagrid('getPager');
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
                            <input name="deptId" id="deptId" style="width: 230px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 230,
                    panelHeight: '180',
                    editable:true,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                        </td>
                        <td style="padding-left: 20px;">
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:false"
                                onclick="searchGrid();">查询</a><a  style="margin-left:10px;" href="javascript:void(0);" class="easyui-linkbutton"
                                data-options="iconCls:'ext-icon-magifier_zoom_out',plain:false" onclick="resetGrid();">
                                重置</a>

                        </td>
                    </tr>
                </table>
            </form>
        </div>
        <!--未取回单笔现金明细-->
        <table id="singleCashGrid" data-options="fit:false,border:false">
        </table>
    </div>
</body>
</html>
