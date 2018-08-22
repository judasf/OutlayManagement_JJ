<%@ Page Language="C#" %>

<% 
    /*
     * 显示接收单位回执信息
     */
    //报表信息表ReportInfo中的reportid
    string reportId = string.IsNullOrEmpty(Request.QueryString["reportid"]) ? "" : Request.QueryString["reportid"].ToString();
    //通过认证    
    if (Request.IsAuthenticated)
    {
        UserDetail ud = new UserDetail();
        int roleid = ud.LoginUser.RoleId;
%>
<script type="text/javascript">
    var roleid=<%=roleid%>
</script>
<%}%>
<script type="text/javascript">

    var reportGrid;
    //退回基层用户已回执的报表
    var backReceiptReportFun = function (id) {
        $.post('service/ReportInfo.ashx/BackReceiptReport', { id: id },
        function (result) {
            if (result.success) {
                reportGrid.datagrid('reload');
            } else {
                parent.$.messager.alert('提示', result.msg, 'error');
            }
        }, 'json');
    };
    //查询功能
    var searchGrid = function () {
        reportGrid.datagrid('load', $.serializeObject($('#searchForm')));
    };
    //重置查询
    var resetGrid = function () {
        $('#searchForm input').val('');
        reportGrid.datagrid('load', {});
    };
    $(function () {
        //加载数据
        if ($('#reportId').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            //初始化基层用户报表回执情况
            reportGrid = $('#reportDetailGrid').datagrid({
                title: '各单位报表回执详情',
                url: 'service/ReportInfo.ashx/GetReportReceiptDetailByReportId?reportid=' + $('#reportId').val(),
                striped: true,
                border:false,
                fit:true,
                noheader:true,
                rownumbers: true,
                pagination: true,
                pageSize: 15,
                pageList:['15','30','45','60'],
                singleSelect: true,
                idField: 'id',
                sortName: 'id',
                sortOrder: 'desc',
                columns: [
        [{
            width: '80',
            title: '单位名称',
            field: 'deptname',
            halign: 'center',
            align: 'center'
        }, {
            width: '65',
            title: '是否接收',
            field: 'isread',
            halign: 'center',
            align: 'center',
            formatter: function (value, row, index) {
                switch (value) {
                    case '0':
                        return '<span class="ext-icon-email" style="padding-left:20px;">未接收</span>';
                        break;
                    case '1':
                        return '<span class="ext-icon-email_open" style="padding-left:20px;">已接收</span>'
                        break;
                }
            }
        }, {
            width: '180',
            title: '回执报表名称',
            field: 'receiptreport',
            halign: 'center',
            align: 'center',
            formatter: function (val, row) {
                var str = '未回执报表';
                if (val && row.isreceipted == 1)
                    str = val.substr(val.lastIndexOf('/') + 1);
                return str;
            }
        }, {
            width: '60',
            title: '报表下载',
            field: 'download',
            halign: 'center',
            align: 'center',
            formatter: function (val, row) {
                var str = '';
                if (row.receiptreport && row.isreceipted == 1)
                    str = $.formatString('<a href="{0}"  title="点击下载报表">点击下载</a>', row.receiptreport);
                return str;
            }
        }, {
            width: '60',
            title: '回执人',
            field: 'receiptuser',
            halign: 'center',
            align: 'center',
            formatter: function (val, row) {
                var str = '';
                if (row.isreceipted == 1)
                    str = val;
                return str;
            }
        }
        , {
            width: '65',
            title: '回执时间',
            field: 'receipttime',
            halign: 'center',
            align: 'center',
            formatter: function (val,row) {
                var str = '';
                if (val && row.isreceipted == 1)
                    str = val.substr(0, 10).replace(/\//g, '-');
                return str;
            }
        }, {
            width: '55',
            title: '操作',
            field: 'action',
            halign: 'center',
            align: 'center',
            formatter: function (val, row) {
                var str = '';
                //退回已回执的报表
                if (row.isreceipted == 1 &&(roleid==2 || roleid==5)) {//稽核和统计可退回
                    str += $.formatString('<a href="javascript:void(0);" title="退回" onclick="backReceiptReportFun(\'{0}\');">退回</a>&nbsp;', row.id);
                }
                return str;
            }
        }
        ]
                ],
                toolbar: '#toolbar',
                onLoadSuccess: function (data) {
                    parent.$.messager.progress('close');
                    if (data.rows.length == 0) {
                        var body = $(this).data().datagrid.dc.body2;
                        body.find('table tbody').append('<tr><td width="' + body.width() + '" style="height: 25px; text-align: center;">没有数据</td></tr>');
                    }
                    $(this).datagrid('tooltip', ['receiptreport']);
                }
            });
            //设置分页属性
            var pager = $('#reportDetailGrid').datagrid('getPager');
            pager.pagination({ layout: ['list', 'sep', 'first', 'prev', 'sep', 'links', 'sep', 'next', 'last', 'sep', 'refresh', 'sep', 'manual']
            });
        }
    });
</script>
<input type="hidden" id="reportId" name="reportId" value="<%=reportId %>" />
<table id="reportDetailGrid">
</table>
<div id="toolbar">
    <form id="searchForm" style="margin: 0;">
        <table>
            <tr>

                <td width="80" align="right">回执情况：
                </td>
                <td>
                    <input name="IsReceipted" style="width: 60px;" id="IsReceipted" class="easyui-combobox" style="width: 100px;"
                        data-options="panelHeight:'auto',editable:false, valueField:'id',textField:'text',data: [{
			id:'0',
			text: '待回执'
		},{
			id: '1',
			text: '已回执'
		}]" />
                </td>

                <td>
                    <a href="javascript:void(0);" class="easyui-linkbutton" data-options="iconCls:'ext-icon-magnifier',plain:true"
                        onclick="searchGrid();">查询</a> <a href="javascript:void(0);" class="easyui-linkbutton"
                            data-options="iconCls:'ext-icon-magifier_zoom_out',plain:true" onclick="resetGrid();">重置</a>
                </td>
            </tr>
        </table>
    </form>
</div>
