<%@ Page Language="C#" %>

<% 
    /** 
     *DeductOutlayDetail表操作对话框，稽核扣减经费申请
     * 
     */
    string id = string.IsNullOrEmpty(Request.QueryString["id"]) ? "" : Request.QueryString["id"].ToString();
%>
<script type="text/javascript">
    //提交表单
    var onFormSubmit = function ($dialog, $grid) {
        if ($('form').form('validate')) {
            var url;
            if ($('#id').val().length == 0) {
                url = 'service/DeductOutlay.ashx/SaveDeductOutlayDetail';
            } else {
                url = 'service/DeductOutlay.ashx/UpdateDeductOutlayDetail';
            }
            //判断扣减额度

            if (parseFloat($('#deductOutlay').numberbox('getValue')) > parseFloat($('#unUsedOutlay').numberbox('getValue'))) {
                parent.$.messager.alert('提示', '扣减额度大于可用额度，请检查输入！', 'error');
                return;
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
    //获取并设置扣减单位的公用经费可用额度
    var setSpecialUnUsedOutlay = function (deptid, specialOutlayID) {
        $.post('service/DeductOutlay.ashx/GetSpecialUnusedOutlayByDeptIDAndOutlayID', { deptId: deptid, outlayId: specialOutlayID }, function (result) {
            if (result.success) {
                $('#unUsedOutlay').numberbox('setValue', result.val);
            } else {
                parent.$.messager.alert('提示', result.msg, 'error');
            }
        }, 'json');
    };
    //获取并设置扣减单位的公用经费可用额度
    var setPublicUnUsedOutlay = function (deptid) {
        $.post('service/DeductOutlay.ashx/GetPublicUnusedOutlayByDeptID', { deptId: deptid }, function (result) {
            if (result.success) {
                $('#unUsedOutlay').numberbox('setValue', result.val);
            } else {
                parent.$.messager.alert('提示', result.msg, 'error');
            }
        }, 'json');
    };
    //初始化公用经费
    var initPublic = function (deptid) {
        //隐藏专项额度编号
        $('#specialOutlayID').combogrid({ required: false });
        $('input[name="specialOutlayID"]').val('0');
        $('#outlayIdTr').hide();
        //获取公用经费可用额度
        setPublicUnUsedOutlay(deptid);
    };
    //初始化专项经费
    var initSpecial = function (deptid) {
        $('#outlayIdTr').show();
        //清空可用额度
        $('#unUsedOutlay').numberbox('setValue', 0);
        $('input[name="specialOutlayID"]').val('');
        //初始化额度编号combogrid
        initSpecialOutlayID(deptid);
    };
    //初始化额度编号combogrid
    var initSpecialOutlayID = function (deptid) {
        $("#specialOutlayID").combogrid({
            url: 'service/DeductOutlay.ashx/GetSpecialOutlayByDeptID?deptId=' + deptid,
            panelWidth: 720,
            panelHeight: 200,
            idField: 'outlayid', //form提交时的值
            textField: 'outlayid',
            editable: false,
            pagination: true,
            required: true,
            rownumbers: true,
            sortName: 'unusedoutlay',
            sortOrder: 'asc',
            pageSize: 5,
            pageList: [5, 10],
            columns: [
              [{
                  width: '80',
                  title: '可用额度',
                  field: 'unusedoutlay',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '下达额度',
                  field: 'alloutlay',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '120',
                  title: '下达额度时间',
                  field: 'outlaytime',
                  sortable: true,
                  halign: 'center',
                  align: 'center',
                  formatter: function (value) {
                      return value.substr(0,value.indexOf(' ')).replace(/\//g, '-');
                  }
              }, {
                  width: '55',
                  title: '额度编号',
                  field: 'outlayid',
                  sortable: true,
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '110',
                  title: '经费类别',
                  field: 'cname',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '150',
                  title: '用途',
                  field: 'usefor',
                  halign: 'center',
                  align: 'center'
              }, {
                  width: '80',
                  title: '资金年度',
                  field: 'outlayyear',
                  halign: 'center',
                  align: 'center',
                  formatter: function (value, row) {
                      var currentYear = new Date().getFullYear();
                      var thisYear = row.outlaytime.substr(0, 4);
                      if (currentYear == thisYear)
                          return '当年下达';
                      else
                          return '上年结余';
                  }
              }]
          ],
            onSelect: function (index, row) {
                if (row) {
                    $('#unUsedOutlay').numberbox('setValue', row.unusedoutlay);
                }
            },
            onLoadSuccess: function (data) {
                parent.$.messager.progress('close');
                if (!data.success && data.total == -1) {
                    parent.$.messager.alert('提示', '登陆超时，请重新登陆再进行操作！', 'error', function () {
                        parent.location.replace('index.aspx');
                    });
                }
            }
        });
        var g = $('#specialOutlayID').combogrid('grid');
        g.datagrid('getPager').pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });
    };
    //初始化额度编号combogrid结束
    $(function () {
        //初始化追加单位
        $('#deptId').combobox({
            valueField: 'id',
            textField: 'text',
            required: true,
            panelWidth: 200,
            panelHeight: 180,
            editable: false,
            url: 'service/Department.ashx/GetScopeDeptsCombobox',
            onSelect: function (rec) {
                $('#deptName').val(rec.text);
                //清空经费类别
                $('#outlayCategory').combobox('setValue', '');
                //清空可用额度
                $('#unUsedOutlay').numberbox('setValue', 0);
                //隐藏额度编号
                $('#outlayIdTr').hide();
            }
        });
        //初始化经费类别树
        $('#outlayCategory').combobox({
            valueField: 'id',
            textField: 'text',
            editable: false,
            required: true,
            panelWidth: 200,
            panelHeight: 'auto',
            data: [{ id: '1', text: '公用经费' }, { id: '2', text: '专项经费'}],
            onSelect: function (record) {
                //判断是否选择了扣减单位
                if (!$('#deptName').val()) {
                    parent.$.messager.alert('提示', '请选择扣减单位', 'warning');
                    $(this).combobox('setValue', '');
                    return;
                }
                //id=1:获取被扣减单位公用经费的值赋给unUsedOutlay
                if (record.id == '1')
                    initPublic($('#deptId').combobox('getValue'));
                //id=2:显示专项经费额度编号，获取被扣减单位可用的专项经费额度，选择后将可用额度赋给unUsedOutlay
                else if (record.id == '2')
                    initSpecial($('#deptId').combobox('getValue'));
            }
        });
        //编辑信息时初始化各项的值
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/DeductOutlay.ashx/GetDeductOutlayDetailByID', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id,
                        'deptName': result.rows[0].deptname,
                        'deductReason': result.rows[0].deductreason
                    });
                    $('#deptId').combobox('setValue', result.rows[0].deptid);
                    $('#outlayCategory').combobox('setValue', result.rows[0].outlaycategory);
                    $('#deductOutlay').numberbox('setValue', result.rows[0].deductoutlay);
                    //根据经费类别的不同处理可用额度和专项经费的显示
                    if (result.rows[0].outlaycategory == '1')//公用经费
                        initPublic(result.rows[0].deptid);
                    if (result.rows[0].outlaycategory == '2') {//专项经费
                        initSpecial(result.rows[0].deptid);
                        //设置专项经费额度编号
                        $('#specialOutlayID').combogrid('setValue', result.rows[0].specialoutlayid);
                        //根据部门编号和额度编号设置专项经费的可用额度
                        setSpecialUnUsedOutlay(result.rows[0].deptid, result.rows[0].specialoutlayid);
                    }

                }
                parent.$.messager.progress('close');
            }, 'json');
        }
    });
   
