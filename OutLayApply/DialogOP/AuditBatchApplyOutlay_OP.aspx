<%@ Page Language="C#" %>

<% 
    /** 
     *AuditOutlayApplyDetail表操作对话框，稽核批量追加经费申请
     * 
     */
%>
<script type="text/javascript">
    //得到重复值
    var getRepeatNum = function (arr) {
        var res = [];
        var ary = arr.sort();
        for (var i = 0; i < ary.length;) {
            var count = 0;
            for (var j = i; j < ary.length; j++) {
                if (ary[i] == ary[j])
                    count++;
            }
            res.push(count);
            i += count;
        }
        return res;
    };
    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            parent.$.messager.confirm('询问', '您确定要提交经费追加申请？', function (r) {
                if (r) {
                    var url = 'service/AuditApplyOutlayAllocate.ashx/SaveAuditBatchApplyOutlayDetail';
                    //要post的json数据
                    var postDate = {};
                    //有数据的行编号
                    var rowsNum = 0;
                    // 选择的部门编号数组，用来检测是否重复选择同一部门
                    var deptidArr = [];
                    var repeatDeptIDArr = [];
                    //遍历每一行表格
                    $.each($('tr', '#applyList'), function (index) {
                        ////剔除标题行
                        //if (index > 0) {
                            //获取部门编号的值
                        var deptid = $('input[name="deptId"]', this).val();
                            //剔除部门编号为空的行数据
                            if (deptid != undefined && deptid.trim().length > 0) {
                                //插入部门编号数组
                                deptidArr.push(deptid);
                                rowsNum++;
                                //遍历每一行要提交的数据
                                $.each($(':input', this).serializeArray(), function (i) {
                                    //设置要提交的键/值对
                                    postDate[this['name'] + rowsNum] = this['value'];
                                });
                            }
                        //}
                    })
                    //插入总数据行数
                    postDate['rowsCount'] = rowsNum;
                    //插入经费类别
                    postDate['outlayCategory'] = $('#outlayCategory').combo('getValue');
                    //插入标题
                    postDate['title'] = $('#title').val();
                    //插入经费用途
                    postDate['usefor'] = $('#usefor').val();
                    //判断是否重复选择同一部门
                    repeatDeptIDArr = getRepeatNum(deptidArr);
                    var canSubmit = true;
                    $.each(repeatDeptIDArr, function (i, n) {
                        if (n > 1) {
                            parent.$.messager.alert('提示', '请不要选择重复的部门！', 'error');
                            canSubmit = false;
                            return false;
                        }
                    });
                    if (canSubmit) {
                        parent.$.messager.progress({
                            title: '提示',
                            text: '数据提交中，请稍后....'
                        });
                        $.post(url, postDate, function (result) {
                            parent.$.messager.progress('close');
                            if (result.success) {
                                $.messager.show({
                                    title: '提示',
                                    msg: result.msg,
                                    showType: 'slide',
                                    timeout: '2000',
                                    style: {
                                        top: document.body.scrollTop + document.documentElement.scrollTop
                                    }
                                });
                                $grid.datagrid('reload');
                                $grid.datagrid('unselectAll');
                                $dialog.dialog('close');
                            } else {
                                parent.$.messager.alert('提示', result.msg, 'error');
                            }
                        }, 'json');
                    }
                }
            });
        }
    };
    //增加列表项
    var addList = function () {
        var index = $('#index').val();
        index++;
        var insertEle = $('<tr><td style="text-align: right;width: 60px">追加单位：</td><td><input type="hidden" name="deptName" id="deptName' + index + '" /><input name="deptId" style="width: 200px;" class="easyui-combobox" data-options="valueField: \'id\',textField: \'text\',required: true,panelWidth: 200,panelHeight: \'180\',editable: false,url: \'service/Department.ashx/GetScopeDeptsCombobox\',onSelect: function (rec) { $(\'#deptName' + index + '\').val(rec.text);}" /> </td><td style="text-align: right;">申请额度：</td><td><input name="applyOutlay"  class="easyui-numberbox" style="width: 150px;" data-options="min:0,precision:2,required:true" /><img src="../../js/easyui/themes/icons/edit_remove.png" onclick="delList(this);" style="margin-left:30px" /></td></tr>').appendTo($('form').find('table'));
        $('#index').val(index);
        $.parser.parse(insertEle);
    };
    //删除列表项
    var delList = function (obj) {
        $(obj).parent().parent().remove();
    };
    $(function () {
        //初始化经费类别树
        $('#outlayCategory').combotree({
            valueField: 'id',
            textField: 'text',
            editable: false,
            required: true,
            lines: true,
            panelHeight: 'auto',
            url: 'service/category.ashx/GetCategory',
            onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            }
        });
    });
   
</script>
<form method="post">
     <input type="hidden" id="index" value="1">
<table class="table table-bordered  table-hover" id="applyList">
    <tr>
        <td style="text-align: right;width: 60px">
            经费类别：
        </td>
        <td>
            <input name="outlayCategory" id="outlayCategory"style="width: 160px;" />
        </td>
         <td style="text-align: right;width:60px">
            标题：
        </td>
        <td>
            <input id="title" name="title" class="easyui-validatebox " style="width: 200px;"
                required />
        </td>
    </tr>
     <tr>
        <td style="text-align: right">
            经费用途：
        </td>
        <td colspan="3">
            <textarea name="usefor" style="width: 490px;" id="usefor" rows="2" class="easyui-validatebox"
                data-options="required:true"></textarea>
        </td>
    </tr>
    <tr>
        <td style="text-align: right; width: 60px">
            追加单位：
        </td>
        <td >
            <input type="hidden" name="deptName" id="deptName1" />
            <input name="deptId" style="width: 200px;" class="easyui-combobox" data-options=" valueField: 'id',
            textField: 'text',
            required: true,
            panelWidth: 200,
            panelHeight: '180',
            editable: false,
            url: 'service/Department.ashx/GetScopeDeptsCombobox',
            onSelect: function (rec) {
                $('#deptName1').val(rec.text);}" />
        </td>
  
        <td style="text-align: right;">
            申请额度：
        </td>
        <td>
            <input name="applyOutlay"  class="easyui-numberbox" style="width: 150px;" data-options="min:0,precision:2,required:true" /><img src="../../js/easyui/themes/icons/edit_add.png" onclick="addList();" style="margin-left:30px" />
        </td>
    </tr>
   
    
   
</table>
</form>
