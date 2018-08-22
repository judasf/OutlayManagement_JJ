<%@ Page Language="C#" AutoEventWireup="true" CodeFile="SpecialOutlayReimburse.aspx.cs"
    Inherits="OutlayReimburse_SpecialOutlayReimburse" %>

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
<script type="text/javascript">
    //专项经费报销的支出方式tabs
    var spTabs; //变量的作用域
    $(function () {
        spTabs = $('#specialTabs').tabs({
            fit: true,
            border: false,
            tools: [{
                text: '刷新',
                iconCls: 'ext-icon-arrow_refresh',
                handler: function () {
                    var href = spTabs.tabs('getSelected').panel('options').href;
                    if (href) {/*说明tab是以href方式引入的目标页面*/
                        var index = spTabs.tabs('getTabIndex', spTabs.tabs('getSelected'));
                        spTabs.tabs('getTab', index).panel('refresh');
                    }
                }
            }]
        });
    });
</script>
<body class="easyui-layout">
    <!-- 专项经费处理页面，通过href显示专项经费明细、现金支出明细、转账支出明细和公务卡支出明细 -->
    <div data-options="region:'center',fit:true,border:false">
        <div id="specialTabs">
            <div title="专项经费明细"  href="SpecialOutlayReimburse_OutlayDetail.aspx">
            </div>
            <div title="现金支出明细"  href="SpecialOutlayReimburse_CashPay.aspx">
            </div>
            <div title="转账支出明细" href="SpecialOutlayReimburse_AccountPay.aspx">
            转账支出明细
            </div>
            <div title="公务卡支出明细"  href="SpecialOutlayReimburse_CardPay.aspx">
            公务卡支出明细
            </div>
        </div>
    </div>
</body>
</html>
