<%@ Page Language="C#" %>

<% 
    /** 
     * categroy表操作对话框
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["cid"]) ? "" : Request.QueryString["cid"].ToString();
    string level = string.IsNullOrEmpty(Request.QueryString["level"]) ? "" : Request.QueryString["level"].ToString();
%>
<script type="text/javascript">

    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#cid').val().length == 0) {
                url = 'service/category.ashx/SaveCategory';
            } else {
                url = 'service/category.ashx/UpdateCategory';
            }
            $.post(url, $.serializeObject($('form')), function (result) {
                if (result.success) {
                    $grid.treegrid('load');
                    $dialog.dialog('close');
                } else {
                    parent.$.messager.alert('提示', result.msg, 'error');
                }
            }, 'json');
        }
    };
    $(function () {
        //加载上级目录树
        var loadCombotree = function (url) {
            $('#pid').combotree({
                valueField: 'id',
                textField: 'text',
                editable: false,
                panelHeight: 'auto',
                url: url,
                onLoadSuccess: function (node, data) {
                    if (!data) {
                        $(this).combotree({ readonly: true });
                    }
                },
                //选择上级目录是设定newLevel的值
                onSelect: function (node) {
                    $('#clevel').val(node.level);
                }
            });
        };
        if ($('#cid').val().length > 0) {
            //修改时只加载自己上层的目录树
            loadCombotree('service/category.ashx/GetCategoryByLevel?clevel=' + $('#clevel').val());
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/category.ashx/GetCategoryByID', {
                cid: $('#cid').val()
            }, function (result) {
                //顶层经费类别不显示上级经费类别选项
                if (result.rows[0].pid == 0)
                    $('#pidTr').hide();
                $('form').form('load', {
                    'cid': result.rows[0].cid,
                    'cname': result.rows[0].cname,
                    'clevel': result.rows[0].clevel,
                    'pid': (result.rows[0].pid == 0) ? '' : result.rows[0].pid
                });
                parent.$.messager.progress('close');
            }, 'json');
        }
        else
        //添加时加载全部目录树
            loadCombotree('service/category.ashx/GetCategory');
    });
</script>
<form method="post">
<table class="table table-bordered  table-hover">
    <tr>
        <td style="text-align: right">
            经费类别名称：
        </td>
        <td style="width: 200px">
            <input type="hidden" id="cid" name="cid" value="<%=id %>" />
            <input id="cname" type="text" name="cname" class="easyui-validatebox " required />
        </td>
    </tr>
    <tr id="pidTr">
        <td style="text-align: right">
            上级经费类别：
        </td>
        <td>
            <input type="hidden" id="clevel" name="clevel" value="<%=level %>" />
            <input id="pid" type="text" name="pid" />
        </td>
    </tr>
</table>
</form>
