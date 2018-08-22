<%@ Page Language="C#" %>

<% 
    /** 
     * 将报表报送给基层单位
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "0" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    var onSendReportFormSubmit = function ($dialog, $grid) {
        var url = 'service/ReportInfo.ashx/SendReportToDepts';
        var checknodes = deptTree.tree('getChecked');
        var ids = [];
        if (checknodes && checknodes.length > 0) {
            for (var i = 0; i < checknodes.length; i++) {
                ids.push(checknodes[i].id);
            }
            $('#receiveDepts').val(ids);
            parent.$.messager.confirm('询问', '您确定要报送该报表？', function (r) {
                if (r) {
                    $.post(url, $.serializeObject($('form')), function (result) {
                        if (result.success) {
                            $grid.datagrid('load');
                            $dialog.dialog('close');
                            parent.$.messager.alert('提示', result.msg, 'info');
                        } else {
                            parent.$.messager.alert('提示', result.msg, 'error');
                        }
                    }, 'json');
                }
            });
        }
        else {
            parent.$.messager.alert('提示', '请选择要接收报表的单位', 'info');
            return;
        }
    };

    var deptTree;
    $(function () {
        deptTree = $('#deptTree').tree({
            url: 'service/department.ashx/GetDeptTreebyUID',
            checkbox: true,
            onClick: function (node) {
                node.checked ? deptTree.tree('uncheck', node.target) : deptTree.tree('check', node.target)
            },
            onLoadSuccess: function (node, data) {
                //                var scopeVal = $('#scopeDepts').val();
                //                if (scopeVal == "0")
                checkAll();
                //                else {
                //                    var ids = $.stringToList(scopeVal);
                //                    if (ids.length > 0) {
                //                        for (var i = 0; i < ids.length; i++) {
                //                            if (deptTree.tree('find', ids[i])) {
                //                                deptTree.tree('check', deptTree.tree('find', ids[i]).target);
                //                            }
                //                        }
                //                    }
                //                }
                parent.$.messager.progress('close');
            },
            cascadeCheck: false
        });
    });

    function checkAll() {
        var nodes = deptTree.tree('getChecked', 'unchecked');
        if (nodes && nodes.length > 0) {
            for (var i = 0; i < nodes.length; i++) {
                deptTree.tree('check', nodes[i].target);
            }
        }
    }
    function uncheckAll() {
        var nodes = deptTree.tree('getChecked');
        if (nodes && nodes.length > 0) {
            for (var i = 0; i < nodes.length; i++) {
                deptTree.tree('uncheck', nodes[i].target);
            }
        }
    }
    function checkInverse() {
        var unchecknodes = deptTree.tree('getChecked', 'unchecked');
        var checknodes = deptTree.tree('getChecked');
        if (unchecknodes && unchecknodes.length > 0) {
            for (var i = 0; i < unchecknodes.length; i++) {
                deptTree.tree('check', unchecknodes[i].target);
            }
        }
        if (checknodes && checknodes.length > 0) {
            for (var i = 0; i < checknodes.length; i++) {
                deptTree.tree('uncheck', checknodes[i].target);
            }
        }
    }
</script>
<div id="scopeDeptsLayout" class="easyui-layout" data-options="fit:true,border:false">
    <div data-options="region:'west'" title="可以接收报表的基层单位" style="width: 200px; padding: 1px;">
        <div class="well well-small">
            <form id="form" method="post">
            <input name="id" type="hidden" value="<%=id %>" />
            <input name="receiveDepts" id="receiveDepts" type="hidden" />
            <ul id="deptTree">
            </ul>
            </form>
        </div>
    </div>
    <div data-options="region:'center'" title="" style="overflow: hidden; padding: 10px;">
        <div class="well well-small">
            <span class="label label-success">用户名：<% UserDetail ui = new UserDetail();

                                                     Response.Write(ui.LoginUser.UserName);%></span>
        </div>
        <div class="well well-large">
            <button class="btn btn-success" onclick="checkAll();">
                全选</button>
            <br />
            <br />
            <button class="btn btn-warning" onclick="checkInverse();">
                反选</button>
            <br />
            <br />
            <button class="btn btn-inverse" onclick="uncheckAll();">
                取消</button>
        </div>
    </div>
</div>
