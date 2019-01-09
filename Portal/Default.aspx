<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>待办事项</title>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>
    <%--引入portal--%>
    <link rel="stylesheet" type="text/css" href="../js/easyui/portal/portal.css" />
    <script type="text/javascript" src="../js/easyui/portal/jquery.portal.js"></script>
    <style type="text/css">
        ul { list-style: none; margin: 0; padding: 8px 10px; }
        ul li { font-size: 13px; line-height: 23px; white-space: nowrap; overflow: hidden; background: url(../css/images/bluedot.gif) 0px 10px no-repeat; padding-left: 8px; border-bottom: 1px solid #eee; }
        ul li a { cursor: pointer; }
        ul li span { margin-left: 10px; color: #3366CC; }
    </style>
    <%  int roleid = 0;
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
            roleid = ud.LoginUser.RoleId;
    %>
    <script type="text/javascript">
        var roleid=<%=roleid%>;
    </script>
    <%} %>
    <script type="text/javascript">
        var portalLayout;
        var portal;
        //要添加的panels
        var panels;
        var state = '1';
        $(function () {
            portalLayout = $('#portalLayout').layout({
                fit: true
            });
            $(window).resize(function () {
                portalLayout.layout('panel', 'center').panel('resize', {
                    width: 1,
                    height: 1
                });
            });

            //定义panels的title数组和herf数组,排列状态state

            var panelsTitle;
            var panelsHref;

            //赋值
            switch (roleid) {
                case 1: //基层用户,
                case 8: //部门负责人
                case 9://部门主管领导
                    panelsTitle = ['经费审批', '报表统计'];
                    panelsHref = ['BaseUser/OutlayInfo.aspx', 'BaseUser/ReportAndNotice.aspx'];
                    break;
                case 2: //稽核员
                    panelsTitle = ['经费审批', '报表统计'];
                    panelsHref = ['Auditor/OutlayAudit.aspx', 'Auditor/ReportAndNotice.aspx'];
                    break;
                case 3: //出纳员
                case 6: //管理员
                case 7://浏览用户
                    panelsTitle = '意见信箱';
                    panelsHref = 'Director/UnReadNotice.aspx';
                    break;
                case 4: //处长
                case 10: //财务主管领导
                    panelsTitle = ['经费审批', '意见信箱'];
                    panelsHref = ['Director/OutlayApprove.aspx', 'Director/UnReadNotice.aspx'];
                    break;
                case 5://统计员
                    panelsTitle = '报表统计';
                    panelsHref = 'Auditor/ReportAndNotice.aspx';
                    break;
            }
            //两行
            if (roleid == 1 || roleid == 2 || roleid == 4|| roleid == 8|| roleid == 9|| roleid == 10) {
                panels = [{ id: 'p1', title: panelsTitle[0], height: 290, href: panelsHref[0],
                    tools: [{ iconCls: 'ext-icon-arrow_refresh', handler: function () { $('#p1').panel('refresh'); } }]
                },
           { id: 'p2', title: panelsTitle[1], height: 290, href: panelsHref[1],
               tools: [{ iconCls: 'ext-icon-arrow_refresh', handler: function () { $('#p2').panel('refresh'); } }]
           }
                ];
                state = 'p1,p2';
            }
            else {//一行
                panels = [{ id: 'p2', title: panelsTitle, href: panelsHref,
                    tools: [{ iconCls: 'ext-icon-arrow_refresh', handler: function () { $('#p2').panel('refresh'); } }]
                }];
                state = 'p2';
            }


            portal = $('#portal').portal({
                border: false,
                fit: true
            });
            //根据panel的状态添加portal

            addPortalPanels(state);
            portal.portal('resize');
        });

        function getPanelOptions(id) {
            for (var i = 0; i < panels.length; i++) {
                if (panels[i].id == id) {
                    return panels[i];
                }
            }
            return undefined;
        }
        function addPortalPanels(portalState) {
            var columns = portalState.split(':');
            for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
                var cc = columns[columnIndex].split(',');
                for (var j = 0; j < cc.length; j++) {
                    var options = getPanelOptions(cc[j]);
                    if (options) {
                        var p = $('<div/>').attr('id', options.id).appendTo('body');
                        p.panel(options);
                        portal.portal('add', {
                            panel: p,
                            columnIndex: columnIndex
                        });
                        portal.portal('disableDragging', p);
                    }
                }
            }
        }
    </script>
</head>
<body>
    <div id="portalLayout">
        <div data-options="region:'center',border:false">
            <div id="portal" style="position: relative">
                <div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