</script>
<form method="post">
<table class="table table-bordered  table-hover">
    <tr>
        <td style="text-align: right;">
            扣减单位：
        </td>
        <td>
            <input type="hidden" id="id" name="id" value="<%=id %>" />
            <input type="hidden" name="deptName" id="deptName" />
            <input name="deptId" id="deptId" style="width: 200px;" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            经费类别：
        </td>
        <td>
            <input name="outlayCategory" id="outlayCategory" style="width: 200px;" />
        </td>
    </tr>
    <tr id="outlayIdTr" style="display: none">
        <td style="text-align: right">
            额度编号：
        </td>
        <td>
            <input name="specialOutlayID" id="specialOutlayID" style="width: 200px;" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            可用额度：
        </td>
        <td>
            <input name="unUsedOutlay" id="unUsedOutlay" class="easyui-numberbox" value="0" style="width: 200px;"
                data-options="min:0,precision:2,disabled:true" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right;">
            扣减额度：
        </td>
        <td>
            <input name="deductOutlay" id="deductOutlay" class="easyui-numberbox" style="width: 200px;"
                data-options="min:0,precision:2,required:true" />
        </td>
    </tr>
    <tr>
        <td style="text-align: right">
            扣减原因：
        </td>
        <td>
            <textarea name="deductReason" style="width: 200px;" id="deductReason" rows="2" class="easyui-validatebox"
                data-options="required:true"></textarea>
        </td>
    </tr>
</table>
</form>
