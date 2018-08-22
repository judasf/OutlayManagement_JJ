<%@ Page Language="C#" %>

<% 
    /** 
     * DeptLevelInfo部门公用经费标准表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request["id"]) ? "" : Request["id"].ToString();
%>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {

        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/DeptOutlay.ashx/SaveDeptOutlay';
            } else {
                url = 'service/DeptOutlay.ashx/UpdateDeptOutlay';
            }
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $grid.datagrid('load');
                    $dialog.dialog('close');
                } else {
                    parent.$.messager.alert('提示', result.msg, 'error');
                }
            }, 'json');
        }
    };
    $(function () {
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/DeptOutlay.ashx/GetDeptOutlayByID', {
                id: $('#id').val()
            }, function (result) {
                if (result.rows[0].levelid != undefined) {
                    $('form').form('load', {
                        'deptId': result.rows[0].deptid,
                        'deptLevelId': result.rows[0].levelid,
                        'deptPeopleNum': result.rows[0].deptpeoplenum
                    });
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
        $('#deptLevelId').combogrid({
            url: 'service/OutlayLevel.ashx/getOutlayLevelInfo',
            panelWidth: 280,
            panelHeight: 200,
            idField: 'levelid',
            textField: 'levelname',
            editable: false,
            pagination: true,
            fitColumns: true,
            required: true,
            rownumbers: true,
            mode: 'remote',
            delay: 500,
            sortName: 'levelid',
            sortOrder: 'asc',
            pageSize: 5,
            pageList: [5, 10],
            columns: [[{
                field: 'levelname',
                title: '公用经费标准名称',
                width: 120,
                sortable: true
            }, {
                field: 'leveloutlay',
                title: '公用经费标准金额',
                width: 140,
                sortable: true
            }]]
        });
        var g = $('#deptLevelId').combogrid('grid');
        g.datagrid('getPager').pagination({ layout: ['first', 'prev','links', 'next', 'last'] });
    });
</script>
<form method="post">
<table class="table table-bordered  table-hover">
    <tr>
        <td style="text-align:right">
            单位名称：
        </td>
        <td style="width: 200px">
            <input type="hidden" id="id" name="id" value="<%=id %>" />
             <input id="deptId" type="text" name="deptId"  class="easyui-combobox" data-options=" required: true,
                    valueField: 'id',
                    textField: 'text',
                    editable: false,
                    <%=(id!="")?"disabled:true,":"" %>
                    panelHeight: 200,
                    mode: 'local',
                    url: 'service/Department.ashx/GetDepartmentCombobox'" />
        </td>
    </tr>
    <tr>
        <td style="text-align:right">
            单位人数：
        </td>
        <td valign="middle" style="width: 100px">
            <input id="deptPeopleNum" type="text" name="deptPeopleNum" class="easyui-numberbox "
                required data-options="min:0" />
        </td>
    </tr>
    <tr>
        <td style="text-align:right">
            公用经费标准：
        </td>
        <td valign="middle" style="width: 100px">
            <input id="deptLevelId" type="text" name="deptLevelId" />
        </td>
    </tr>
</table>
</form>
