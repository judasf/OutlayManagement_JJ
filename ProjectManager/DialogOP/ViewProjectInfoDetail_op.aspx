<%@ Page Language="C#" %>

<% 
    /** 
     *项目申报详情
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
    }
%>
<script type="text/javascript">
    //提交表单
    var print = function ($dialog, $grid) {
        $("#printDiv").printArea({ mode: "popup", standard: "strict" });
    };
    //显示采购项目信息
    var showItemList = function (pjno) {
        $.post('../service/ProjectManager.ashx/GetItemListByNoForList', { no: pjno }, function (nodeRes) {
            if (nodeRes.total > 0) {
                $.each(nodeRes.rows, function (i, item) {
                    if (i >= 0) {
                        var editEle = $.formatString('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td><td>{6}</td></tr>', i + 1, item.purchasename, item.units, item.number, item.price, item.budgetamount, item.techrequirement);
                        $(editEle).appendTo($('#itemList'));
                    }
                });
            }
        }, 'json');
    };
    //初始化表单数据
    $(function () {
        if ($('#id').val().length > 0) {
            parent.$.messager.progress({
                text: '数据加载中....'
            });
            $.post('service/ProjectManager.ashx/GetProjectApplyInfoById', {
                ID: $('#id').val()
            }, function (result) {
                if (result.rows[0].id != undefined) {
                    $('form').form('load', {
                        'id': result.rows[0].id
                    });
                    $('#pjno').html(result.rows[0].pjno);
                    $('#deptname').html(result.rows[0].deptname);
                    $('#linkman').html(result.rows[0].linkman);
                    $('#linkmantel').html(result.rows[0].linkmantel);
                    $('#projectcontent').html(result.rows[0].projectcontent + "<br/><br/><p style='text-align:right;'>" + result.rows[0].applytime + "</p>");
                    //显示审核信息
                    $('#dm').append(result.rows[0].deptmanaaudit);
                    if (result.rows[0].deptmanacomment.length > 0)
                        $('#dm').append('，' + result.rows[0].deptmanacomment);
                    $('#dm').append("<br/><p style='text-align:right;'>" + result.rows[0].deptmananame + "</p>")
                    $('#dm').append("<p style='text-align:right;'>" + result.rows[0].deptmanaaudittime + "</p>")
                    $('#dl').append(result.rows[0].deptleadaudit);
                    if (result.rows[0].deptleadcomment.length > 0)
                        $('#dl').append('，' + result.rows[0].deptmanacomment);
                    $('#dl').append("<br/><p style='text-align:right;'>" + result.rows[0].deptleadname + "</p>")
                    $('#dl').append("<p style='text-align:right;'>" + result.rows[0].deptleadaudittime + "</p>")
                    $('#fm').append(result.rows[0].financemanaaudit);
                    if (result.rows[0].financemanacomment.length > 0)
                        $('#fm').append('，' + result.rows[0].financemanacomment);
                    $('#fm').append("<br/><p style='text-align:right;'>" + result.rows[0].financemananame + "</p>")
                    $('#fm').append("<p style='text-align:right;'>" + result.rows[0].financemanaaudittime + "</p>")
                    $('#fl').append(result.rows[0].financeleadaudit);
                    if (result.rows[0].financeleadcomment.length > 0)
                        $('#fl').append('，' + result.rows[0].financeleadcomment);
                    $('#fl').append("<br/><p style='text-align:right;'>" + result.rows[0].financeleadname + "</p>")
                    $('#fl').append("<p style='text-align:right;'>" + result.rows[0].financeleadaudittime + "</p>")
                    //初始化采购项目明细
                    showItemList(result.rows[0].pjno);

                }
                parent.$.messager.progress('close');
            }, 'json');
        }
    });
</script>
<style>
    #editBaseInfoForm table tr td { vertical-align: middle; }

    #editBaseInfoForm table tr td.text-right { text-align: right; width: 100px; }

    #editBaseInfoForm table tr td input, #baseInfoForm table tr td select { padding: 0 5px; line-height: 25px; height: 25px; }

    #editBaseInfoForm table tr.auditTr td { height: 40px; vertical-align: text-top; }

    #itemList { margin-bottom: 0; }

    #itemList tr td { text-align: center; }
</style>
<form method="post" id="editBaseInfoForm">
    <div id="printDiv">
        <p style="font-size: 1.3em; text-align: center; line-height: 2.3em; font-weight: 700;">安阳市公安局交通管理支队自行采购项目申报表</p>
        <table class="table table-bordered  table-hover row-fluid" style="margin-left: 20px; margin-right: 20px; width: 95%">
            <tr>
                <td class="text-left">项目编号：
                <input type="hidden" id="id" name="id" value="<%=id %>" />
                    <span id="pjno"></span></td>
                <td class="text-left">申报部门：
                <span id="deptname"></span></td>
            </tr>
            <tr>
                <td class="text-left">联系人：
                <span id="linkman"></span></td>
                <td class="text-left">联系电话：
                <span id="linkmantel"></span></td>
            </tr>
            <tr>
                <td colspan="4">部门申报情况：
                <div id="projectcontent" style="text-indent: 2em;"></div>
                </td>
            </tr>
            <tr>
                <td colspan="4">
                    <table class="table  table-bordered" id="itemList">
                        <tr>
                            <th style="text-align: center; width: 40px;">序号  
                            </th>
                            <th style="text-align: center; width: 230px;">采购项目名称
                            </th>
                            <th style="text-align: center; width: 40px;">单位  
                            </th>
                            <th style="text-align: center; width: 40px;">数量
                            </th>
                            <th style="text-align: center; width: 100px;">单价(元)
                            </th>
                            <th style="text-align: center; width: 120px;">采购预算资金(元)
                            </th>
                            <th style="text-align: center; width: 180px;">技术要求
                            </th>
                        </tr>

                    </table>
                </td>
            </tr>
            <tr class="auditTr">
                <td id="dm">申报部门负责人意见：</td>
                <td id="dl">申报部门主管领导意见：</td>

            </tr>
            <tr class="auditTr">
                <td id="fm">财务部门意见：</td>
                <td id="fl">财务主管领导意见：</td>

            </tr>
        </table>
    </div>
</form>
