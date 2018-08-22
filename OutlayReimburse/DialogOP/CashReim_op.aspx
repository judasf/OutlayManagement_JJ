<%@ Page Language="C#" %>
<%--动态增加或者删除现金支出的凭证，并计算每笔凭证之和--%>
<style type="text/css">
    #cashList p.header { text-align: center; font-weight: 700; font-size: 14px; line-height: 30px; border-bottom: 1px solid #ccc; }
    #cashList p.header span { margin-left: -20px; }
    #cashList p.header img { margin-left: 30px; }
</style>
<script type="text/javascript">
//删除单笔金额
    var delCash = function (obj) {
        //获取报销金额的值
        var reim = parseFloat($('#reimburseOutlay').numberbox('getValue'));
        //获取删除的金额值
        var reduceVal = parseFloat($(obj).parent().parent().find('input:hidden').val());
        if (reduceVal)
            reim -= reduceVal;
         //从data中清除要删除的数据
        $('#cashList').removeData($(obj).parent().parent().find('.easyui-numberbox').attr('id'));
        //删除金额
        $(obj).parent().parent().remove();
        //设置报销金额
        $('#reimburseOutlay').numberbox('setValue', reim);

    }
    //增加单笔报销金额
    var addCash = function () {
        var index = $('#index').val();
        index++;
        var insertEle = $('<tr><td>&nbsp;</td><td>金额：<input name="inputOutlay" id="inputOutlay' + index + '" class="easyui-numberbox" style="width: 100px;" data-options="required:true,min:0,precision:2" /></td><td style="padding-left:10px;"><img src="js/easyui/themes/icons/no.png" title="删除金额" onclick="delCash(this);"></td></tr>').appendTo($('#cashList').find('table'));
        $('#index').val(index);
        $.parser.parse(insertEle);
    }
    //更新报销金额，每次计算报销金额
    $('#cashList table').on('blur', 'input', function () {
        var reim = 0;
        //获取当前的值保存在data中
        if (parseFloat($(this).val()))
            $('#cashList').data($(this).attr('id'), $(this).val());
        else//无效输入赋值为0
            $('#cashList').data($(this).attr('id'), '0');
          //遍历data中的数据
        $.each($('#cashList').data(), function (key, value) {
        //计算报销金额的值
            reim += parseFloat(value);

        });
        //设置报销金额
        $('#reimburseOutlay').numberbox('setValue', reim);
    });
       
  
    
</script>
<div id="cashList">
    <input type="hidden" id="index" value="1">
    <p class="header">
        <span>现金支出事项</span><img src="js/easyui/themes/icons/edit_add.png" title="增加金额" onclick="addCash();"></p>
    <table border="0" cellpadding="3" cellspacing="0">
        <tr>
            <td style="width: 74px;">
            </td>
            <td>
                金额：<input id="inputOutlay1" name="inputOutlay" class="easyui-numberbox" style="width: 100px;"
                    data-options="required:true,min:0,precision:2" />
            </td>
            <td>
            </td>
        </tr>
    </table>
</div>
