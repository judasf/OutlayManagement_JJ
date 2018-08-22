<%@ Page Language="C#" %>

<% 
    /** 
     * 设置用户审批范围
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["uid"]) ? "" : Request.QueryString["uid"].ToString();
    string scopeDepts = string.IsNullOrEmpty(Request.QueryString["scopeDepts"]) ? "" : Request.QueryString["scopeDepts"].ToString();
    string roleName = string.IsNullOrEmpty(Request.QueryString["roleName"]) ? "" : Request.QueryString["roleName"].ToString();
%>
<script type="text/javascript">
    var onFormSubmit = function ($dialog, $grid) {
            var url = 'service/UserInfo.ashx/SetScopeDepts';
            var checknodes = deptTree.tree('getChecked');
            var ids = [];
            if (checknodes && checknodes.length > 0) {
                for (var i = 0; i < checknodes.length; i++) {
                    ids.push(checknodes[i].id);
                }
            $('#scopeDepts').val(ids);
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
    };

    var deptTree;
    $(function () {
        deptTree = $('#deptTree').tree({
            url: 'service/department.ashx/GetDeptTree',
            //            parentField: 'pid',
            //lines : true,
            checkbox: true,
            onClick: function (node) {
                node.checked ? deptTree.tree('uncheck', node.target) : deptTree.tree('check', node.target)
            },
            onLoadSuccess: function (node, data) {
                var scopeVal = $('#scopeDepts').val();
                if (scopeVal=="0")
                    checkAll();
                else {
                    var ids = $.stringToList(scopeVal);
                    if (ids.length > 0) {
                        for (var i = 0; i < ids.length; i++) {
                            if (deptTree.tree('find', ids[i])) {
                                deptTree.tree('check', deptTree.tree('find', ids[i]).target);
                            }
                        }
                    } 
                }
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
    <div data-options="region:'west'" title="[<%=roleName %>]角色可以审批的基层单位" style="width: 300px; padding: 1px;">
        <div class="well well-small">
            <form id="form" method="post">
            <input name="uid" type="hidden"  value="<%=id %>">
            <ul id="deptTree">
            </ul>
            <input id="scopeDepts" value="<%=scopeDepts %>" name="scopeDepts" type="hidden" />
            </form>
        </div>
    </div>
    <div data-options="region:'center'" title="" style="overflow: hidden; padding: 10px;">
        <div class="well well-small">
            <span class="label label-success">角色名称：<%=roleName%></span>
           
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
