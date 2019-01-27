<%@ Page Language="C#" %>

<% 
    /** 
     * 打印项目申报详情
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
    var rowspannum = 2;
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
                        var editEle = $.formatString('<tr style="text-align:center"><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td><td>{6}</td></tr>', i + 1, item.purchasename, item.units, item.number, item.price, item.budgetamount, item.techrequirement);
                        $(editEle).insertBefore($('#afterList'));
                        rowspannum++;
                    }
                });
                $('#rowspan').attr("rowSpan", rowspannum);
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
                    $('#projectcontent').html(result.rows[0].projectcontent + "<br/><br/><p style='text-align:right;margin-right:10px;'>" + result.rows[0].applytime + "</p>");
                    //显示审核信息
                    $('#dm').append(result.rows[0].dm);
                    $('#dm').append("<br/><p style='text-align:right;margin-right:10px;'>" + result.rows[0].deptmananame + "</p>")
                    $('#dm').append("<p style='text-align:right;margin-right:10px;'>" + result.rows[0].dmtime + "</p>");
                    $('#dl').append(result.rows[0].dl);
                    $('#dl').append("<br/><p style='text-align:right;margin-right:10px;'>" + result.rows[0].deptleadname + "</p>")
                    $('#dl').append("<p style='text-align:right;margin-right:10px;'>" + result.rows[0].dltime + "</p>");
                    $('#fm').append(result.rows[0].fm);
                    $('#fm').append("<br/><p style='text-align:right;margin-right:10px;'>" + result.rows[0].financemananame + "</p>")
                    $('#fm').append("<p style='text-align:right;margin-right:10px;'>" + result.rows[0].fmtime + "</p>");
                    $('#fl').append(result.rows[0].fl);
                    $('#fl').append("<br/><p style='text-align:right;margin-right:10px;'>" + result.rows[0].financeleadname + "</p>")
                    $('#fl').append("<p style='text-align:right;margin-right:10px;'>" + result.rows[0].fltime + "</p>");
                    //初始化采购项目明细
                    showItemList(result.rows[0].pjno);


                }
                parent.$.messager.progress('close');
            }, 'json');
        }
    });
</script>
<style>
    #editBaseInfoForm { font-size: 12px; }
    #editBaseInfoForm table tr td { vertical-align: middle; }
    #editBaseInfoForm table tr td.text-right { text-align: right; }
    #editBaseInfoForm table tr td.text-center { text-align: center; }
    #editBaseInfoForm table tr.auditTr td { height: 30px; vertical-align: text-top; }
</style>
<form method="post" id="editBaseInfoForm">
    <div id="printDiv">
        <p style="margin-top: 100px; font-size: 1.3em; text-align: center; line-height: 2.3em; font-weight: 700;">安阳市公安局交通管理支队自行采购项目申报表</p>
        <p style="margin: 0 0 0 30px; line-height: 30px;">项目编号：<span id="pjno"></span></p>
        <table border="1" bordercolor="#000" style="border-collapse: collapse; margin-left: 20px; margin-right: 20px; width: 95%">
            <tr>
                <td class="text-center" colspan="2" style="width: 80px;">申报部门
                </td>
                <td class="text-center">
                    <input type="hidden" id="id" name="id" value="<%=id %>" />
                    <span id="deptname"></span></td>

                <td class="text-center" colspan="2" style="width: 80px;">联系人</td>
                <td class="text-center" style="width: 90px;"><span id="linkman"></span></td>
                <td class="text-center" style="width: 130px;">联系电话</td>
                <td class="text-center" style="width: 180px;"><span id="linkmantel"></span></td>
            </tr>
            <tr>
                <td id="rowspan" style="width: 40px; text-align: center;">部<br />
                    门<br />
                    申<br />
                    报<br />
                    情<br />
                    况
               
                </td>
                <td colspan="7">
                    <div id="projectcontent" style="text-indent: 2em;"></div>
                </td>
            </tr>
            <tr>

                <th style="text-align: center; width: 40px;">序号  
                </th>
                <th style="text-align: center; width: 230px;">采购项目名称
                </th>
                <th style="text-align: center; width: 40px;">单位  
                </th>
                <th style="text-align: center; width: 40px;">数量
                </th>
                <th style="text-align: center; width: 90px;">单价(元)
                </th>
                <th style="text-align: center; width: 130px;">采购预算资金(元)
                </th>
                <th style="text-align: center; width: 180px;">技术要求
                </th>

            </tr>
            <tr class="auditTr" id="afterList">
                <td class="text-center">申<br />
                    报<br />
                    部<br />
                    门<br />
                    负<br />
                    责<br />
                    人<br />
                    意<br />
                    见</td>
                <td colspan="3" id="dm" style="text-indent: 2em;"></td>
                <td class="text-center">申<br />
                    报<br />
                    部<br />
                    门<br />
                    主<br />
                    管<br />
                    领<br />
                    导<br />
                    意<br />
                    见</td>
                <td id="dl" colspan="3" style="text-indent: 2em;"></td>
            </tr>
            <tr class="auditTr">
                <td class="text-center">行<br />
                    财<br />
                    部<br />
                    门<br />
                    意<br />
                    见</td>
                <td id="fm" colspan="3" style="text-indent: 2em;"></td>
                <td class="text-center">财<br />
                    务<br />
                    主<br />
                    管<br />
                    领<br />
                    导<br />
                    意<br />
                    见</td>
                <td id="fl" colspan="3" style="text-indent: 2em;"></td>

            </tr>
        </table>
    </div>
</form>
