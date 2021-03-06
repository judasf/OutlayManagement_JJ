﻿<%@ Page Language="C#" %>

<!-- 专项经费支出管理——公务卡支付明细——基层用户 -->
<script type="text/javascript">
    //送审待送审的公务卡支出申请
    var sendCardReimburse = function (id) {
        parent.$.messager.confirm('送审支出', '您确认要送审该项支出？', function (r) {
            if (r) {
                $.post('../service/ReimburseOutlay.ashx/SendCardReimburse',
                { id: id },
                function (result) {
                    if (result.success) {
                        cardGrid.datagrid('reload');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //删除待送审的公务卡支出
    var removeCardReimburse = function (id) {
        parent.$.messager.confirm('删除确认', '您确认要删除该项支出？', function (r) {
            if (r) {
                $.post('../service/ReimburseOutlay.ashx/RemoveCardReimburse',
                { id: id },
                function (result) {
                    if (result.success) {
                        cardGrid.datagrid('reload');
                        //刷新tab的内容，来更新专项经费明细
                        var tab = spTabs.tabs('getTab', 0);
                        if (tab)
                            tab.panel('refresh');
                        parent.$.messager.alert('成功', result.msg, 'info');
                    } else {
                        parent.$.messager.alert('提示', result.msg, 'error');
                    }
                }, 'json');
            }
        });
    };
    //导出专项经费公务卡报销excel
    var exportCardReimburse = function () {
        jsPostForm('../service/ReimburseOutlay.ashx/ExportUserSpecialCardReimburse?type=2', $.serializeObject($('#sasearchForm')));
    };
    //转账支出表
    var cardGrid;
    $(function () {
        //cardGrid 转账支出表
        cardGrid = $('#cardGrid').datagrid({
            title: '公务卡支出明细',
            url: '../service/ReimburseOutlay.ashx/GetCardPay?type=2',
            striped: true,
            rownumbers: true,
            pagination: true,
            noheader: true,
            showFooter: true,
            pageSize: 20,
            singleSelect: true,
            idField: 'id',
            sortName: 'id',
            sortOrder: 'desc',
            columns: [[
            {
                width: '65',
                title: '办理编号',
                field: 'reimburseno',
                sortable: true,
                halign: 'center',
                align: 'center'
            }, {
                width: '80',
                title: '单位名称',
                field: 'deptname',
                halign: 'center',
                align: 'center'
            }, {
                width: '65',
                title: '申请日期',
                field: 'reimbursedate',
                sortable: true,
                halign: 'center',
                align: 'center'
            }, {
                width: '65',
                title: '支出金额',
                field: 'reimburseoutlay',
                sortable: true,
                halign: 'center',
                align: 'center'
            }, {
                width: '55',
                title: '额度编号',
                field: 'outlayid',
                sortable: true,
                halign: 'center',
                align: 'center'
            }
            , {
                width: '70',
                title: '经费类别',
                field: 'outlaycategory',
                halign: 'center',
                align: 'center'
            }, {
                width: '100',
                title: '支出科目',
                field: 'expensesubject',
                halign: 'center',
                align: 'center'
            }, {
                width: '120',
                title: '支出摘要',
                field: 'memo',
                halign: 'center',
                align: 'center'
            }, {
                width: '60',
                title: '持卡人',
                field: 'cardholder',
                halign: 'center',
                align: 'center'
            }, {
                width: '130',
                title: '卡号',
                field: 'cardnumber',
                halign: 'center',
                align: 'center'
            }, {
                width: '110',
                title: '消费时间',
                field: 'spendingtime',
                halign: 'center',
                align: 'center',
                formatter: function (value) {
                    if (value)
                        return value.replace(/\//g, '-');
                }
            }, {
                width: '50',
                title: '经办人',
                field: 'username',
                halign: 'center',
                align: 'center'
            }, {
                width: '50',
                title: '报销人',
                field: 'reimburseuser',
                halign: 'center',
                align: 'center'
            }, {
                width: '65',
                title: '审核状态',
                field: 'status',
                sortable: true,
                halign: 'center',
                align: 'center',
                formatter: function (value, row, index) {
                    switch (value) {
                        case '-1':
                            return '被稽核退回';
                            break;
                        case '0':
                            return '待送审'
                            break;
                        case '1':
                            return '待审核'
                            break;
                        case '2': //被出纳退回给稽核，基层用户显示为出纳退回，当被稽核退回时status为-1
                            return '被出纳退回'
                            break;
                        case '3':
                            return '已审核'
                            break;
                    }
                }
            }, {
                width: '55',
                title: '结报状态',
                field: 'finishstatus',
                sortable: true,
                halign: 'center',
                align: 'center',
                formatter: function (value, row, index) {
                    switch (value) {
                        case '0':
                            return '待受理'
                            break;
                        case '1':
                            return '已受理'
                            break;
                        case '2':
                            return '已办结'
                            break;
                    }
                }
            }
               , {
                   title: '操作',
                   field: 'action',
                   width: '60',
                   halign: 'center',
                   align: 'center',
                   formatter: function (value, row) {
                       var str = '';
                       if (row.status == 0) { //基层用户，待送审的支出申请可以送审或删除
                           str += $.formatString('<a href="javascript:void(0)" onclick="sendCardReimburse(\'{0}\');">送审</a>&nbsp;', row.id);
                           str += $.formatString('<a href="javascript:void(0)" onclick="removeCardReimburse(\'{0}\');">删除</a>', row.id);

                       }
                       return str;
                   }
               }, {
                   width: '150',
                   title: '稽核意见',
                   field: 'auditorcomment',
                   halign: 'center',
                   align: 'center'
               }
            ]
            ],
            toolbar: '#spcardTip',
            onLoadSuccess: function (data) {
                if (data.rows.length == 0) {
                    var body = $(this).data().datagrid.dc.body2;
                    body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                }
                //提示框
                $(this).datagrid('tooltip', ['outlaycategory', 'expensesubject', 'memo', 'cardnumber', 'spendingtime', 'auditorcomment']);
            }
        });
        //设置分页属性
        var pager = $('#cardGrid').datagrid('getPager');
        pager.pagination({
            layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
        });

    });
</script>
<div id="spcardTip">
    <form id="sasearchForm" style="margin: 0;">
        <table>
            <tr>
                <td width="50" align="right">日期：
                </td>
                <td>
                    <input style="width: 80px;" name="sdate" id="sdate" class="Wdate" onfocus="WdatePicker({maxDate:'#F{$dp.$D(\'edate\')}',maxDate:'%y-%M-%d'})"
                        readonly="readonly" />-<input style="width: 80px;" name="edate" id="edate" class="Wdate"
                            onfocus="WdatePicker({minDate:'#F{$dp.$D(\'sdate\')}',maxDate:'%y-%M-%d'})" readonly="readonly" />
                </td>
                <td width="50" align="right">编号：
                </td>
                <td>
                    <input style="width: 55px; height: 20px" type="text" class="combo" name="outlayid" />
                </td>
                <td width="50" align="right">类别：
                </td>
                <td align="left">
                    <input type="hidden" name="outlayCategory" id="outlayCategory" />
                    <input name="category" id="category" class="easyui-combotree" data-options="valueField: 'id',textField: 'text', editable: false, lines: true,panelHeight: 'auto',url: '../service/category.ashx/GetCategory?pid=2',onLoadSuccess: function (node, data) {
                if (!data) {
                    $(this).combotree({ readonly: true });
                }
            },onSelect:function(node){if(node) $('#sasearchForm').find('#outlayCategory').val(node.text);}" />
                </td>
                <td width="50" align="right">审核：
                </td>
                <td>
                    <input style="width: 105px" name="status" id="status" class="easyui-combobox" data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'-1','text':'被稽核退回'},{'value':'0','text':'待送审'},{'value':'1','text':'待审核'},{'value':'2','text':'被出纳退回'},{'value':'3','text':'已审核'}]" />
                </td>
                <td width="50" align="right">结报：
                </td>
                <td>
                    <input id="finishstatus" class="easyui-combobox"
                        data-options="panelHeight:'auto',editable:false,valueField:'value',textField:'text',data:[{'value':'0','text':'待受理'},{'value':'2','text':'已办结'}],onSelect:function(rec){(rec.value>0)&&$('#sasearchForm').find('#status').combobox('setValue','3');}"
                        name="finishstatus" style="width: 60px" />
                </td>
                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="cardGrid.datagrid('load', $.serializeObject($('#sasearchForm')));">查询</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true"
                        onclick="  $('#sasearchForm input').val('');cardGrid.datagrid('load', {});">重置</a>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-table_go',plain:true"
                        onclick="exportCardReimburse();">导出</a>
                </td>
            </tr>
        </table>
    </form>
    <div style="background: url(../js/easyui/themes/icons/tip.png) no-repeat 10px 5px; line-height: 24px; padding-left: 30px;">
        转账支出明细无需取回被退回的金额，当支出申请被稽核退回时额度自动回复
    </div>
</div>
<table id="cardGrid" data-options="fit:false,border:false">
</table>
