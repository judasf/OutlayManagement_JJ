<%@ Page Language="C#" %>

<% 
    /** 
     *项目申报
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<!-- 项目管理 -->
<%  //roleid  
    string deptname;
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
        deptname = ud.LoginUser.UserDept;
%>
<script type="text/javascript">
    /// <summary>单位名称</summary>
    var deptname = '<%=deptname%>';
</script>
<%} %>
<script type="text/javascript">
    //提交表单
    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/ProjectManager.ashx/SaveProjectApplyInfo';
            } else {
                url = 'service/ProjectManager.ashx/UpdateProjectApplyInfo';
            }
            parent.$.messager.confirm('询问', '您确定提交该项目申报表？', function (r) {
                if (r) {
                    //要post的json数据
                    var postDate = {};
                    //有数据的行编号
                    var rowsNum = 0;
                    //遍历每一行表格
                    $.each($('tr', '#itemList'), function (index) {
                        //剔除标题行
                        if (index > 0) {
                            //获取采购项目名称
                            var purchasename = $('input[name="purchasename"]', this).val();
                            //剔除采购项目名称为空的行数据
                            if (purchasename != undefined && purchasename.trim().length > 0) {
                                rowsNum++;
                                //遍历每一行要提交的数据
                                $.each($(':input', this).serializeArray(), function (i) {
                                    //设置要提交的键/值对
                                    postDate[this['name'] + rowsNum] = this['value'];
                                });
                            }
                        }
                    })
                    //插入总数据行数
                    postDate['rowsCount'] = rowsNum;
                    //插入id
                    postDate['id'] = $('#id').val();
                    //插入项目编号
                    postDate['pjno'] = $('#pjno').val();
                    //插入申报部门
                    postDate['deptname'] = $('#deptname').val();
                    //联系人
                    postDate['linkman'] = $('#linkman').val();
                    //联系电话
                    postDate['linkmantel'] = $('#linkmantel').val();
                    //申报内容
                    postDate['projectcontent'] = $('#projectcontent').val();
                    var canSubmit = true;
                    if (canSubmit) {
                        parent.$.messager.progress({
                            title: '提示',
                            text: '数据提交中，请稍后....'
                        });
                        $.post(url, postDate, function (result) {
                            if (result.success) {
                                parent.$.messager.progress('close');
                                $grid.datagrid('reload');
                                $dialog.dialog('close');
                                //编辑成功后，刷新tab的内容，来更新全部申请
                                if (url == 'service/ProjectManager.ashx/UpdateProjectApplyInfo') {
                                    var panel = parent.index_tabs.tabs('getTab', 0).panel('panel');
                                    var frame = panel.find('iframe');
                                    frame[0].contentWindow.$('#feeGrid').datagrid('reload');
                                    //var panel = index_tabs.tabs('getTab', 0).panel('panel');
                                    //var frame = panel.find('iframe');
                                    //try {
                                    //    if (frame.length > 0) {
                                    //        for (var i = 0; i < frame.length; i++) {
                                    //            frame[i].contentWindow.document.write('');
                                    //            frame[i].contentWindow.close();
                                    //            frame[i].src = frame[i].src;
                                    //        }
                                    //        if (navigator.userAgent.indexOf("MSIE") > 0) {// IE特有回收内存方法
                                    //            try {
                                    //                CollectGarbage();
                                    //            } catch (e) {
                                    //            }
                                    //        }
                                    //    }
                                    //} catch (e) {
                                    //}

                                }
                            } else
                                parent.$.messager.alert('提示', result.msg, 'error');
                        }, 'json');
                    }
                }
            });
        }
    };
    //增加采购项目
    var addList = function () {
        var index = $('#index').val();
        index++;
        var insertEle = $(' <tr><td><input type="text" name="purchasename" class="easyui-validatebox span12" data-options="required:true"/></td><td><input type="text" name="units" class="easyui-validatebox span9" data-options="required:true"/></td><td><input type="text" name="number" class="easyui-validatebox span9" data-options="required:true"/></td><td><input type="text" name="price" id="price' + index + '" class="easyui-numberbox span11" data-options="precision:2,required:true" /></td><td><input type="text" name="budgetamount" id="budgetamount' + index + '" class="easyui-numberbox span11" data-options="precision:2,required:true" /></td><td><input type="text" name="techrequirement" class="span12" /></td><td style="text-align:center;"><img src="../js/easyui/themes/icons/edit_remove.png" onclick="delList(this);" style="cursor: pointer;" /></td></tr>').appendTo($('#itemList'));
        $('#index').val(index);
        $.parser.parse(insertEle);
    };

    //删除采购项目
    var delList = function (obj) {
        var index = $('#index').val();
        index--;
        $(obj).parent().parent().remove();
        $('#index').val(index);
    };
    //显示可编辑的采购项目信息
    var showEditItemList = function (pjno) {
        $.post('../service/ProjectManager.ashx/GetItemListByNoForList', { no: pjno }, function (nodeRes) {
            if (nodeRes.total > 0) {
                $('#index').val(nodeRes.total - 1);
                $.each(nodeRes.rows, function (i, item) {
                    if (i > 0) {
                        var editEle = $('<tr><td><input type="text" name="purchasename" class="easyui-validatebox span12" data-options="required:true"/></td><td><input type="text" name="units" class="easyui-validatebox span9" data-options="required:true"/></td><td><input type="text" name="number" class="easyui-validatebox span9" data-options="required:true"/></td><td><input type="text" name="price" id="price' + i + '" class="easyui-numberbox span11" data-options="precision:2,required:true" /></td><td><input type="text" name="budgetamount" id="budgetamount' + i + '" class="easyui-numberbox span11" data-options="precision:2,required:true" /></td><td><input type="text" name="techrequirement" class="span12" /></td><td style="text-align:center;"><img src="../js/easyui/themes/icons/edit_remove.png" onclick="delList(this);" style="cursor: pointer;" /></td></tr>').appendTo($('#itemList'));
                        $.parser.parse(editEle);
                        $('input[name="purchasename"]', editEle).val(item.purchasename);
                        $('input[name="units"]', editEle).val(item.units);
                        $('input[name="number"]', editEle).val(item.number);
                        $('#price' + i, editEle).numberbox('setValue', item.price);
                        $('#budgetamount' + i, editEle).numberbox('setValue', item.budgetamount);
                        $('input[name="techrequirement"]', editEle).val(item.techrequirement);
                    }
                    else {
                        $('input[name="purchasename"]').val(item.purchasename);
                        $('input[name="units"]').val(item.units);
                        $('input[name="number"]').val(item.number);
                        $('#price').numberbox('setValue', item.price);
                        $('#budgetamount').numberbox('setValue', item.budgetamount);
                        $('input[name="techrequirement"]').val(item.techrequirement);
                    }
                });
            }
        }, 'json');
    };
    $(function () {
        //初始化表单数据
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/ProjectManager.ashx/GetProjectApplyInfoById', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'pjno': result.rows[0].pjno,
                        'deptname': result.rows[0].deptname,
                        'linkman': result.rows[0].linkman,
                        'linkmantel': result.rows[0].linkmantel,
                        'projectcontent': result.rows[0].projectcontent
                    });
                    //显示可编辑的采购项目信息
                    showEditItemList(result.rows[0].pjno);
                }
                parent.$.messager.progress('close');
            }, 'json');
        }
        else {
            $('#deptname').val(deptname);
        }
    });
</script>
<style>
    #editBaseInfoForm table tr td {
        vertical-align: middle;
    }

        #editBaseInfoForm table tr td.text-right {
            text-align: right;
        }

        #editBaseInfoForm table tr td input, #baseInfoForm table tr td select {
            padding: 0 5px;
            line-height: 25px;
            height: 25px;
        }
</style>
<form method="post" id="editBaseInfoForm">

    <p style="font-size: 1.3em; text-align: center; line-height: 2.3em; font-weight: 700;">安阳市公安局交通管理支队自行采购项目申报表</p>
    <table class="table table-bordered  table-hover row-fluid">
        <tr>
            <td class="text-right">申报部门：</td>
            <td>
                <input type="hidden" id="id" name="id" value="<%=id %>" />
                <input type="hidden" id="pjno" name="pjno" />
                <input type="text" name="deptname" id="deptname" readonly class="easyui-validatebox span11" data-options="required:true" /></td>


            <td class="text-right">联系人：</td>
            <td>
                <input type="text" name="linkman" id="linkman" class="easyui-validatebox" data-options="required:true" /></td>
            <td class="text-right">联系电话：</td>
            <td>
                <input type="text" name="linkmantel" id="linkmantel" class="easyui-validatebox" data-options="required:true" /></td>
        </tr>
        <tr>
            <td colspan="6">部门申报情况：
                <textarea name="projectcontent" id="projectcontent" rows="4" class="easyui-validatebox span11" style="border-color: #ccc; background-color: #fff;" data-options="required:true"></textarea>
            </td>
        </tr>
        <tr>
            <td colspan="6">
                <input type="hidden" id="index" value="0">
                <table class="table  table-bordered" id="itemList">
                    <tr>
                        <th style="text-align: center; width: 230px;">采购项目名称
                        </th>
                        <th style="text-align: center; width: 60px;">单位  

                        </th>
                        <th style="text-align: center; width: 60px;">数量
                        </th>
                        <th style="text-align: center; width: 100px;">单价(元)
                        </th>
                        <th style="text-align: center; width: 100px;">采购预算资金(元)
                        </th>
                        <th style="text-align: center; width: 180px;">技术要求
                        </th>
                        <th style="text-align: center; width: 30px;">操作
                        </th>
                    </tr>
                    <tr>
                        <td>
                            <input type="text" name="purchasename" class="easyui-validatebox span12" data-options="required:true" />
                        </td>
                        <td>
                            <input type="text" name="units" class="easyui-validatebox span9" data-options="required:true" />
                        </td>
                        <td>
                            <input type="text" name="number" class="easyui-validatebox span9" data-options="required:true" />
                        </td>
                        <td>
                            <input type="text" name="price" id="price" class="easyui-numberbox span11" data-options="precision:2,required:true" />
                        </td>
                        <td>
                            <input type="text" name="budgetamount" id="budgetamount" class="easyui-numberbox span11" data-options="precision:2,required:true" />
                        </td>
                        <td>
                            <input type="text" name="techrequirement" class="span12" />
                        </td>
                        <td style="text-align: center;">
                            <img id="btn" onclick="javascript:addList();" src="../../js/easyui/themes/icons/edit_add.png" />

                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</form>
