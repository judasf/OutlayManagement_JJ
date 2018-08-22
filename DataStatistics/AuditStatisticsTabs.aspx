<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>数据统计</title>
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
<script type="text/javascript">
    //稽核：数据统计tabs，包括经费收支余额总表和经费收支分类统计表
    $(function () {
        var adTabs = $('#auditTabs').tabs({
            fit: true,
            border: false,
            tools: [{
                text: '刷新',
                iconCls: 'ext-icon-arrow_refresh',
                handler: function () {
                    var href = adTabs.tabs('getSelected').panel('options').href;
                    if (href) {/*说明tab是以href方式引入的目标页面*/
                        var index = adTabs.tabs('getTabIndex', adTabs.tabs('getSelected'));
                        adTabs.tabs('getTab', index).panel('refresh');
                    }
                }
            }]
        });
    });
</script>
<body class="easyui-layout">
    <!--追加经费明细包括基层用户申请的和稽核直接追加的 -->
    <div data-options="region:'center',fit:true,border:false">
        <div id="auditTabs">
            <div title="单位经费收支余额总表" style="overflow: hidden;" href="Audit_DeptAllOutlayStatistics.aspx">
            </div>
            <div title="单位经费收支分类统计表" style="overflow: hidden;" href="Audit_DeptOutlayTypeStatistics.aspx">
            </div>
        </div>
    </div>
</body>
</html>
