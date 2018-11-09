<%@ WebHandler Language="C#" Class="FetchMenu" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;

public class FetchMenu : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;
    /// <summary>
    /// 用户角色
    /// </summary>
    int roleid = 0;
    public void ProcessRequest(HttpContext context)
    {
        //不让浏览器缓存
        context.Response.Buffer = true;
        context.Response.ExpiresAbsolute = DateTime.Now.AddDays(-1);
        context.Response.AddHeader("pragma", "no-cache");
        context.Response.AddHeader("cache-control", "");
        context.Response.CacheControl = "no-cache";
        context.Response.ContentType = "text/plain";

        Request = context.Request;
        Response = context.Response;
        Session = context.Session;
        Server = context.Server;

        //判断登陆状态
        if (!Request.IsAuthenticated)
        {
            Response.Write("{\"success\":false,\"msg\":\"登陆超时，请重新登陆后再进行操作！\",\"total\":-1,\"rows\":[]}");
            return;
        }
        else
        {
            UserDetail ud = new UserDetail();
            roleid = ud.LoginUser.RoleId;
        }
        if (!string.IsNullOrEmpty(Request.Form["method"]))
        {
            MethodInfo methodInfo = this.GetType().GetMethod(Request.Form["method"]);
            if (methodInfo != null)
            {
                methodInfo.Invoke(this, null);
            }
            else
                Response.Write("{\"flag\":\"0\",\"msg\":\"method not match!\"}");
        }
        else
        {
            Response.Write("{\"flag\":\"0\",\"msg\":\"method not found!\"}");
        }
    }

    public void CreatMenu()
    {
        /*
         * 权限列表
         * 1：基层用户,2：稽核员,3：出纳员,4：行财处长,5：统计员,6：系统管理员,7：浏览用户,8:部门负责人，9：部门主管领导，10：行财主管领导
         */
        string userID = Request.Form["userid"] == null ? "" : Request.Form["userid"].ToString();
        if (userID != "")
        {
            StringBuilder menuList = new StringBuilder();
            menuList.Append("{\"flag\":\"1\",\"msg\":\"succ\",\"menus\":");
            menuList.Append("[");
            //经费报销管理 begin
            //accordion 头
            if (roleid == 1 || roleid == 2 || roleid == 3 || roleid == 4 || roleid == 6 || roleid == 7 || roleid == 8 || roleid == 9 || roleid == 10)
            {
                menuList.Append("{\"menuid\": \"3\",\"menuname\": \"支出管理\",\"icon\": \"ext-icon-cart_remove\",\"menus\": [");
            }
            if (roleid == 1 || roleid == 8 || roleid == 9)//基层用户、部门负责人、部门主管领导
            {
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"公用经费支出管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayReimburse/PublicOutlayReimburse.aspx\",\"iframename\": \"pbframe\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"专项经费支出管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayReimburse/SpecialOutlayReimburse.aspx\",\"iframename\": \"spframe\"}");

            }
            if (roleid == 2)
            {

                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"现金支出报销管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayReimburse/AuditCashReimburse.aspx\",\"iframename\": \"xjbxgl\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"转账支出报销管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayReimburse/AuditAccountReimburse.aspx\",\"iframename\": \"zzbxgl\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"公务卡支出报销管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayReimburse/AuditCardReimburse.aspx\",\"iframename\": \"gwkbxgl\"}");
            }
            if (roleid == 3 || roleid == 4 || roleid == 6 || roleid == 7 || roleid == 10)//出纳,处长,管理员,浏览用户,行财主管领导
            {

                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"现金支出报销管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayReimburse/AcceptCashReimburse.aspx\",\"iframename\": \"xjshbxgl\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"转账支出报销管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayReimburse/AcceptAccountReimburse.aspx\",\"iframename\": \"zzshbxgl\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"公务卡支出报销管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayReimburse/AcceptCardReimburse.aspx\",\"iframename\": \"gwkshbxgl\"}");
            }
            //accordion 尾
            if (roleid == 1 || roleid == 2 || roleid == 3 || roleid == 4 || roleid == 6 || roleid == 7 || roleid == 8 || roleid == 9 || roleid == 10)
            {
                menuList.Append("]}");
            }
            //经费报销管理 end
            //经费管理 begin
            //accordion 头
            if (roleid == 1 || roleid == 2 || roleid == 4 || roleid == 6 || roleid == 7 || roleid == 8 || roleid == 9 || roleid == 10)
            {
                menuList.Append(",{\"menuid\": \"2\",\"menuname\": \"经费管理\",\"icon\": \"ext-icon-cart_put\",\"menus\": [");
            }
            if (roleid == 1 || roleid == 8 || roleid == 9)//基层用户、部门负责人、部门主管领导
            {
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"公用经费下发明细\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/PublicOutlayDetail.aspx\",\"iframename\": \"gyjfxfmx\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"专项经费管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/AllApplyOutlayTabs.aspx\",\"iframename\": \"zjjfgl\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"扣减经费管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayDeduct/DeductOutlayApplyDetail.aspx\",\"iframename\": \"kjjfgl\"}");
            }
            if (roleid == 2 || roleid == 6 || roleid == 7 || roleid == 10)//稽核,管理员，浏览用户，行财主管领导
            {
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"公用经费管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/CreatePublicOutlay.aspx\",\"iframename\": \"gyjfsc\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"专项经费管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/AllAuditApplyOutlayTabs.aspx\",\"iframename\": \"zjjfsh\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"扣减经费管理\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayDeduct/DeductOutlayApply.aspx\",\"iframename\": \"kjjfgl\"}");
            }
            if (roleid == 4)//处长
            {
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"公用经费审批\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/ApproverPublicOutlay.aspx\",\"iframename\": \"gyjfsp\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"追加经费审批\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/AllApproverApplyOutlayTabs.aspx\",\"iframename\": \"zjjfsp\"},");
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"扣减经费审批\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutlayDeduct/ApproveDeductOutlay.aspx\",\"iframename\": \"kjjfsp\"}");
            }
            //增加额度合并明细
            if (roleid == 1 || roleid == 2 || roleid == 4 || roleid == 6 || roleid == 7 || roleid == 8 || roleid == 9 || roleid == 10)
            {
                menuList.Append(",{\"menuid\": \"12\",\"menuname\": \"专项经费合并明细\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"OutLayApply/SpecialOutlayMergePublicDetail.aspx\",\"iframename\": \"zxhfhbmx\"}");
            }
            //accordion 尾
            if (roleid == 1 || roleid == 2 || roleid == 4 || roleid == 6 || roleid == 7 || roleid == 8 || roleid == 9 || roleid == 10)
            {
                menuList.Append("]}");
            }
            //经费管理 end
            //报表统计 begin
            //accordion 头
            if (roleid != 5)
                menuList.Append(",");
            menuList.Append("{\"menuid\": \"1\",\"menuname\": \"报表统计\",\"icon\": \"ext-icon-chart_bar\",\"menus\": [");
            if (roleid != 1 && roleid != 8 && roleid != 9)
            {
                if (roleid == 7)//浏览用户
                {
                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"意见信箱\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\":\"NoticeInfo/ReplyNoticeInfo.aspx\",\"iframename\": \"yjxx\"}");
                    menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"可用额度查询\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\":\"DataStatistics/UnUsedOutlayDetail.aspx\",\"iframename\": \"kyedcx\"}");
                }
                else
                {
                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"报表报送\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\":\"ReportInfo/ReportInfo.aspx\",\"iframename\": \"bbbs\"},");
                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"意见信箱\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\":\"NoticeInfo/ReplyNoticeInfo.aspx\",\"iframename\": \"yjxx\"}");
                    if (roleid == 2)
                    {
                        menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"数据统计\",\"icon\": \"ext-icon-table\",");
                        menuList.Append("\"url\":\"DataStatistics/AuditStatisticsTabs.aspx\",\"iframename\": \"sjtj\"}");
                    }
                    if (roleid == 2 || roleid == 4 || roleid == 6 || roleid == 10)//稽核，行财科长，管理员，行财主管领导
                    {
                        menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"可用额度查询\",\"icon\": \"ext-icon-table\",");
                        menuList.Append("\"url\":\"DataStatistics/UnUsedOutlayDetail.aspx\",\"iframename\": \"kyedcx\"}");
                        menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"年度经费结余\",\"icon\": \"ext-icon-table\",");
                        menuList.Append("\"url\":\"DataStatistics/AnnualBalanceDetial.aspx\",\"iframename\": \"ndjfjy\"}");
                        menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"单位对账单\",\"icon\": \"ext-icon-table\",");
                        menuList.Append("\"url\":\"DataStatistics/AccountStatementInfo.aspx\",\"iframename\": \"dwdzd\"}");
                    }
                    if (roleid == 6)
                    {
                        menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"额度修正\",\"icon\": \"ext-icon-table\",");
                        menuList.Append("\"url\":\"DataStatistics/FixedOutlayTabs.aspx\",\"iframename\": \"edxz\"}");
                        menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"待取回现金支出\",\"icon\": \"ext-icon-table\",");
                        menuList.Append("\"url\":\"DataStatistics/UnRetrieveOutlay.aspx\",\"iframename\": \"dqhxjzc\"}");
                    }
                }
            }
            else if (roleid == 1 || roleid == 8 || roleid == 9)
            {
                menuList.Append("{\"menuid\": \"14\",\"menuname\": \"报表报送\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\":\"ReportInfo/ReceiverReportInfo.aspx\",\"iframename\": \"bbbs\"},");
                menuList.Append("{\"menuid\": \"14\",\"menuname\": \"意见信箱\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\":\"NoticeInfo/NoticeInfo.aspx\",\"iframename\": \"yjxx\"},");
                menuList.Append("{\"menuid\": \"14\",\"menuname\": \"数据统计\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\":\"DataStatistics/BaseUserStatisticsTabs.aspx\",\"iframename\": \"sjtj\"}");
                menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"年度经费结余\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\":\"DataStatistics/AnnualBalanceDetial.aspx\",\"iframename\": \"ndjfjy\"}");
                menuList.Append(",{\"menuid\": \"14\",\"menuname\": \"单位对账单\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\":\"DataStatistics/AccountStatementInfo.aspx\",\"iframename\": \"dwdzd\"}");
            }
            //accordion 尾
            menuList.Append("]}");
            //报表统计 end
            //项目管理 begin
            //accordion 头
            if (roleid != 5)
                menuList.Append(",{\"menuid\": \"1\",\"menuname\": \"项目申报\",\"icon\": \"ext-icon-chart_bar\",\"menus\": [");
            if (roleid != 5)
            {
                menuList.Append("{\"menuid\": \"11\",\"menuname\": \"全部申报项目\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"ProjectManager/ProjectManager_All.aspx\",\"iframename\": \"xmsb\"}");

                if (roleid == 8)
                {
                    menuList.Append(",{\"menuid\": \"11\",\"menuname\": \"待审批项目\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\": \"ProjectManager/ProjectManager.aspx?cs=1\",\"iframename\": \"bscsh\"}");
                }
                if (roleid == 9)
                {
                    menuList.Append(",{\"menuid\": \"11\",\"menuname\": \"待审批项目\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\": \"ProjectManager/ProjectManager.aspx?cs=2\",\"iframename\": \"bscsh\"}");
                }
                if (roleid == 4)
                {
                    menuList.Append(",{\"menuid\": \"11\",\"menuname\": \"待审批项目\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\": \"ProjectManager/ProjectManager.aspx?cs=3\",\"iframename\": \"bscsh\"}");
                }
                if (roleid == 10)
                {
                    menuList.Append(",{\"menuid\": \"11\",\"menuname\": \"待审批项目\",\"icon\": \"ext-icon-table\",");
                    menuList.Append("\"url\": \"ProjectManager/ProjectManager.aspx?cs=4\",\"iframename\": \"bscsh\"}");
                }
                menuList.Append(",{\"menuid\": \"11\",\"menuname\": \"审批完结项目\",\"icon\": \"ext-icon-table\",");
                menuList.Append("\"url\": \"ProjectManager/ProjectManager.aspx?cs=5\",\"iframename\": \"bscsh\"}");
            }
            //accordion 尾
            if (roleid != 5)
                menuList.Append("]}");
            //项目管理 end
            //系统设置 begin
            if (roleid == 2 || roleid == 6 || roleid == 3)
            {
                //accordion 头
                menuList.Append(",{\"menuid\": \"1\",\"menuname\": \"系统设置\",\"icon\": \"ext-icon-cog\",\"menus\": [");
                if (roleid != 2 && roleid != 3)
                {
                    menuList.Append("{\"menuid\": \"11\",\"menuname\": \"用户管理\",\"icon\": \"ext-icon-status_online\",");
                    menuList.Append("\"url\": \"baseinfo/userinfo.aspx\",\"iframename\": \"yhgl\"},");
                    menuList.Append("{\"menuid\": \"12\",\"menuname\": \"基层单位管理\",\"icon\": \"ext-icon-group\",");
                    menuList.Append("\"url\": \"baseinfo/department.aspx\",\"iframename\": \"jcdwgl\"},");

                    menuList.Append("{\"menuid\": \"12\",\"menuname\": \"支出科目管理\",\"icon\": \"ext-icon-text_list_bullets\",");
                    menuList.Append("\"url\": \"baseinfo/expensesubject.aspx\",\"iframename\": \"zckmgl\"},");
                    menuList.Append("{\"menuid\": \"13\",\"menuname\": \"角色管理\",\"icon\": \"ext-icon-tux\",");
                    menuList.Append("\"url\":\"baseinfo/RoleInfo.aspx\",\"iframename\": \"jsgl\" },");
                    menuList.Append("{\"menuid\": \"13\",\"menuname\": \"经费类别管理\",\"icon\": \"ext-icon-wrench\",");
                    menuList.Append("\"url\":\"baseinfo/category.aspx\",\"iframename\": \"jflbgl\" },");
                }
                if (roleid != 3)
                {
                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"公用经费标准管理\",\"icon\": \"ext-icon-money\",");
                    menuList.Append("\"url\":\"baseinfo/OutlayLevel.aspx\"},");
                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"基层单位公用经费设置\",\"icon\": \"ext-icon-money\",");
                    menuList.Append("\"url\":\"baseinfo/DeptOutlay.aspx\",\"iframename\": \"jcdwgyjfsz\"}");
                }
                if (roleid != 2)
                {
                    if (roleid != 3)
                        menuList.Append(",");

                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"转账信息管理\",\"icon\": \"ext-icon-building\",");
                    menuList.Append("\"url\":\"baseinfo/PayeeInfo.aspx\",\"iframename\": \"zzxxgl\"},");
                    menuList.Append("{\"menuid\": \"14\",\"menuname\": \"公务卡信息管理\",\"icon\": \"ext-icon-vcard\",");
                    menuList.Append("\"url\":\"baseinfo/CardInfo.aspx\",\"iframename\": \"gwkxxgl\"}");
                }
                //accordion 尾
                menuList.Append("]}");
            }
            //系统设置 end
            menuList.Append("]}");
            Response.Write(menuList.ToString());
        }
        else
            Response.Write("{\"flag\":\"0\",\"msg\":\"argument not match!\"}");


    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}