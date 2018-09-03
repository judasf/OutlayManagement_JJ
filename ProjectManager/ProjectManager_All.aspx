<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <title>项目申报表</title>
    <script src="../js/My97DatePicker/WdatePicker.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="../js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="../js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="../js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <link href="../css/extEasyUIIcon.css" rel="stylesheet" type="text/css" />
    <script src="../js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <script src="../js/extJquery.js" type="text/javascript"></script>
    <script src="../js/extEasyUI.js" type="text/javascript"></script>

    <!-- 项目管理 -->
    <%  //roleid  
        int roleid = 0;
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
            //获取项目状态
    %>
    <script type="text/javascript">
        var roleid = '<%=roleid%>';
    </script>
    <%} %>
    <script type="text/javascript">
        var adminAuditFun = function (id) {
            /// <summary>申请审核</summary>
            var dialog = parent.$.modalDialog({
                title: '费用审核',
                width: 800,
                height: 600,
                iconCls: 'ext-icon-page',
                href: 'ProjectManager/dialogop/AuditProjectInfo_op.aspx?id=' + id,
                buttons: [{
                    text: '提交',
                    handler: function () {
                        parent.onFormSubmit(dialog, pjGrid);
                    }
                },
                {
                    text: '关闭',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }
                ]
            });
        };
        //添加项目申报
        var addFun = function (id) {
            var dialog = parent.$.modalDialog({
                title: '项目申报',
                width: 1000,
                height: 600,
                iconCls: 'icon-add',
                href: 'ProjectManager/dialogop/ProjectManager_OP.aspx',
                buttons: [{
                    text: '提交',
                    handler: function () {
                        parent.onFormSubmit(dialog, pjGrid);
                    }
                }, {
                    text: '关闭',
                    handler: function () {
                        dialog.dialog('close');
                    }
                }]
            });
        };
        //显示费用申请信息详情
        var viewProjectDetail = function (id, status) {
            var btns = [{
                text: '关闭',
                handler: function () {
                    dialog.dialog('close');
                }
            }];
            //已完结的可打印
            if (status == 5)
                btns.unshift({
                    text: '打印',
                    handler: function () {
                        parent.print(dialog, pjGrid);
                    }
                })
            var dialog = parent.$.modalDialog({
                title: '项目申报表详情',
                width: 800,
                height: 600,
                iconCls: 'icon-print',
                href: 'ProjectManager/dialogop/PrintProjectInfoDetail_op.aspx?id=' + id,
                buttons: btns
            });
        };
        //项目申请明细表
        var pjGrid;
        $(function () {
            var url = '../service/ProjectManager.ashx/GetProjectInfo';
            pjGrid = $('#pjGrid').datagrid({
                title: '项目申报明细表',
                url: url,
                striped: true,
                rownumbers: true,
                pagination: true,
                noheader: true,
                fit: false,
                border: false,
                showFooter: true,
                pageSize: 20,
                singleSelect: true,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                columns: [[{
                    title: '操作',
                    field: 'action',
                    width: '80',
                    halign: 'center',
                    align: 'center',
                    formatter: function (value, row) {
                        var str = '';
                        if (row.status >= 1 &&row.status <= 4 && roleid == 6) {//项目审批:管理员项目审批功能
                            str += $.formatString('<a href="javascript:void(0)" onclick="adminAuditFun(\'{0}\');">项目审批</a>', row.id);
                        }
                        if (row.status == 5 && roleid == 6) { //已完结申请可打印
                            str += $.formatString('<a href="javascript:void(0)" onclick="viewProjectDetail(\'{0}\',\'{1}\');">打印申请表</a>', row.id, row.status);
                        }
                        if (row.status <=0 && roleid == 6) { //被退回和未提交查看详情
                            str += $.formatString('<a href="javascript:void(0)" onclick="viewProjectDetail(\'{0}\',\'{1}\');">查看详情</a>', row.id, row.status);
                        }
                        return str;
                    }
                }
                ,
                   {
                       width: '120',
                       title: '项目编号',
                       field: 'pjno',
                       halign: 'center',
                       align: 'center'
                   }, {
                       width: '120',
                       title: '当前进度',
                       field: 'status',
                       halign: 'center',
                       align: 'center',
                       formatter: function (value, row, index) {
                           switch (value) {
                               case '-1':
                                   return '已退回'
                                   break;
                               case '0':
                                   return '待送审'
                                   break;
                               case '1':
                                   return '部门负责人审核中'
                                   break;
                               case '2':
                                   return '部门主管领导审批中'
                                   break;
                               case '3':
                                   return '行财部门审核中'
                                   break;
                               case '4':
                                   return '行财领导审批中'
                                   break;
                               case '5':
                                   return '审批完结'
                                   break;
                           }
                       }
                   }, {
                       width: '120',
                       title: '申报部门',
                       field: 'deptname',
                       halign: 'center',
                       align: 'center'
                   }, {
                       width: '120',
                       title: '联系人',
                       field: 'linkman',
                       halign: 'center',
                       align: 'center'
                   }, {
                       width: '120',
                       title: '联系电话',
                       field: 'linkmantel',
                       halign: 'center',
                       align: 'center'
                   }, {
                       width: '120',
                       title: '申报时间',
                       field: 'applytime',
                       halign: 'center',
                       align: 'center'
                   }, {
                       width: '340',
                       title: '申报内容',
                       field: 'projectcontent',
                       halign: 'center',
                       align: 'center'
                   }
                ]],
                toolbar: '#agTip',
                onLoadSuccess: function (data) {
                    parent.$.messager.progress('close');
                    if (data.rows.length == 0) {
                        var body = $(this).data().datagrid.dc.body2;
                        body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                    }
                    //提示框
                    $(this).datagrid('tooltip', ['projectcontent']);
                    //取消全选
                    $(this).datagrid('unselectAll');
                    if (roleid != 6)
                        $(this).datagrid('hideColumn', 'action');
                },
                onDblClickRow: function (index, row) {
                    viewProjectDetail(row.id, row.status);
                }
            });
            //设置分页属性
            var pager = $('#pjGrid').datagrid('getPager');
            pager.pagination({
                layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
            });

        });
    </script>
