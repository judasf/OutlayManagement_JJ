<%@ Page Language="C#" AutoEventWireup="true" CodeFile="index.aspx.cs" Inherits="index" %>

<!DOCTYPE html>
<html>
<head>
    <title>安阳市公安局交通管理支队</title>
    <link href="favicon.ico" rel="shortcut icon" />
    <%--引入ueditor文件--%>
    <script type="text/javascript" charset="utf-8">        window.UEDITOR_HOME_URL = 'js/ueditor/';</script>
    <script src="js/ueditor/ueditor.config.js" type="text/javascript" charset="utf-8"></script>
    <script src="js/ueditor/ueditor.all.min.js" type="text/javascript" charset="utf-8"></script>
    <script src="js/ueditor/lang/zh-cn/zh-cn.js" type="text/javascript" charset="utf-8"></script>
    <%--引入My97日期文件--%>
    <script src="js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <%--引入Jquery文件--%>
    <script src="js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="css/bootstrap.min.css" rel="stylesheet" type="text/css" />
    <%--引入uploadify文件--%>
    <link rel="stylesheet" type="text/css" href="js/uploadify/uploadify.css" />
    <script type="text/javascript" src="js/uploadify/jquery.uploadify.js"></script>
    <%--引入easyui文件--%>
    <link href="js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="js/extJquery.js" type="text/javascript"></script>
    <script src="js/extEasyUI.js" type="text/javascript"></script>
     <%--引入图片展示插件--%>
    <link href="js/ImgPopup/ImgPopup.css" rel="stylesheet" />
    <script src="js/ImgPopup/ImgPopup.min.js"></script>
     <%--打印插件--%>
    <script src="js/jquery.PrintArea.js"></script>
    <script type="text/javascript">
        var index_tabs; var index_tabsMenu;
        $(function () {
            //初始化导航菜单
            $.ajax({
                type: "post",
                dataType: "json",
                url: "service/FetchMenu.ashx",
                data: { method: "CreatMenu", userid: "1" }
            }).done(function (result) {
                //成功调用后处理返回结果
                if (result.flag === "0")
                    $.messager.alert("error", result.msg, "error");
                else {
                    //遍历json数据，生成结果
                    $('#navgation').empty();
                    var menuContent = "";
                    $.each(result.menus, function (i, _menus) {
                        menuContent += $.formatString('<div title="{0}" iconCls="{1}" style="overflow:auto;padding:10px;"><ul class="easyui-tree" >', _menus.menuname, _menus.icon);
                        $.each(_menus.menus, function (j, o) {
                            menuContent += $.formatString('<li data-options="iconCls:\'{0}\',attributes:{url:\'{1}\',iframeName:\'{2}\'}">{3}</li>', o.icon, o.url, o.iframename, o.menuname);
                        });
                        menuContent += "</ul></div>"
                    });
                    $('#navgation').append(menuContent).accordion();
                    //处理tree节点
                    $('.easyui-tree').tree({
                        onClick: function (node) {
                            $.messager.progress({
                                title: '提示',
                                text: '数据处理中，请稍后....'
                            });
                            addTab({
                                url: node.attributes.url,
                                title: node.text,
                                iconCls: node.iconCls,
                                iframeName: node.attributes.iframeName
                            });
                        }
                    });
                }
            }
            );
            //增加tab
            function addTab(params) {
                var iframe = '<iframe src="' + params.url + '" frameborder="0" style="border:0;width:100%;height:98%;" name="' + params.iframeName + '"></iframe>';
                var t = $('#index_tabs');
                var opts = {
                    title: params.title,
                    closable: true,
                    iconCls: params.iconCls,
                    content: iframe,
                    border: false,
                    fit: true
                };
                if (t.tabs('exists', opts.title)) {
                    t.tabs('select', opts.title);
                    $.messager.progress('close');
                } else {
                    t.tabs('add', opts);

                }
            }
            //初始化tabs
            index_tabs = $('#index_tabs').tabs({
                fit: true,
                border: false,
                onContextMenu: function (e, title) {
                    e.preventDefault();
                    index_tabsMenu.menu('show', {
                        left: e.pageX,
                        top: e.pageY
                    }).data('tabTitle', title);
                },
                tools: [{
                    text: '刷新',
                    iconCls: 'ext-icon-arrow_refresh',
                    handler: function () {
                        var panel = index_tabs.tabs('getSelected').panel('panel');
                        var frame = panel.find('iframe');
                        try {
                            if (frame.length > 0) {
                                for (var i = 0; i < frame.length; i++) {
                                    frame[i].contentWindow.document.write('');
                                    frame[i].contentWindow.close();
                                    frame[i].src = frame[i].src;
                                }
                                if (navigator.userAgent.indexOf("MSIE") > 0) {// IE特有回收内存方法
                                    try {
                                        CollectGarbage();
                                    } catch (e) {
                                    }
                                }
                            }
                        } catch (e) {
                        }
                    }
                }, {
                    text: '关闭',
                    iconCls: 'ext-icon-cross',
                    handler: function () {
                        var index = index_tabs.tabs('getTabIndex', index_tabs.tabs('getSelected'));
                        var tab = index_tabs.tabs('getTab', index);
                        if (tab.panel('options').closable) {
                            index_tabs.tabs('close', index);
                        } else {
                            $.messager.alert('提示', '[' + tab.panel('options').title + ']不可以被关闭！', 'error');
                        }
                    }
                }]
            });
            //tab右键菜单
            index_tabsMenu = $('#index_tabsMenu').menu({
                onClick: function (item) {
                    var curTabTitle = $(this).data('tabTitle');
                    var type = $(item.target).attr('title');

                    if (type === 'refresh') {
                        index_tabs.tabs('getTab', curTabTitle).panel('refresh');
                        return;
                    }

                    if (type === 'close') {
                        var t = index_tabs.tabs('getTab', curTabTitle);
                        if (t.panel('options').closable) {
                            index_tabs.tabs('close', curTabTitle);
                        }
                        return;
                    }

                    var allTabs = index_tabs.tabs('tabs');
                    var closeTabsTitle = [];

                    $.each(allTabs, function () {
                        var opt = $(this).panel('options');
                        if (opt.closable && opt.title != curTabTitle && type === 'closeOther') {
                            closeTabsTitle.push(opt.title);
                        } else if (opt.closable && type === 'closeAll') {
                            closeTabsTitle.push(opt.title);
                        }
                    });

                    for (var i = 0; i < closeTabsTitle.length; i++) {
                        index_tabs.tabs('close', closeTabsTitle[i]);
                    }
                }
            });
        });
        //修改密码
        var editCurrentUserPwd = function () {
            var dialog = parent.$.modalDialog({
                title: '修改密码',
                width: 340,
                height: 250,
                href: 'BaseInfo/DialogOP/UserPwd_OP.aspx',
                buttons: [{
                    text: '修改',
                    handler: function () {
                        parent.onFormSubmit(dialog);
                    }
                },
                {
                    text: '取消',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }]
            });
        };
        //退出登录
        var logOut = function () {
            $.ajax({
                type: "post",
                dataType: "json",
                url: "service/commondb.ashx/LogOut"
            }).done(function (result) {
                if (result.success) {
                    location.replace('index.aspx');
                }
            });
        };
    </script>
    <style type="text/css">
        .head a { color: #fff; text-decoration: none; }
    </style>
</head>
<body class="easyui-layout">
    <div region="north" split="true" border="false" style="overflow: hidden; height: 65px; background: #2076C3 url(css/images/headbg.png) repeat-x; line-height: 64px; color: #fff; font-family: Verdana, 微软雅黑,黑体">
        <span style="float: right; padding-right: 20px; font-size: 14px;" class="head">[<%
                                                                                            UserDetail ui = new UserDetail();

                                                                                            Response.Write(ui.LoginUser.UserName+"（"+ui.LoginUser.RoleName+"）");
                
        %>]，欢迎您！ <a href="javascript:void(0);" onclick="editCurrentUserPwd();">[修改密码]</a> <a
            href="javascript:void(0);" onclick="logOut();">[安全退出]</a> </span>
        <span style="background: url(css/images/logo.png) no-repeat left; width: 425px; height: 64px; float: left;"></span>

    </div>
    <div region="south" split="true" style="height: 30px; background: #D2E0F2;">
        <div style="text-align: center;">
            安阳市公安局交通管理支队
        </div>
    </div>
    <div region="west" split="true" title="模块导航" style="width: 180px;" id="west">
        <div id="navgation" data-options="fit:true,border:false">
        </div>
    </div>
    <div id="mainPanle" region="center" style="background: #eee; overflow-y: hidden">
        <div id="index_tabs">
            <div title="待办事项" style="overflow: hidden;" id="home">
                <iframe src="portal/Default.aspx" frameborder="0" style="border: 0; width: 100%; height: 98%;"></iframe>
            </div>
        </div>
    </div>
    <div id="formLogin" method="post" url="List.aspx" style="width: 300px; height: 200px;"
        title="用户登录">
        <table width="100%" style="line-height: 50px; border: red 1px;">
            <tr align="center">
                <td align="right">用户名：
                </td>
                <td align="left">
                    <input id="ipt_username" name="ipt_username" type="text" class="easyui-validatebox"
                        required="true" />
                </td>
            </tr>
            <tr align="center">
                <td align="right">密码：
                </td>
                <td align="left">
                    <input id="ipt_userpwd" name="ipt_userpwd" type="password" class="easyui-validatebox"
                        required="true" />
                </td>
            </tr>
        </table>
    </div>
    <!-- tab右键菜单 -->
    <div id="index_tabsMenu" style="width: 120px; display: none;">
        <div title="refresh" data-options="iconCls:'ext-icon-arrow_refresh'">
            刷新
        </div>
        <div class="menu-sep">
        </div>
        <div title="close" data-options="iconCls:'ext-icon-cross'">
            关闭
        </div>
        <div title="closeOther" data-options="iconCls:'ext-icon-cross'">
            关闭其他
        </div>
        <div title="closeAll" data-options="iconCls:'ext-icon-cross'">
            关闭所有
        </div>
    </div>
</body>
</html>
