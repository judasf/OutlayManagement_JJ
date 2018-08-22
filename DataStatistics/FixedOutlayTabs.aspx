<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>额度修正</title>
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
    //管理员：经费额度修正tabs，包括公用经费和专项经费额度
    $(function () {
        var adTabs = $('#fixedTabs').tabs({
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
    <div data-options="region:'center',fit:true,border:false">
        <div id="fixedTabs">
            <div title="公用经费修正" style="overflow: hidden;" href="FixedPublicOutlay.aspx">
            </div>
            <div title="专项经费修正" style="overflow: hidden;" href="FixedSpecialOutlay.aspx">
            </div>
        </div>
    </div>
</body>
</html>