</head>
<body class="easyui-layout">
    <div data-options="region:'center',fit:true,border:false">
        <div id="agTip">
            <form id="pasearchForm" style="margin: 0;">
                <table>
                    <tr>
                        <td width="80" align="right">申请时间：
                        </td>
                        <td>
                            <input style="width: 95px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')}',maxDate:'%y-%M-%d'})"
                                readonly="readonly" />-<input style="width: 95px;" name="edate" id="edate" class="Wdate"
                                    onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                        </td>
                        <td width="120" align="right">项目申请编号：
                        </td>
                        <td>
                            <input style="width: 120px; height: 20px" type="text" class="combo" name="pjno" />
                        </td>
                        <%if (roleid != 1 && roleid != 8 && roleid != 9)
                            { %>
                        <td width="80" align="right">申请部门：
                        </td>
                        <td>
                            <input name="deptId" id="deptId" style="width: 100px;" class="easyui-combobox" data-options="
                    valueField: 'id',
                    textField: 'text',
                    panelWidth: 100,
                    panelHeight: '180',
                    editable:false,
                    url: '../service/Department.ashx/GetScopeDeptsCombobox'" />
                        </td>
                        <%} %>
                    </tr>
                    <tr>
                        <td width="80" align="right">当前进度：
                        </td>
                        <td>
                            <input id="status" class="easyui-combobox" name="status" style="width: 120px"
                                data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'','text':'全部'},{'value':'-1','text':'已退回'},{'value':'1','text':'部门负责人审核中'},{'value':'2','text':'部门主管领导审批中'},{'value':'3','text':'行财部门审核中'},{'value':'4','text':'行财主管领导审批中'},{'value':'5','text':'已完结'}]" />
                        </td>
                        <td colspan="6" style="padding-left: 30px;">
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                                onclick="pjGrid.datagrid('load', $.serializeObject($('#pasearchForm')));">查询</a>
                            <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                                onclick="  $('#pasearchForm input').val('');pjGrid.datagrid('load', {});">重置</a>
                            <%--<a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                                onclick="exportAccountReimburse();">导出</a>--%>
                            <%if (roleid == 1)
                                { %>
                            <a href="javascript:void(0);" class="easyui-linkbutton"
                                onclick="addFun();" data-options="iconCls:'ext-icon-note_add',plain:true">项目申报</a>
                            <%} %>
                        </td>
                    </tr>
                </table>
            </form>
            <div style="background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAolJREFUeNp8U81PE1EQn7df3XZbQE2tlAQaKJWiiegBJH6EoyboSePJk4me/Dh68Wb8B0zUE4kXLiYSSRo5oDbQkBATCrVGcbVAAwixlO2H7e727a6zYCvoxkl+mdl58/vNm7fvEcuywLbYHXbHE4IAOIHhSVw5hMsEfR59khqQNHbL4cpTY8dzsN+QCxe9bT2nwxdu9UsdoYCmrlvF5UxuafJlpLi21I7r4wirTmDqgYkp7HLK29Z7ZuDuyPXm8LEIENOt6t95vWm1s+/m/Wvetu5zhgn9NeNPx30CuL2ByKXbg4ZZYUxTrxHCAcuKQKlCt5VZODp8ox/HOI8iDWuMQHeTgeaO7nZKSypqW5QWTE3bBNOsERQ0WkJdQewetMBJYHdbrKbljJ+VL5QQZodcLn/lWFZgeL6FgMVSFOD+J7CxOj+9JIXYaLm8WLU7M4yLcbmCRJI6hbWF5IpukHXLcjgDewTEm9TYqCyJxzVB8POi2MpKUhcjSWFWYDu0xOiTrEYhpjsdom2o/KmsKFMzI89mA4Fht88XZTyeEOPz9bomHj9aUPL5t1iT2stpCBRVAiWNAHYYW/6QzGbn0t8E4TDPcV5Onn2/nEnNZXUKo9UaQEV3EFBrDVDc4sTH6cl1JNsCfHpqcgNzr/AA7UMEx3vwOm1BFZVtqDqkMul5kRCW4F0gmfSCG0nzdfLzGfPfv/Dus4kAuHo2AH6/vzC9SGJ9CfdlWZbh4bi2MthpKXZdQjb33f2/3wK8SGzC0FAUoy2IRntA1wVwIjr9BTsWEQfi8fgRO5HL5aBQ+FFfb0UcRHj28kj9OeOw9nv2/S5qwm8v+geIINbcQ59HlBDbiALmqM37JcAABIc4sUmmya4AAAAASUVORK5CYII=') no-repeat 10px 5px; line-height: 24px; padding-left: 30px;">
                双击查看项目详情！
            </div>
        </div>
        <table id="pjGrid">
        </table>
    </div>
</body>
</html>
