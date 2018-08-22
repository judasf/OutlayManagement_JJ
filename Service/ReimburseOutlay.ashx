<%@ WebHandler Language="C#" Class="ReimburseOutlay" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections;
using System.Collections.Generic;
/// <summary>
/// 经费报销流程处理
/// </summary>
public class ReimburseOutlay : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;
    /// <summary>
    /// 非基层用户的管辖范围
    /// </summary>
    string scopeDepts;
    /// <summary>
    /// 用户角色编号
    /// </summary>
    string roleid;
    /// <summary>
    /// 用户部门编号
    /// </summary>
    string deptid;
    /// <summary>
    /// 登陆用户部门名
    /// </summary>
    string deptName;
    /// <summary>
    /// 当前登陆用户名
    /// </summary>
    string userName;
    public void ProcessRequest(HttpContext context)
    {
        //不让浏览器缓存
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
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
            roleid = ud.LoginUser.RoleId.ToString();
            scopeDepts = ud.LoginUser.ScopeDepts;
            deptid = ud.LoginUser.DeptId.ToString();
            deptName = ud.LoginUser.UserDept;
            userName = ud.LoginUser.UserName;
        }
        string method = HttpContext.Current.Request.PathInfo.Substring(1);
        if (method.Length != 0)
        {
            MethodInfo methodInfo = this.GetType().GetMethod(method);
            if (methodInfo != null)
            {
                methodInfo.Invoke(this, null);
            }
            else
                Response.Write("{\"success\":false,\"msg\":\"Method Not Matched !\"}");
        }
        else
        {
            Response.Write("{\"success\":false,\"msg\":\"Method not Found !\"}");
        }
        Response.End();
    }
    /// <summary>
    /// 设置现金报销表查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForCash()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //申请开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" ReimburseDate >='" + Request.Form["sdate"] + "'");
        //申请截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" ReimburseDate <='" + Request.Form["edate"] + "'");

        //基层用户数据显示条件
        if (roleid == "1")
        {
            //未选择申请日期
            if (string.IsNullOrEmpty(Request.Form["sdate"]) && string.IsNullOrEmpty(Request.Form["edate"]))
            {
                //存在上面未送审支出申请,显示全部未送审申请
                if (IsExistUnsendReimburse("cashpay"))
                {
                    list.Add(" status=0 ");
                }
                else //不存在，则显示当年数据
                    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
            }
        }
        //--------------------------------------------------------------//
        //稽核处理开始日期
        if (!string.IsNullOrEmpty(Request.Form["audit_sdate"]))
            list.Add(" AuditDate >='" + Request.Form["audit_sdate"] + "'");
        //稽核处理截止日期
        if (!string.IsNullOrEmpty(Request.Form["audit_edate"]))
            list.Add(" AuditDate <='" + Request.Form["audit_edate"] + "'");
        //稽核处理日期未选择，默认只显示当年数据(稽核用户)
        //if (string.IsNullOrEmpty(Request.Form["audit_sdate"]) && string.IsNullOrEmpty(Request.Form["audit_edate"]) && roleid == "2")
        //    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//
        //出纳、处长、管理员、浏览用户处理开始日期
        if (!string.IsNullOrEmpty(Request.Form["accept_sdate"]))
        {
            if (roleid == "6") //管理员按申请日期查询
                list.Add(" ReimburseDate >='" + Request.Form["accept_sdate"] + "'");
            else
                list.Add(" AcceptDate >='" + Request.Form["accept_sdate"] + "'");
        }
        //出纳处理截止日期
        if (!string.IsNullOrEmpty(Request.Form["accept_edate"]))
        {
            if (roleid == "6") //管理员按申请日期查询
                list.Add(" ReimburseDate <='" + Request.Form["accept_edate"] + "'");
            else
                list.Add(" AcceptDate <='" + Request.Form["accept_edate"] + "'");
        }
        //出纳处理日期未选择，默认只显示当年数据（出纳,处长,管理员,浏览用户）
        //if (string.IsNullOrEmpty(Request.Form["accept_sdate"]) && string.IsNullOrEmpty(Request.Form["accept_edate"]) && (roleid == "3" || roleid == "4" || roleid == "6" || roleid == "7"))
        //    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //-----------2017年1月8日修改
        //管理员默认显示当年数据（处长,管理员,浏览用户）
        if (string.IsNullOrEmpty(Request.Form["accept_sdate"]) && string.IsNullOrEmpty(Request.Form["accept_edate"]) && (roleid == "4" || roleid == "6" || roleid == "7"))
            list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//
        //按额度编号
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" outlayid like'%" + Request.Form["outlayid"] + "%'");
        //按经费类别
        if (!string.IsNullOrEmpty(Request.Form["outlayCategory"]))
            list.Add(" outlayCategory ='" + Request.Form["outlayCategory"] + "'");
        //按办理编号
        if (!string.IsNullOrEmpty(Request.Form["reimburseNo"]))
            list.Add(" reimburseNo like'%" + Request.Form["reimburseNo"] + "%'");
        //按单位查询
        //基层用户只获取自己的信息
        if (roleid == "1")
            list.Add(" a.deptid= " + deptid);
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" a.deptid ='" + Request.Form["deptid"] + "'");
        }
        //按审核状态查询
        if (!string.IsNullOrEmpty(Request.Form["status"]))
        {
            if (Request.Form["status"] == "3")//已审核的，显示已审核和部分审核的信息
                list.Add(" (status = 3 or status=4) ");
            else
                list.Add("status=" + Request.Form["status"]);
        }
        //默认显示数据设置
        //基层用户(1)显示全部未送审信息，可取回被退回的金额；稽核(2)默认显示已提交待审核(1)和被出纳退回(2)，可查询1，2和已审核(3)和已审核部分退回(4)的记录；出纳(3)显示稽核已审核(3)和已审核部分退回(4)，finishStatus:未受理(0),已受理(1)的记录；可查询已办结(2)的记录;管理员(6)显示finishStatus(2)已办结的，可查询待受理和已受理的
        //稽核显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "2")
            list.Add("(status>0 and status<3) ");
        //出纳显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "3")
            list.Add(" status>2 ");
        //按结报状态查询
        if (!string.IsNullOrEmpty(Request.Form["finishstatus"]))
            list.Add(" finishstatus= " + Request.Form["finishstatus"].ToString());
        else
        {
            if (roleid == "6")
                list.Add(" finishstatus=2 ");
            else
                list.Add(" finishstatus<2");
        }
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" a.deptid in (" + scopeDepts + ") ");
        //经费类别：1：公用；2：专项，用来判断显示基层用户公用经费报销或者专项经费报销
        string type = Convert.ToString(Request.QueryString["type"]);
        //基层用户根据经费类别不同在不同页面显示现金报销明细，其他用户全部显示
        if (roleid == "1")
            list.Add(" type=" + type);
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    ///  获取现金支出报销表Reimburse_CashPay数据 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetCashPay()
    {
        int total = 0;
        string where = SetQueryConditionForCash();
        string tableName = "Reimburse_CashPay a join department b on a.deptid=b.deptid";
        string fieldStr = "a.*,b.deptname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "reimburseoutlay,auditcashoutlay", "reimbursedate", "合计"));
    }
    /// <summary>
    /// 获取单笔现金支出明细
    /// </summary>
    public void GetCashReimburseByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        string sql = "select a.*,b.deptname,dbo.F_SumEveryAuditSingleCash(@id) as auditcash from Reimburse_CashPay a join department b on a.deptid=b.deptid where a.id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 通过ReimburseNo：办理编号获取现金支出凭证明细
    /// </summary>
    public void GetCashReimburseDetailByNo()
    {
        int reimburseNo = 0;
        int.TryParse(Request.QueryString["no"], out reimburseNo);
        int total = 0;
        string where = "ReimburseNo=" + reimburseNo;
        string tableName = "Reimburse_CashPayDetail";
        string fieldStr = "*";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 获取经费报销办理编号,获取办理编号,判断编号前6为是否为当年当月，如果是则追加1，不是设置为0001
    /// </summary>
    /// <returns></returns>
    public int GetReimburseNo()
    {
        int reimburseNo;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select top 1  ReimburseNo from autono");
        string currentNo = ds.Tables[0].Rows[0][0].ToString();
        if (currentNo.Substring(0, 6) == DateTime.Now.ToString("yyyyMM"))
            reimburseNo = int.Parse(currentNo) + 1;
        else
            reimburseNo = int.Parse(DateTime.Now.ToString("yyyyMM") + "0001");
        return reimburseNo;
    }
    /// <summary>
    /// 设置转账报销表查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForAccount()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //申请开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" ReimburseDate >='" + Request.Form["sdate"] + "'");
        //申请截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" ReimburseDate <='" + Request.Form["edate"] + "'");
        //基层用户数据显示条件
        if (roleid == "1")
        {
            //未选择申请日期
            if (string.IsNullOrEmpty(Request.Form["sdate"]) && string.IsNullOrEmpty(Request.Form["edate"]))
            {
                //存在上面未送审支出申请,显示全部未送审申请
                if (IsExistUnsendReimburse("accountpay"))
                {
                    list.Add(" status=0 ");
                }
                else //不存在，则显示当年数据
                    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
            }
        }


        //--------------------------------------------------------------//
        //稽核处理开始日期
        if (!string.IsNullOrEmpty(Request.Form["audit_sdate"]))
            list.Add(" AuditDate >='" + Request.Form["audit_sdate"] + "'");
        //稽核处理截止日期
        if (!string.IsNullOrEmpty(Request.Form["audit_edate"]))
            list.Add(" AuditDate <='" + Request.Form["audit_edate"] + "'");
        //稽核处理日期未选择，默认只显示当年数据(稽核用户)
        //if (string.IsNullOrEmpty(Request.Form["audit_sdate"]) && string.IsNullOrEmpty(Request.Form["audit_edate"]) && roleid == "2")
        //    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//
        //出纳、处长、管理员、浏览用户处理开始日期
        if (!string.IsNullOrEmpty(Request.Form["accept_sdate"]))
        {
            if (roleid == "6") //管理员按申请日期查询
                list.Add(" ReimburseDate >='" + Request.Form["accept_sdate"] + "'");
            else
                list.Add(" AcceptDate >='" + Request.Form["accept_sdate"] + "'");
        }
        //出纳处理截止日期
        if (!string.IsNullOrEmpty(Request.Form["accept_edate"]))
        {
            if (roleid == "6") //管理员按申请日期查询
                list.Add(" ReimburseDate <='" + Request.Form["accept_edate"] + "'");
            else
                list.Add(" AcceptDate <='" + Request.Form["accept_edate"] + "'");
        }
        //出纳处理日期未选择，默认只显示当年数据（出纳,处长,管理员,浏览用户）
        //if (string.IsNullOrEmpty(Request.Form["accept_sdate"]) && string.IsNullOrEmpty(Request.Form["accept_edate"]) && (roleid == "3" || roleid == "4" || roleid == "6" || roleid == "7"))
        //    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //-----------2017年1月8日修改
        //管理员默认显示当年数据（处长,管理员,浏览用户）
        if (string.IsNullOrEmpty(Request.Form["accept_sdate"]) && string.IsNullOrEmpty(Request.Form["accept_edate"]) && (roleid == "4" || roleid == "6" || roleid == "7"))
            list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//
        //按额度编号
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" outlayid like'%" + Request.Form["outlayid"] + "%'");
        //按经费类别
        if (!string.IsNullOrEmpty(Request.Form["outlayCategory"]))
            list.Add(" outlayCategory ='" + Request.Form["outlayCategory"] + "'");
        //按办理编号
        if (!string.IsNullOrEmpty(Request.Form["reimburseNo"]))
            list.Add(" reimburseNo like'%" + Request.Form["reimburseNo"] + "%'");
        //按单位查询
        //基层用户只获取自己的信息
        if (roleid == "1")
            list.Add(" a.deptid= " + deptid);
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" a.deptid ='" + Request.Form["deptid"] + "'");
        }
        //按审核状态查询
        if (!string.IsNullOrEmpty(Request.Form["status"]))
            list.Add(" status =" + Request.Form["status"]);
        //默认显示数据设置,转账支出无已审核部分退回(4)的状态记录
        //基层用户(1)显示全部信息；稽核(2)默认显示已提交待审核(1)和被出纳退回(2)，可查询1，2和已审核(3)和的记录；出纳(3)显示稽核已审核(3)，finishStatus:未受理(0),已受理(1)的记录；可查询已办结(2)的记录;管理员(6)显示finishStatus(2)已办结的，可查询待受理和已受理的
        //稽核显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "2")
            list.Add("(status>0 and status<3) ");
        //出纳显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "3")
            list.Add(" status>2 ");
        //按结报状态查询
        if (!string.IsNullOrEmpty(Request.Form["finishstatus"]))
            list.Add(" finishstatus= " + Request.Form["finishstatus"].ToString());
        else
        {
            if (roleid == "6")
                list.Add(" finishstatus=2 ");
            else
                list.Add(" finishstatus<2");
        }
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" a.deptid in (" + scopeDepts + ") ");
        //经费类别：1：公用；2：专项，用来判断显示基层用户公用经费报销或者专项经费报销
        string type = Convert.ToString(Request.QueryString["type"]);
        //基层用户根据经费类别不同在不同页面显示转账报销明细，其他用户全部显示
        if (roleid == "1")
            list.Add(" type=" + type);
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取转账支出报销表Reimburse_AccountPay数据 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetAccountPay()
    {
        int total = 0;
        string where = SetQueryConditionForAccount();
        string tableName = "Reimburse_AccountPay a join department b on a.deptid=b.deptid";
        string fieldStr = "a.*,b.deptname";

        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "reimburseoutlay", "reimbursedate", "合计"));
    }
    /// <summary>
    /// 通过ID获取转账支出明细表Reimburse_AccountPay
    /// </summary>
    public void GetAccountReimburseByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        string sql = "select a.*,b.deptname from Reimburse_AccountPay a join department b on a.deptid=b.deptid where a.id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 设置公务卡报销表查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForCard()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //申请开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" ReimburseDate >='" + Request.Form["sdate"] + "'");
        //申请截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" ReimburseDate <='" + Request.Form["edate"] + "'");
        //基层用户数据显示条件
        if (roleid == "1")
        {
            //未选择申请日期
            if (string.IsNullOrEmpty(Request.Form["sdate"]) && string.IsNullOrEmpty(Request.Form["edate"]))
            {
                //存在上面未送审支出申请,显示全部未送审申请
                if (IsExistUnsendReimburse("cardpay"))
                {
                    list.Add(" status=0 ");
                }
                else //不存在，则显示当年数据
                    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
            }
        }
        //--------------------------------------------------------------//
        //稽核处理开始日期
        if (!string.IsNullOrEmpty(Request.Form["audit_sdate"]))
            list.Add(" AuditDate >='" + Request.Form["audit_sdate"] + "'");
        //稽核处理截止日期
        if (!string.IsNullOrEmpty(Request.Form["audit_edate"]))
            list.Add(" AuditDate <='" + Request.Form["audit_edate"] + "'");
        //稽核处理日期未选择，默认只显示当年数据(稽核用户)
        //if (string.IsNullOrEmpty(Request.Form["audit_sdate"]) && string.IsNullOrEmpty(Request.Form["audit_edate"]) && roleid == "2")
        //    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//

        //出纳、处长、管理员、浏览用户处理开始日期
        if (!string.IsNullOrEmpty(Request.Form["accept_sdate"]))
        {
            if (roleid == "6") //管理员按申请日期查询
                list.Add(" ReimburseDate >='" + Request.Form["accept_sdate"] + "'");
            else
                list.Add(" AcceptDate >='" + Request.Form["accept_sdate"] + "'");
        }
        //出纳处理截止日期
        if (!string.IsNullOrEmpty(Request.Form["accept_edate"]))
        {
            if (roleid == "6") //管理员按申请日期查询
                list.Add(" ReimburseDate <='" + Request.Form["accept_edate"] + "'");
            else
                list.Add(" AcceptDate <='" + Request.Form["accept_edate"] + "'");
        }
        //出纳处理日期未选择，默认只显示当年数据（出纳,处长,管理员,浏览用户）
        //if (string.IsNullOrEmpty(Request.Form["accept_sdate"]) && string.IsNullOrEmpty(Request.Form["accept_edate"]) && (roleid == "3" || roleid == "4" || roleid == "6" || roleid == "7"))
        //    list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //-----------2017年1月8日修改
        //管理员默认显示当年数据（处长,管理员,浏览用户）
        if (string.IsNullOrEmpty(Request.Form["accept_sdate"]) && string.IsNullOrEmpty(Request.Form["accept_edate"]) && (roleid == "4" || roleid == "6" || roleid == "7"))
            list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//
        //按额度编号
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" outlayid like'%" + Request.Form["outlayid"] + "%'");
        //按经费类别
        if (!string.IsNullOrEmpty(Request.Form["outlayCategory"]))
            list.Add(" outlayCategory ='" + Request.Form["outlayCategory"] + "'");
        //按办理编号
        if (!string.IsNullOrEmpty(Request.Form["reimburseNo"]))
            list.Add(" reimburseNo like'%" + Request.Form["reimburseNo"] + "%'");
        //按单位查询
        //基层用户只获取自己的信息
        if (roleid == "1")
            list.Add(" a.deptid= " + deptid);
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" a.deptid ='" + Request.Form["deptid"] + "'");
        }
        //按审核状态查询
        if (!string.IsNullOrEmpty(Request.Form["status"]))
            list.Add(" status =" + Request.Form["status"]);
        //默认显示数据设置,公务卡支出无已审核部分退回(4)的状态记录
        //基层用户(1)显示全部信息；稽核(2)默认显示已提交待审核(1)和被出纳退回(2)，可查询1，2和已审核(3)和的记录；出纳(3)显示稽核已审核(3)，finishStatus:未受理(0),已受理(1)的记录；可查询已办结(2)的记录;管理员(6)显示finishStatus(2)已办结的，可查询待受理和已受理的
        //稽核显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "2")
            list.Add("(status>0 and status<3) ");
        //出纳显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "3")
            list.Add(" status>2 ");
        //按结报状态查询
        if (!string.IsNullOrEmpty(Request.Form["finishstatus"]))
            list.Add(" finishstatus= " + Request.Form["finishstatus"].ToString());
        else
        {
            if (roleid == "6")
                list.Add(" finishstatus=2 ");
            else
                list.Add(" finishstatus<2");
        }
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" a.deptid in (" + scopeDepts + ") ");
        //经费类别：1：公用；2：专项，用来判断显示基层用户公用经费报销或者专项经费报销
        string type = Convert.ToString(Request.QueryString["type"]);
        //基层用户根据经费类别不同在不同页面显示转账报销明细，其他用户全部显示
        if (roleid == "1")
            list.Add(" type=" + type);
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取公务卡支出报销表Reimburse_CardPay数据 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetCardPay()
    {
        int total = 0;
        string where = SetQueryConditionForCard();
        string tableName = "Reimburse_CardPay a join department b on a.deptid=b.deptid";
        string fieldStr = "a.*,b.deptname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "reimburseoutlay", "reimbursedate", "合计"));
    }
    /// <summary>
    /// 通过ID获取转账公务卡支出明细表Reimburse_CardPay
    /// </summary>
    public void GetCardReimburseByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        string sql = "select a.*,b.deptname from Reimburse_CardPay a join department b on a.deptid=b.deptid where a.id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #region 基层用户操作
    /// <summary>
    /// 保存现金支出记录和每笔凭证,设置为待送审状态(0)--基层用户
    /// </summary>
    public void SaveCashReimburse()
    {

        /* 1、获取办理编号,判断编号前6为是否为当年当月，如果是则追加1，不是设置为0001
         * 2、通过传递的经费类别type，来设置要更新的是公用经费还是专项经费
         * 3、设置办理时间为当天，获取请求参数，报销金额、单位名称，经办人等
         * 4、设置status为0，finishstatus 为0
         * 5、获取reimburseOutlay,分割为数组，批量写入每笔凭证
         * 6、更新经费的可用额度值
         */
        //1、办理编号
        int reimburseNo = GetReimburseNo();
        StringBuilder sql = new StringBuilder();
        //更新报销编号的值
        sql.Append("update autono set reimburseno=@reimburseno;");
        //2、报销的经费来源：1：公用；2：专项
        int type = 0;
        int.TryParse(Request.Form["type"], out type);
        //3、保存现金报销记录
        //获取参数
        //经费来源数据表ID
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //办理日期
        string reimburseDate = DateTime.Now.ToString("yyyy-MM-dd");
        //报销金额
        decimal reimburseOutlay = 0.00M;
        decimal.TryParse(Request.Form["reimburseOutlay"], out reimburseOutlay);
        //经费类别
        string outlayCategory = Convert.ToString(Request.Form["outlaycategory"]);
        //经费类别被删除，不存在无法添加支出登记
        if (String.IsNullOrEmpty(Request.Form["outlaycategory"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"经费类别不存在，无法提交！" + outlayCategory + "\"}");
            return;
        }
        //报销人
        string reimburseUser = Convert.ToString(Request.Form["reimburseUser"]);
        //支出科目
        string expenseSubject = Convert.ToString(Request.Form["expenseSubject"]);
        //支出摘要
        string memo = Convert.ToString(Request.Form["memo"]);
        //专项经费的额度编号，公共经费没有该项
        string outlayId = string.IsNullOrEmpty(Request.Form["outlayId"]) ? "0" : Convert.ToString(Request.Form["outlayId"]);
        sql.Append("insert Reimburse_CashPay values(@deptid,@reimburseno,@reimbursedate,@reimburseoutlay,0,");
        sql.Append("@outlaycategory,@expensesubject,@memo,@username,@reimburseuser,0,0,@type,@outlayid,'','','','','');");
        //设定参数
        List<SqlParameter> _paras = new List<SqlParameter>();
        _paras.Add(new SqlParameter("@id", id));
        _paras.Add(new SqlParameter("@deptid", deptid));
        _paras.Add(new SqlParameter("@reimburseno", reimburseNo));
        _paras.Add(new SqlParameter("@reimbursedate", reimburseDate));
        _paras.Add(new SqlParameter("@reimburseoutlay", reimburseOutlay));
        _paras.Add(new SqlParameter("@outlaycategory", outlayCategory));
        _paras.Add(new SqlParameter("@expensesubject", expenseSubject));
        _paras.Add(new SqlParameter("@memo", memo));
        _paras.Add(new SqlParameter("@username", userName));
        _paras.Add(new SqlParameter("@reimburseuser", reimburseUser));
        _paras.Add(new SqlParameter("@type", type));
        _paras.Add(new SqlParameter("@outlayid", outlayId));
        //5、获取每一笔报销金额
        string inputOutlay = Convert.ToString(Request.Form["inputoutlay"]);
        string[] arrInput = inputOutlay.Split(',');
        decimal singleOutlay;
        //通过计算每笔额度得到的总额度
        decimal computeAllSingleOutlay = 0.00M;
        //遍历单笔金额，生成sql语句,并定义参数
        for (int i = 0; i < arrInput.Length; i++)
        {
            if (decimal.TryParse(arrInput[i], out singleOutlay))
            {
                //计算总额度
                computeAllSingleOutlay += singleOutlay;
                sql.Append("insert into Reimburse_CashPayDetail values(@reimburseno,@singleoutlay" + i.ToString() + ",1);");
                _paras.Add(new SqlParameter("@singleoutlay" + i.ToString(), singleOutlay));
            }

        }
        if (reimburseOutlay != computeAllSingleOutlay)
        {
            Response.Write("{\"success\":false,\"msg\":\"报销总金额与单笔金额总和不一致，请检查输入！\"}");
            return;
        }
        //6、更新经费可用额度
        //根据type的值判断经费表
        if (type == 1) //公用
            sql.Append("update PublicOutlay set UnusedOutlay= UnusedOutlay-@reimburseoutlay where id=@id;");
        if (type == 2)//专项
            sql.Append("update SpecialOutlay set UnusedOutlay= UnusedOutlay-@reimburseoutlay where id=@id;");
        //使用事务提交操作
        using (SqlConnection conn = SqlHelper.GetConnection())
        {
            conn.Open();
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    SqlHelper.ExecuteNonQuery(trans, CommandType.Text, sql.ToString(), _paras.ToArray());
                    //SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), _paras.ToArray());
                    trans.Commit();
                    Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
                }
                catch
                {
                    trans.Rollback();
                    Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
                    throw;
                }
            }
        }
    }
    /// <summary>
    /// 获取被退回的现金支出单笔凭证，并恢复公用/专项经费的可用额度
    /// </summary>
    public void GetBackSingleCashReimburse()
    {
        /*1、获取现金支出凭证表Reimburse_CashPayDetail的ID
         *2、通过ID获取办理编号ReimburseNo和要恢复的单笔凭证金额SingleOutlay
         *3、通过办理编号ReimburseNo在现金支出明细表Reimburse_CashPay中获取部门编号deptid和经费支出来源type和
         *   经费追加编号OutlayId
         *4、根据经费支出来源type设置要恢复额度的经费表1：PublicOutlay，2：SpecialOutlay
         *5、根据deptid恢复公用经费可用额度，根据deptid和OutlayId来恢复专项经费的可用额度
         *6、更新现金支出凭证表Reimburse_CashPayDetail当前记录的status为-2：已恢复
         */
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        decimal singleOutlay = 0;
        int deptId = 0, type = 0, outlayId = 0;
        //更新sql语句
        string updateSql = "";
        //更新语句的参数
        List<SqlParameter> paras = new List<SqlParameter>();
        StringBuilder sql = new StringBuilder();
        sql.Append("select a.singleoutlay,b.deptid,b.[type],b.outlayid from Reimburse_CashPayDetail a ");
        sql.Append("join Reimburse_CashPay b on a.reimburseno=b.reimburseno where a.id=@id");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), new SqlParameter("@id", id));
        if (ds.Tables[0].Rows.Count == 1)//获取各项的值
        {
            decimal.TryParse(ds.Tables[0].Rows[0][0].ToString(), out singleOutlay);
            int.TryParse(ds.Tables[0].Rows[0][1].ToString(), out deptId);
            int.TryParse(ds.Tables[0].Rows[0][2].ToString(), out type);
            int.TryParse(ds.Tables[0].Rows[0][3].ToString(), out outlayId);
        }
        else//获取不到值
        {
            Response.Write("{\"success\":false,\"msg\":\"执行出错,无此记录\"}");
            return;
        }
        //更新当前现金支出凭证的状态
        updateSql += "update Reimburse_CashPayDetail set status=-2 where id=@id;";
        //初始化更新参数
        paras.Add(new SqlParameter("@id", id));
        paras.Add(new SqlParameter("@singleOutlay", singleOutlay));
        paras.Add(new SqlParameter("@deptid", deptId));
        if (type == 1)//公用经费额度恢复
        {
            updateSql += "Update PublicOutlay set UnusedOutlay=UnusedOutlay+@singleOutlay where deptid=@deptid";
        }
        else if (type == 2)//专项经费额度恢复
        {
            updateSql += "Update SpecialOutlay set UnusedOutlay=UnusedOutlay+@singleOutlay where deptid=@deptid and outlayid=@outlayid";
            //添加经费额度编号参数
            paras.Add(new SqlParameter("@outlayid", outlayId));
        }
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, updateSql, paras.ToArray());
        if (result > 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,额度已恢复\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");

    }
    /// <summary>
    /// 送审待送审的现金支出申请
    /// </summary>
    public void SendCashReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter para = new SqlParameter("@id", id);
        string sql = "Update Reimburse_CashPay set status=1 where id=@id and status=0";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 删除待送审的现金支出申请
    /// </summary>
    public void RemoveCashReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //存储过程返回值
        int result;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@result",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Direction = ParameterDirection.ReturnValue;
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "RemoveUnSendCashReimburse", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该现金支出项申请被删除！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该现金支出对应的经费不存在，不能删除！\"}");
        if (result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    /// <summary>
    /// 保存转账支出记录，同城和异地方式
    /// </summary>
    public void SaveAccountReimburse()
    {
        /* 1、获取办理编号
   * 2、通过传递的经费类别type，来设置要更新的是公用经费还是专项经费
   * 3、设置办理时间为当天，获取请求参数，报销金额、单位名称，经办人,收款单位,银行账号，开户行等
   * 4、设置status为0，finishstatus 为0
   * 5、保存支出记录，
   * 6、更新该基层单位的转账信息，要求deptid和accountnumber 不能重复
   * 7、更新经费的可用额度值
   */
        //1、办理编号
        int reimburseNo = GetReimburseNo();
        StringBuilder sql = new StringBuilder();
        //更新报销编号的值
        sql.Append("update autono set reimburseno=@reimburseno;");
        //2、报销的经费来源：1：公用；2：专项
        int type = 0;
        int.TryParse(Request.Form["type"], out type);
        //3、获取参数
        //经费来源数据表ID
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //办理日期
        string reimburseDate = DateTime.Now.ToString("yyyy-MM-dd");
        //报销金额
        decimal reimburseOutlay = Convert.ToDecimal(Request.Form["reimburseOutlay"]);
        //经费类别
        string outlayCategory = Convert.ToString(Request.Form["outlaycategory"]);
        //经费类别被删除，不存在无法添加支出登记
        if (String.IsNullOrEmpty(Request.Form["outlaycategory"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"经费类别不存在，无法提交！" + outlayCategory + "\"}");
            return;
        }
        //报销人
        string reimburseUser = Convert.ToString(Request.Form["reimburseUser"]);
        //支出科目
        string expenseSubject = Convert.ToString(Request.Form["expenseSubject"]);
        //支出摘要
        string memo = Convert.ToString(Request.Form["memo"]);
        //专项经费的额度编号，公共经费没有该项
        string outlayId = string.IsNullOrEmpty(Request.Form["outlayId"]) ? "0" : Convert.ToString(Request.Form["outlayId"]);
        //支出方式
        int payment = Convert.ToInt32(Request.Form["payment"]);
        //收款单位;由于网络原因获取不到payeename的值提示
        if (String.IsNullOrEmpty(Request.Form["payeeName"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"未获取到“收款单位”的值，请重试！\"}");
            return;
        }
        string payeeName = Convert.ToString(Request.Form["payeeName"]);
        //银行账号
        string accountNumber = Convert.ToString(Request.Form["accountNumber"]);
        //开户行
        string bankName = Convert.ToString(Request.Form["bankName"]);
        //4,5、保存转账支出登记
        sql.Append("insert Reimburse_AccountPay values");
        sql.Append("(@deptid,@reimburseno,@reimbursedate,@reimburseoutlay,@payment,");
        sql.Append("@outlaycategory,@expensesubject,@memo,@payeename,@accountnumber,@bankname,");
        sql.Append("@username,@reimburseuser,0,0,@type,@outlayid,'','','','','');");
        //设定参数
        List<SqlParameter> _paras = new List<SqlParameter>();
        _paras.Add(new SqlParameter("@id", id));
        _paras.Add(new SqlParameter("@deptid", deptid));
        _paras.Add(new SqlParameter("@reimburseno", reimburseNo));
        _paras.Add(new SqlParameter("@reimbursedate", reimburseDate));
        _paras.Add(new SqlParameter("@reimburseoutlay", reimburseOutlay));
        _paras.Add(new SqlParameter("@payment", payment));
        _paras.Add(new SqlParameter("@outlaycategory", outlayCategory));
        _paras.Add(new SqlParameter("@expensesubject", expenseSubject));
        _paras.Add(new SqlParameter("@memo", memo));
        _paras.Add(new SqlParameter("@payeename", payeeName));
        _paras.Add(new SqlParameter("@accountnumber", accountNumber));
        _paras.Add(new SqlParameter("@bankname", bankName));
        _paras.Add(new SqlParameter("@username", userName));
        _paras.Add(new SqlParameter("@reimburseuser", reimburseUser));
        _paras.Add(new SqlParameter("@type", type));
        _paras.Add(new SqlParameter("@outlayid", outlayId));
        //6、判断更新当前单位转账支出收款单位信息
        //不存在当前收款账号信息，则插入新数据
        sql.Append("if not exists (select * from payeeinfo where  accountnumber=@accountnumber)");
        sql.Append(" insert into payeeinfo values(@payeename,@accountnumber,@bankname); ");
        //存在，则更新当前用户的银行账号信息
        sql.Append(" else ");
        sql.Append("update payeeinfo set PayeeName=@payeename,BankName=@bankname where    AccountNumber=@accountnumber;");
        //7、更新经费可用额度
        //根据type的值判断经费表
        if (type == 1) //公用
            sql.Append("update PublicOutlay set UnusedOutlay= UnusedOutlay-@reimburseoutlay where id=@id;");
        if (type == 2)//专项
            sql.Append("update SpecialOutlay set UnusedOutlay= UnusedOutlay-@reimburseoutlay where id=@id;");
        //使用事务提交操作
        using (SqlConnection conn = SqlHelper.GetConnection())
        {
            conn.Open();
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    SqlHelper.ExecuteNonQuery(trans, CommandType.Text, sql.ToString(), _paras.ToArray());
                    trans.Commit();
                    Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
                }
                catch
                {
                    trans.Rollback();
                    Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
                    throw;
                }
            }
        }
    }
    /// <summary>
    /// 送审待送审的转账支出申请
    /// </summary>
    public void SendAccountReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter para = new SqlParameter("@id", id);
        string sql = "Update Reimburse_AccountPay set status=1 where id=@id and status=0";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 删除待送审的转账支出申请
    /// </summary>
    public void RemoveAccountReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //存储过程返回值
        int result;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@result",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Direction = ParameterDirection.ReturnValue;
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "RemoveUnSendAccountReimburse", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该转账支出项申请被删除！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该转账支出对应的经费额度不存在，不能删除！\"}");
        if (result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    /// <summary>
    /// 保存公务卡支出记录
    /// </summary>
    public void SaveCardReimburse()
    {
        /* 1、获取办理编号
   * 2、通过传递的经费类别type，来设置要更新的是公用经费还是专项经费
   * 3、设置办理时间为当天，获取请求参数，报销金额、单位名称，经办人,持卡人,卡号,消费时间等
   * 4、设置status为0，finishstatus 为0
   * 5、保存支出记录，
   * 6、更新该基层单位的转账信息，要求deptid和accountnumber 不能重复
   * 7、更新经费的可用额度值
   */
        //1、办理编号
        int reimburseNo = GetReimburseNo();
        StringBuilder sql = new StringBuilder();
        //更新报销编号的值
        sql.Append("update autono set reimburseno=@reimburseno;");
        //2、报销的经费来源：1：公用；2：专项
        int type = 0;
        int.TryParse(Request.Form["type"], out type);
        //3、获取参数
        //经费来源数据表ID
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //办理日期
        string reimburseDate = DateTime.Now.ToString("yyyy-MM-dd");
        //报销金额
        decimal reimburseOutlay = Convert.ToDecimal(Request.Form["reimburseOutlay"]);
        //经费类别
        string outlayCategory = Convert.ToString(Request.Form["outlaycategory"]);
        //经费类别被删除，不存在无法添加支出登记
        if (String.IsNullOrEmpty(Request.Form["outlaycategory"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"经费类别不存在，无法提交！" + outlayCategory + "\"}");
            return;
        }
        //报销人
        string reimburseUser = Convert.ToString(Request.Form["reimburseUser"]);
        //支出科目
        string expenseSubject = Convert.ToString(Request.Form["expenseSubject"]);
        //支出摘要
        string memo = Convert.ToString(Request.Form["memo"]);
        //专项经费的额度编号，公共经费没有该项
        string outlayId = string.IsNullOrEmpty(Request.Form["outlayId"]) ? "0" : Convert.ToString(Request.Form["outlayId"]);
        //持卡人
        if (String.IsNullOrEmpty(Request.Form["cardholder"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"未获取到“持卡人”的值，请重试！\"}");
            return;
        }
        string cardholder = Convert.ToString(Request.Form["cardholder"]);
        //卡号
        string cardNumber = Convert.ToString(Request.Form["cardNumber"]);
        //消费时间
        string spendingTime = Convert.ToString(Request.Form["spendingTime"]);
        //4,5、保存转账支出登记
        sql.Append("insert Reimburse_CardPay values");
        sql.Append("(@deptid,@reimburseno,@reimbursedate,@reimburseoutlay,");
        sql.Append("@outlaycategory,@expensesubject,@memo,@cardholder,@cardnumber,@spendingtime,");
        sql.Append("@username,@reimburseuser,0,0,@type,@outlayid,'','','','','');");
        //设定参数
        List<SqlParameter> _paras = new List<SqlParameter>();
        _paras.Add(new SqlParameter("@id", id));
        _paras.Add(new SqlParameter("@deptid", deptid));
        _paras.Add(new SqlParameter("@reimburseno", reimburseNo));
        _paras.Add(new SqlParameter("@reimbursedate", reimburseDate));
        _paras.Add(new SqlParameter("@reimburseoutlay", reimburseOutlay));
        _paras.Add(new SqlParameter("@outlaycategory", outlayCategory));
        _paras.Add(new SqlParameter("@expensesubject", expenseSubject));
        _paras.Add(new SqlParameter("@memo", memo));
        _paras.Add(new SqlParameter("@cardholder", cardholder));
        _paras.Add(new SqlParameter("@cardnumber", cardNumber));
        _paras.Add(new SqlParameter("@spendingtime", spendingTime));
        _paras.Add(new SqlParameter("@username", userName));
        _paras.Add(new SqlParameter("@reimburseuser", reimburseUser));
        _paras.Add(new SqlParameter("@type", type));
        _paras.Add(new SqlParameter("@outlayid", outlayId));
        //6、判断更新当前单位转账支出收款单位信息
        //不存在当前收款账号信息，则插入新数据
        sql.Append("if not exists (select * from cardinfo where deptid=@deptid and cardnumber=@cardnumber)");
        sql.Append(" insert into cardinfo values(@deptid,@cardholder,@cardnumber); ");
        //存在，则更新当前用户的银行账号信息
        sql.Append(" else ");
        sql.Append("update cardinfo set cardholder=@cardholder where deptid=@deptid and cardNumber=@cardnumber;");
        //7、更新经费可用额度
        //根据type的值判断经费表
        if (type == 1) //公用
            sql.Append("update PublicOutlay set UnusedOutlay= UnusedOutlay-@reimburseoutlay where id=@id;");
        if (type == 2)//专项
            sql.Append("update SpecialOutlay set UnusedOutlay= UnusedOutlay-@reimburseoutlay where id=@id;");
        //使用事务提交操作
        using (SqlConnection conn = SqlHelper.GetConnection())
        {
            conn.Open();
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    SqlHelper.ExecuteNonQuery(trans, CommandType.Text, sql.ToString(), _paras.ToArray());
                    trans.Commit();
                    Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
                }
                catch
                {
                    trans.Rollback();
                    Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
                    throw;
                }
            }
        }
    }
    /// <summary>
    /// 送审待送审的公务卡支出申请
    /// </summary>
    public void SendCardReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter para = new SqlParameter("@id", id);
        string sql = "Update Reimburse_CardPay set status=1 where id=@id and status=0";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 删除待送审的公务卡支出申请
    /// </summary>
    public void RemoveCardReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //存储过程返回值
        int result;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@result",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Direction = ParameterDirection.ReturnValue;
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "RemoveUnSendCardReimburse", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该公务卡支出项申请被删除！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该公务卡支出对应的经费额度不存在，不能删除！\"}");
        if (result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    #endregion
    #region 稽核员操作
    /// <summary>
    /// 审核单笔现金支出凭证，并更新已审核额度的值
    /// </summary>
    public void AuditSingleCashReimburse()
    {
        //现金支出表Reimburse_CashPay中的ID
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        ////现金支出凭证表Reimburse_CashPayDetail表中的ID
        int singleCashId = 0;
        int.TryParse(Request.Form["singlecashid"], out singleCashId);
        StringBuilder sql = new StringBuilder();
        //审核单笔凭证，每笔支出凭证的状态：-1：被稽核退回；1：待稽核审核；2：已审核；
        sql.Append("update Reimburse_CashPayDetail set status=2 where id=@singleCashId;");
        //获取当前已审核通过所有单笔凭证的金额之和
        sql.Append("set @auditCash=dbo.F_SumEveryAuditSingleCash(@id);");
        decimal auditOutlay;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@singleCashId",SqlDbType.Int),
            new SqlParameter("@auditCash",SqlDbType.Decimal),
            new SqlParameter("@id",SqlDbType.Int)
        };
        paras[0].Value = singleCashId;
        paras[1].Direction = ParameterDirection.Output;
        paras[1].Precision = (byte)18;
        paras[1].Scale = (byte)2;
        paras[2].Value = id;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        auditOutlay = (decimal)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\",\"auditoutlay\":" + auditOutlay.ToString() + "}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    ///  退回单笔现金支出凭证给基层用户
    /// </summary>
    public void BackSingleCashReimburse()
    {
        ////现金支出凭证表Reimburse_CashPayDetail表中的ID
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        StringBuilder sql = new StringBuilder();
        //退回单笔凭证，每笔支出凭证的状态：-1：被稽核退回；1：待稽核审核；2：已审核；
        sql.Append("update Reimburse_CashPayDetail set status=-1 where id=@id;");
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int)
        };
        paras[0].Value = id;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 审核现金支出，设置现金支出记录状态，审核或退回，在提交时要做判断，
    /// 1、单笔凭证有未做处理的即在提交时仍为待审核状态的要提示不能提交
    /// 2、单笔全部审核通过的，提交时直接审核该记录为已审核，设置审核金额（Reimburse_CashPay表中的AuditCashOutlay）
    /// 3、单笔全部退回的，提交时将该记录设置为被退回，退回给基层用户，审核金额为0
    /// 4、单笔凭证有审核通过有退回的，提交时将该记录设置为部分已审核，设置审核金额，基层用户可取回被退回金额
    /// </summary>
    public void AuditCashReimburse()
    {
        //数据表Reimburse_CashPay的ID
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //办理编号
        int reimburseNo = 0;
        int.TryParse(Request.Form["reimburseNo"], out reimburseNo);
        //支出科目
        string expenseSubject = Convert.ToString(Request.Form["expenseSubject"]);
        //稽核审核意见
        string auditorcomment = Convert.ToString(Request.Form["auditorcomment"]);
        //审核通过的金额之和
        decimal auditCahsOutlay = 0;
        decimal.TryParse(Request.Form["auditOutlay"], out auditCahsOutlay);
        int result = 0;
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@reimburseno",SqlDbType.Int),
            new SqlParameter("@expensesubject",SqlDbType.VarChar),
            new SqlParameter("@auditcashoutlay",SqlDbType.Decimal),
            new SqlParameter("@auditor",SqlDbType.NVarChar),
            new SqlParameter("@auditdate",SqlDbType.VarChar),
            new SqlParameter("@auditorcomment",SqlDbType.VarChar),
            new SqlParameter("@result",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Value = reimburseNo;
        paras[2].Value = expenseSubject;
        paras[3].Value = auditCahsOutlay;
        paras[4].Value = userName;
        paras[5].Value = DateTime.Now.ToString("yyyy-MM-dd");
        paras[6].Value = auditorcomment;
        paras[7].Direction = ParameterDirection.ReturnValue;
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "AuditCashReimburse", paras);
        result = (int)paras[7].Value;
        if (result == 1)//有未处理凭证不能提交
            Response.Write("{\"success\":false,\"msg\":\"有未处理的现金支出凭证，请处理后再提交！\"}");
        if (result == 3)
            Response.Write("{\"success\":true,\"msg\":\"审核成功，设置状态为已审核\"}");
        if (result == 4)
            Response.Write("{\"success\":true,\"msg\":\"审核成功，设置状态为部分审核\"}");
        if (result == -1)
            Response.Write("{\"success\":true,\"msg\":\"审核成功，设置状态为被退回\"}");
    }
    //审核转账支出Reimburse_AccountPay，更新支出科目和状态
    public void AuditAccountReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        //支出科目
        string expenseSubject = Convert.ToString(Request.Form["expenseSubject"]);
        string sql = "update Reimburse_AccountPay set status=3,expenseSubject=@expensesubject,Auditor=@auditor,AuditDate=@auditdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@expensesubject",expenseSubject),
            new SqlParameter("@auditor",userName),
            new SqlParameter("@auditdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 退回转账支出给基层用户，并恢复可用额度
    /// 1、获取转账支出表Reimburse_AccountPay的id
    /// 2、通过ID获取该记录的type,1:公用经费支出；2：专项经费支出，部门编号deptid,专项经费的额度编号outlayid，申请支出的经费额度ReimburseOutlay
    /// 3、根据经费支出来源type设置要恢复额度的经费表1：PublicOutlay，2：SpecialOutlay
    /// 4、根据deptid恢复公用经费可用额度，根据deptid和OutlayId来恢复专项经费的可用额度
    /// 5、更新转账支出表Reimburse_AccountPay当前记录的status为-1：被稽核退回
    /// </summary>
    public void BackAccountReimburse()
    {
        //1、
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //增加稽核退回意见
        string auditorcomment = Convert.ToString(Request.Form["auditorcomment"]);
        decimal reimburseOutlay = 0;
        int deptId = 0, type = 0, outlayId = 0;

        //判断是否填写退回意见
        if (auditorcomment.Trim().Length == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"请填写稽核退回意见！\"}");
            return;
        }
        //更新sql语句
        string updateSql = "";
        //更新语句的参数
        List<SqlParameter> paras = new List<SqlParameter>();
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseOutlay,deptid,type,outlayid from  Reimburse_AccountPay where id=@id");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), new SqlParameter("@id", id));
        //2、
        if (ds.Tables[0].Rows.Count == 1)//获取各项的值
        {
            decimal.TryParse(ds.Tables[0].Rows[0][0].ToString(), out reimburseOutlay);
            int.TryParse(ds.Tables[0].Rows[0][1].ToString(), out deptId);
            int.TryParse(ds.Tables[0].Rows[0][2].ToString(), out type);
            int.TryParse(ds.Tables[0].Rows[0][3].ToString(), out outlayId);
        }
        else//获取不到值
        {
            Response.Write("{\"success\":false,\"msg\":\"执行出错,无此记录\"}");
            return;
        }
        //5、更新当前转账支出凭证的状态
        updateSql += "update Reimburse_AccountPay set status=-1,Auditor=@auditor,AuditDate=@auditdate,auditorcomment=@auditorcomment where id=@id;";
        //初始化更新参数
        paras.Add(new SqlParameter("@id", id));
        paras.Add(new SqlParameter("@reimburseOutlay", reimburseOutlay));
        paras.Add(new SqlParameter("@deptid", deptId));
        paras.Add(new SqlParameter("@auditor", userName));
        paras.Add(new SqlParameter("@auditdate", DateTime.Now.ToString("yyyy-MM-dd")));
        paras.Add(new SqlParameter("@auditorcomment", auditorcomment));
        //3、
        if (type == 1)//公用经费额度恢复
        {
            updateSql += "Update PublicOutlay set UnusedOutlay=UnusedOutlay+@reimburseOutlay where deptid=@deptid";
        }
        else if (type == 2)//专项经费额度恢复
        {
            updateSql += "Update SpecialOutlay set UnusedOutlay=UnusedOutlay+@reimburseOutlay where deptid=@deptid and outlayid=@outlayid";
            //添加经费额度编号参数
            paras.Add(new SqlParameter("@outlayid", outlayId));
        }
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, updateSql, paras.ToArray());
        if (result > 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,额度已恢复\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 审核公务卡支出Reimburse_CardPay，更新支出科目和状态
    /// </summary>
    public void AuditCardReimburse()
    {
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        //支出科目
        string expenseSubject = Convert.ToString(Request.Form["expenseSubject"]);
        string sql = "update Reimburse_CardPay set status=3,expenseSubject=@expensesubject,Auditor=@auditor,AuditDate=@auditdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@expensesubject",expenseSubject),
            new SqlParameter("@auditor",userName),
            new SqlParameter("@auditdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 退回公务卡支出给基层用户，并恢复可用额度
    /// 1、获取公务卡支出表Reimburse_CardPay的id
    /// 2、通过ID获取该记录的type,1:公用经费支出；2：专项经费支出，部门编号deptid,专项经费的额度编号outlayid，申请支出的经费额度ReimburseOutlay
    /// 3、根据经费支出来源type设置要恢复额度的经费表1：PublicOutlay，2：SpecialOutlay
    /// 4、根据deptid恢复公用经费可用额度，根据deptid和OutlayId来恢复专项经费的可用额度
    /// 5、更新公务卡支出表Reimburse_CardPay当前记录的status为-1：被稽核退回
    /// </summary>
    public void BackCardReimburse()
    {
        //1、
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        decimal reimburseOutlay = 0;
        int deptId = 0, type = 0, outlayId = 0;
        //增加稽核退回意见
        string auditorcomment = Convert.ToString(Request.Form["auditorcomment"]);
        //更新sql语句
        string updateSql = "";
        //判断是否填写退回意见
        if (auditorcomment.Trim().Length == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"请填写稽核退回意见！\"}");
            return;
        }
        //更新语句的参数
        List<SqlParameter> paras = new List<SqlParameter>();
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseOutlay,deptid,type,outlayid from  Reimburse_CardPay where id=@id");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), new SqlParameter("@id", id));
        //2、
        if (ds.Tables[0].Rows.Count == 1)//获取各项的值
        {
            decimal.TryParse(ds.Tables[0].Rows[0][0].ToString(), out reimburseOutlay);
            int.TryParse(ds.Tables[0].Rows[0][1].ToString(), out deptId);
            int.TryParse(ds.Tables[0].Rows[0][2].ToString(), out type);
            int.TryParse(ds.Tables[0].Rows[0][3].ToString(), out outlayId);
        }
        else//获取不到值
        {
            Response.Write("{\"success\":false,\"msg\":\"执行出错,无此记录\"}");
            return;
        }
        //5、更新当前转账支出凭证的状态
        updateSql += "update Reimburse_CardPay set status=-1,Auditor=@auditor,AuditDate=@auditdate,auditorcomment=@auditorcomment where id=@id;";
        //初始化更新参数
        paras.Add(new SqlParameter("@id", id));
        paras.Add(new SqlParameter("@reimburseOutlay", reimburseOutlay));
        paras.Add(new SqlParameter("@deptid", deptId));
        paras.Add(new SqlParameter("@auditor", userName));
        paras.Add(new SqlParameter("@auditdate", DateTime.Now.ToString("yyyy-MM-dd")));
        paras.Add(new SqlParameter("@auditorcomment", auditorcomment));
        //3、
        if (type == 1)//公用经费额度恢复
        {
            updateSql += "Update PublicOutlay set UnusedOutlay=UnusedOutlay+@reimburseOutlay where deptid=@deptid";
        }
        else if (type == 2)//专项经费额度恢复
        {
            updateSql += "Update SpecialOutlay set UnusedOutlay=UnusedOutlay+@reimburseOutlay where deptid=@deptid and outlayid=@outlayid";
            //添加经费额度编号参数
            paras.Add(new SqlParameter("@outlayid", outlayId));
        }
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, updateSql, paras.ToArray());
        if (result > 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,额度已恢复\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    #endregion
    #region 出纳操作
    /// <summary>
    /// 受理已审核和已审核部分退回的现金支出明细
    /// </summary>
    public void AcceptCashAudit()
    {
        //现金支出明细表Reimburse_CashPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_CashPay set finishstatus=1,Accepter=@accepter,AcceptDate=@acceptdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 退回稽核已审核和已审核部分退回的现金支出明细到稽核，由稽核退回给基层用户
    /// </summary>
    public void BackCashAudit()
    {
        /*处理步骤
         * 1、获取请求的现金支出明细表Reimburse_CashPay的ID和办理编号reimburseNo
         * 2、设置现金支出明细表Reimburse_CashPay的审核状态status为2:被退回(稽核显示)，结报状态finishstatus不变
         * 3、在现金支出凭证表Reimburse_CashPayDetail中设置当前办理编号并且状态status为2：已审核的记录的status为3：被出纳退回
         */
        int id = 0, reimburseNo = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        int.TryParse(Request.Form["reimburseno"].ToString(), out reimburseNo);
        StringBuilder sql = new StringBuilder();
        sql.Append("update Reimburse_CashPay set status=2,Accepter=@accepter,AcceptDate=@acceptdate where id=@id;");
        sql.Append("update Reimburse_CashPayDetail set status=3 where reimburseno=@reimburseno and status=2");
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@reimburseno",reimburseNo),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result > 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 办结已受理的现金支出明细
    /// </summary>
    public void FinishCashAccept()
    {
        //现金支出明细表Reimburse_CashPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_CashPay set finishstatus=2,Accepter=@accepter,AcceptDate=@acceptdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 受理已审核的转账支出明细
    /// </summary>
    public void AcceptAccountAudit()
    {
        //转账支出明细表Reimburse_AccountPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_AccountPay set finishstatus=1,Accepter=@accepter,AcceptDate=@acceptdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 退回稽核已审核的转账支出明细到稽核，由稽核退回给基层用户
    /// </summary>
    public void BackAccountAudit()
    {
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        StringBuilder sql = new StringBuilder();
        sql.Append("update Reimburse_AccountPay set status=2,Accepter=@accepter,AcceptDate=@acceptdate where id=@id;");
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 办结已受理的转账支出明细
    /// </summary>
    public void FinishAccountAccept()
    {
        //转账支出明细表Reimburse_AccountPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_AccountPay set finishstatus=2,Accepter=@accepter,AcceptDate=@acceptdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 受理已审核的公务卡支出明细
    /// </summary>
    public void AcceptCardAudit()
    {
        //转账支出明细表Reimburse_CardPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_CardPay set finishstatus=1,Accepter=@accepter,AcceptDate=@acceptdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 退回稽核已审核的转账公务卡支出明细到稽核，由稽核退回给基层用户
    /// </summary>
    public void BackCardAudit()
    {
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        StringBuilder sql = new StringBuilder();
        sql.Append("update Reimburse_CardPay set status=2,Accepter=@accepter,AcceptDate=@acceptdate where id=@id;");
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 办结已受理的公务卡支出明细
    /// </summary>
    public void FinishCardAccept()
    {
        //公务卡支出明细表Reimburse_CashPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_CardPay set finishstatus=2,Accepter=@accepter,AcceptDate=@acceptdate where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@accepter",userName),
            new SqlParameter("@acceptdate",DateTime.Now.ToString("yyyy-MM-dd"))
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    #endregion
    #region 管理员操作
    /// <summary>
    /// 管理员,取消现金支出办结，退回到待受理
    /// </summary>
    public void CancelFinishCash()
    {
        //现金支出明细表Reimburse_CashPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_CashPay set finishstatus=0 where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 管理员,取消转账支出办结，退回到待受理
    /// </summary>
    public void CancelFinishAccount()
    {
        //现金支出明细表Reimburse_AccountPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_AccountPay set finishstatus=0 where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 管理员,取消公务卡办结，退回到待受理
    /// </summary>
    public void CancelFinishCard()
    {
        //公务卡支出明细表Reimburse_CardPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "update Reimburse_CardPay set finishstatus=0 where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 管理员删除被稽核退回的现金支出申请，
    /// 在删除时要判断是否有未恢复的单笔现金支出凭证
    /// 删除时同时删除对应的现金支出凭证表中的记录
    /// </summary>
    public void RemoveBackCashReimburseByAudit()
    {
        //现金支出明细表Reimburse_CashPay的id
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //存储过程返回值
        int result;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@result",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Direction = ParameterDirection.ReturnValue;
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "RemoveBackCashReimburseByAudit", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该现金支出项申请被删除！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该现金支出申请存在未被基层用户取回的单笔现金支出凭证，不能删除！\"}");
        if (result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    /// <summary>
    /// 管理员删除被稽核退回的转账支出申请，
    /// </summary>
    public void RemoveBackAccountReimburseByAudit()
    {
        //转账支出明细表Reimburse_AccountPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "delete from  Reimburse_AccountPay where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 管理员删除被稽核退回的公务卡支出申请
    /// </summary>
    public void RemoveBackCardReimburseByAudit()
    {
        //公务卡支出明细表Reimburse_CardPay的id
        int id = 0;
        int.TryParse(Request.Form["id"].ToString(), out id);
        string sql = "delete from  Reimburse_CardPay where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, new SqlParameter("@id", id));
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    #endregion
    #region 一般用户导出excel
    /// <summary>
    /// 基层用户导出公用经费现金支出明细
    /// </summary>
    public void ExportUserPublicCashReimburse()
    {
        string where = SetQueryConditionForCash();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,auditcashoutlay,outlaycategory,expensesubject,");
        sql.Append("memo,username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核'  when status=2 then '被出纳退回' ");
        sql.Append(" when status=3 then '已审核' when status=4 then '已审核部分退回' end,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end");
        sql.Append(" from Reimburse_CashPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "经费类别";
        dt.Columns[5].ColumnName = "支出科目";
        dt.Columns[6].ColumnName = "支出摘要";
        dt.Columns[7].ColumnName = "经办人";
        dt.Columns[8].ColumnName = "报销人";
        dt.Columns[9].ColumnName = "审核状态";
        dt.Columns[10].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "公用经费现金报销明细.xls", "6");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 基层用户导出专项经费现金支出明细
    /// </summary>
    public void ExportUserSpecialCashReimburse()
    {
        string where = SetQueryConditionForCash();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,auditcashoutlay,outlayid,outlaycategory,expensesubject,");
        sql.Append("memo,username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核'  when status=2 then '被出纳退回' ");
        sql.Append(" when status=3 then '已审核' when status=4 then '已审核部分退回' end,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end");
        sql.Append(" from Reimburse_CashPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "额度编号";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "支出科目";
        dt.Columns[7].ColumnName = "支出摘要";
        dt.Columns[8].ColumnName = "经办人";
        dt.Columns[9].ColumnName = "报销人";
        dt.Columns[10].ColumnName = "审核状态";
        dt.Columns[11].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "专项经费现金报销明细.xls", "7");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 基层用户导出公用经费转账支出明细
    /// </summary>
    public void ExportUserPublicAccountReimburse()
    {
        string where = SetQueryConditionForAccount();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,");
        sql.Append("Payment= case when payment=1 then'同城转账' when payment=2 then '异地转账' end,");
        sql.Append("outlaycategory,expensesubject,memo,PayeeName,AccountNumber,BankName,");
        sql.Append("username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核' ");
        sql.Append(" when status=2 then '被出纳退回'  when status=3 then '已审核' end,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end ");
        sql.Append(" from Reimburse_AccountPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "转账方式";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "支出科目";
        dt.Columns[7].ColumnName = "支出摘要";
        dt.Columns[8].ColumnName = "收款单位";
        dt.Columns[9].ColumnName = "银行账号";
        dt.Columns[10].ColumnName = "开户行";
        dt.Columns[11].ColumnName = "经办人";
        dt.Columns[12].ColumnName = "报销人";
        dt.Columns[13].ColumnName = "审核状态";
        dt.Columns[14].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "公用经费转账报销明细.xls", "7,8,9,10");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 基层用户导出专项经费转账支出明细
    /// </summary>
    public void ExportUserSpecialAccountReimburse()
    {
        string where = SetQueryConditionForAccount();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,outlayid,");
        sql.Append("Payment= case when payment=1 then'同城转账' when payment=2 then '异地转账' end,");
        sql.Append("outlaycategory,expensesubject,memo,PayeeName,AccountNumber,BankName,");
        sql.Append("username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核' ");
        sql.Append(" when status=2 then '被出纳退回'  when status=3 then '已审核' end,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end ");
        sql.Append(" from Reimburse_AccountPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "额度编号";
        dt.Columns[5].ColumnName = "转账方式";
        dt.Columns[6].ColumnName = "经费类别";
        dt.Columns[7].ColumnName = "支出科目";
        dt.Columns[8].ColumnName = "支出摘要";
        dt.Columns[9].ColumnName = "收款单位";
        dt.Columns[10].ColumnName = "银行账号";
        dt.Columns[11].ColumnName = "开户行";
        dt.Columns[12].ColumnName = "经办人";
        dt.Columns[13].ColumnName = "报销人";
        dt.Columns[14].ColumnName = "审核状态";
        dt.Columns[15].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "专项经费转账报销明细.xls", "8,9,10,11");
        Response.Flush();
        Response.End();
    }

    /// <summary>
    /// 基层用户导出公用经费公务卡支出明细
    /// </summary>
    public void ExportUserPublicCardReimburse()
    {
        string where = SetQueryConditionForCard();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,");
        sql.Append("outlaycategory,expensesubject,memo,CardHolder,CardNumber,SpendingTime,");
        sql.Append("username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核' ");
        sql.Append(" when status=2 then '被出纳退回'  when status=3 then '已审核' end,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end");
        sql.Append(" from Reimburse_CardPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "经费类别";
        dt.Columns[5].ColumnName = "支出科目";
        dt.Columns[6].ColumnName = "支出摘要";
        dt.Columns[7].ColumnName = "持卡人";
        dt.Columns[8].ColumnName = "卡号";
        dt.Columns[9].ColumnName = "消费时间";
        dt.Columns[10].ColumnName = "经办人";
        dt.Columns[11].ColumnName = "报销人";
        dt.Columns[12].ColumnName = "审核状态";
        dt.Columns[13].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "公用经费公务卡报销明细.xls", "6,8,9");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 基层用户导出专项经费公务卡支出明细
    /// </summary>
    public void ExportUserSpecialCardReimburse()
    {
        string where = SetQueryConditionForCard();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,outlayid,");
        sql.Append("outlaycategory,expensesubject,memo,CardHolder,CardNumber,SpendingTime,");
        sql.Append("username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核' ");
        sql.Append(" when status=2 then '被出纳退回'  when status=3 then '已审核' end,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end");
        sql.Append(" from Reimburse_CardPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "额度编号";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "支出科目";
        dt.Columns[7].ColumnName = "支出摘要";
        dt.Columns[8].ColumnName = "持卡人";
        dt.Columns[9].ColumnName = "卡号";
        dt.Columns[10].ColumnName = "消费时间";
        dt.Columns[11].ColumnName = "经办人";
        dt.Columns[12].ColumnName = "报销人";
        dt.Columns[13].ColumnName = "审核状态";
        dt.Columns[14].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "专项经费公务卡报销明细.xls", "7,9,10");
        Response.Flush();
        Response.End();
    }
    #endregion

    #region 稽核导出excel
    /// <summary>
    /// 导出现金支出报销明细——稽核
    /// </summary>
    public void ExportAuditCashReimburse()
    {
        string where = SetQueryConditionForCash();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,auditcashoutlay,outlayid,outlaycategory,expensesubject,");
        sql.Append("memo,username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核'  when status=2 then '被出纳退回' ");
        sql.Append(" when status=3 then '已审核' when status=4 then '已审核部分退回' end,auditdate,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end");
        sql.Append(" from Reimburse_CashPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "额度编号";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "支出科目";
        dt.Columns[7].ColumnName = "支出摘要";
        dt.Columns[8].ColumnName = "经办人";
        dt.Columns[9].ColumnName = "报销人";
        dt.Columns[10].ColumnName = "审核状态";
        dt.Columns[11].ColumnName = "审核日期";
        dt.Columns[12].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "现金支出报销明细.xls", "7");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 导出转账支出报销明细——稽核
    /// </summary>
    public void ExportAuditAccountReimburse()
    {
        string where = SetQueryConditionForAccount();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,");
        sql.Append("Payment= case when payment=1 then'同城转账' when payment=2 then '异地转账' end,");
        sql.Append("outlaycategory,expensesubject,memo,PayeeName,AccountNumber,BankName,");
        sql.Append("username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核' ");
        sql.Append(" when status=2 then '被退回'  when status=3 then '已审核' end,auditdate,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end ");
        sql.Append(" from Reimburse_AccountPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "转账方式";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "支出科目";
        dt.Columns[7].ColumnName = "支出摘要";
        dt.Columns[8].ColumnName = "收款单位";
        dt.Columns[9].ColumnName = "银行账号";
        dt.Columns[10].ColumnName = "开户行";
        dt.Columns[11].ColumnName = "经办人";
        dt.Columns[12].ColumnName = "报销人";
        dt.Columns[13].ColumnName = "审核状态";
        dt.Columns[14].ColumnName = "审核日期";
        dt.Columns[15].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "转账支出报销明细.xls", "7,8,9,10");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 导出公务卡支出报销明细——稽核
    /// </summary>
    public void ExportAuditCardReimburse()
    {
        string where = SetQueryConditionForCard();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,");
        sql.Append("outlaycategory,expensesubject,memo,CardHolder,CardNumber,SpendingTime,");
        sql.Append("username,reimburseuser,");
        sql.Append("status= case when status=-1 then '被稽核退回' when status=1 then '待审核' ");
        sql.Append(" when status=2 then '被退回'  when status=3 then '已审核' end,auditdate,");
        sql.Append("finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end");
        sql.Append(" from Reimburse_CardPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "经费类别";
        dt.Columns[5].ColumnName = "支出科目";
        dt.Columns[6].ColumnName = "支出摘要";
        dt.Columns[7].ColumnName = "持卡人";
        dt.Columns[8].ColumnName = "卡号";
        dt.Columns[9].ColumnName = "消费时间";
        dt.Columns[10].ColumnName = "经办人";
        dt.Columns[11].ColumnName = "报销人";
        dt.Columns[12].ColumnName = "审核状态";
        dt.Columns[13].ColumnName = "审核日期";
        dt.Columns[14].ColumnName = "结报状态";
        MyXls.CreateXls(dt, "公务卡支出报销明细.xls", "6,8,9");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 出纳导出Excel
    /// <summary>
    /// 导出现金支出报销明细——出纳
    /// </summary>
    public void ExportAcceptCashReimburse()
    {
        string where = SetQueryConditionForCash();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,auditcashoutlay,outlaycategory,expensesubject,");
        sql.Append("memo,username,reimburseuser,finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end,");
        sql.Append("acceptdate from Reimburse_CashPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "经费类别";
        dt.Columns[5].ColumnName = "支出科目";
        dt.Columns[6].ColumnName = "支出摘要";
        dt.Columns[7].ColumnName = "经办人";
        dt.Columns[8].ColumnName = "报销人";
        dt.Columns[9].ColumnName = "结报状态";
        dt.Columns[10].ColumnName = "办理日期";
        MyXls.CreateXls(dt, "现金支出报销明细.xls", "6");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 导出转账支出报销明细——出纳
    /// </summary>
    public void ExportAcceptAccountReimburse()
    {
        string where = SetQueryConditionForAccount();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,");
        sql.Append("Payment= case when payment=1 then'同城转账' when payment=2 then '异地转账' end,");
        sql.Append("outlaycategory,expensesubject,memo,PayeeName,AccountNumber,BankName,");
        sql.Append("username,reimburseuser,finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end,");
        sql.Append("acceptdate from Reimburse_AccountPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "转账方式";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "支出科目";
        dt.Columns[7].ColumnName = "支出摘要";
        dt.Columns[8].ColumnName = "收款单位";
        dt.Columns[9].ColumnName = "银行账号";
        dt.Columns[10].ColumnName = "开户行";
        dt.Columns[11].ColumnName = "经办人";
        dt.Columns[12].ColumnName = "报销人";
        dt.Columns[13].ColumnName = "结报状态";
        dt.Columns[14].ColumnName = "办理日期";
        MyXls.CreateXls(dt, "转账支出报销明细.xls", "7,8,9,10");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 导出公务卡支出报销明细——出纳
    /// </summary>
    public void ExportAcceptCardReimburse()
    {
        string where = SetQueryConditionForCard();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select reimburseno,b.deptname,reimbursedate,ReimburseOutlay,");
        sql.Append("outlaycategory,expensesubject,memo,CardHolder,CardNumber,SpendingTime,");
        sql.Append("username,reimburseuser,finishstatus= case when finishstatus=0 then '待受理'  ");
        sql.Append("when finishstatus=1 then '已受理' when finishstatus=2 then '已办结' end,");
        sql.Append("acceptdate from Reimburse_CardPay a join department b on a.deptid=b.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "办理编号";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "申请日期";
        dt.Columns[3].ColumnName = "支出金额";
        dt.Columns[4].ColumnName = "经费类别";
        dt.Columns[5].ColumnName = "支出科目";
        dt.Columns[6].ColumnName = "支出摘要";
        dt.Columns[7].ColumnName = "持卡人";
        dt.Columns[8].ColumnName = "卡号";
        dt.Columns[9].ColumnName = "消费时间";
        dt.Columns[10].ColumnName = "经办人";
        dt.Columns[11].ColumnName = "报销人";
        dt.Columns[12].ColumnName = "结报状态";
        dt.Columns[13].ColumnName = "办理日期";
        MyXls.CreateXls(dt, "公务卡支出报销明细.xls", "6,8,9");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 经费支出明细
    /// <summary>
    /// 设置经费支出明细查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForSpending()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" ReimburseDate >='" + Request.Form["sdate"] + "'");
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" ReimburseDate <='" + Request.Form["edate"] + "'");
        //申请日期未选择，默认只显示当年数据
        if (string.IsNullOrEmpty(Request.Form["sdate"]) && string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" left(ReimburseDate,4) = YEAR(GETDATE())");
        //--------------------------------------------------------------//
        //按支出方式
        if (!string.IsNullOrEmpty(Request.Form["reimbursetype"]))
            list.Add(" reimbursetype ='" + Request.Form["reimbursetype"] + "'");
        //部门编号
        string deptid = Convert.ToString(Request.QueryString["deptid"]);
        list.Add(" a.deptid=" + deptid);
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    ///  获取公用经费支出明细 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetPublicOutlaySpendingDetail()
    {
        int total = 0;
        string where = SetQueryConditionForSpending();
        StringBuilder sql = new StringBuilder("(SELECT  DeptId,ReimburseDate,ReimburseNo,'现金支出' as  reimbursetype,ExpenseSubject,AuditCashOutlay as reimburseoutlay   FROM Reimburse_CashPay WHERE [type]=1 AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,ReimburseDate,ReimburseNo,'转账支出' as reimbursetype,ExpenseSubject,reimburseoutlay  FROM Reimburse_AccountPay WHERE [type]=1 AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT  DeptId,ReimburseDate,ReimburseNo,'公务卡支出' as  reimbursetype,ExpenseSubject,reimburseoutlay FROM Reimburse_CardPay WHERE [type]=1 AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,convert(varchar(10),DeductTime,23) AS ReimburseDate,DeductNo AS ReimburseNo,'经费扣减' as reimbursetype, '经费扣减' as ExpenseSubject,deductoutlay as reimburseoutlay   FROM DeductOutlayDetail  WHERE SpecialOutlayID=0 AND [Status]=2 ) as a ");
        sql.Append(" JOIN Department AS d ON a.DeptId=d.DeptID ");
        string tableName = sql.ToString();
        string fieldStr = "a.*,d.deptname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "reimburseoutlay", "expensesubject", "合计"));
    }
    /// <summary>
    /// 导出公用经费支出明细
    /// </summary>
    public void ExportPublicOutlaySpending()
    {
        string where = SetQueryConditionForSpending();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select d.deptname,a.ReimburseDate,a.ReimburseNo,a.reimbursetype,a.ExpenseSubject,a.reimburseoutlay from ");
        sql.Append("(SELECT  DeptId,ReimburseDate,ReimburseNo,'现金支出' as  reimbursetype,ExpenseSubject,AuditCashOutlay as reimburseoutlay   FROM Reimburse_CashPay WHERE [type]=1 AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,ReimburseDate,ReimburseNo,'转账支出' as reimbursetype,ExpenseSubject,reimburseoutlay  FROM Reimburse_AccountPay WHERE [type]=1 AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT  DeptId,ReimburseDate,ReimburseNo,'公务卡支出' as  reimbursetype,ExpenseSubject,reimburseoutlay FROM Reimburse_CardPay WHERE [type]=1 AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,convert(varchar(10),DeductTime,23) AS ReimburseDate,DeductNo AS ReimburseNo,'经费扣减' as reimbursetype, '经费扣减' as ExpenseSubject,deductoutlay as reimburseoutlay   FROM DeductOutlayDetail  WHERE SpecialOutlayID=0 AND [Status]=2 ) as a ");
        sql.Append(" JOIN Department AS d ON a.DeptId=d.DeptID ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "单位名称";
        dt.Columns[1].ColumnName = "支出日期";
        dt.Columns[2].ColumnName = "办理编号";
        dt.Columns[3].ColumnName = "支出方式";
        dt.Columns[4].ColumnName = "支出科目";
        dt.Columns[5].ColumnName = "支出金额";
        MyXls.CreateXls(dt, "公用经费支出明细.xls", "");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    ///  获取专项经费支出明细 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetSpecialOutlaySpendingDetail()
    {
        int total = 0;
        //专项经费额度编号
        string OutlayID = "";
        if (!string.IsNullOrEmpty(Request.QueryString["outlayid"]))
            OutlayID = Request.QueryString["outlayid"];
        string where = SetQueryConditionForSpending();
        StringBuilder sql = new StringBuilder("(SELECT  DeptId,ReimburseDate,ReimburseNo,'现金支出' as  reimbursetype,ExpenseSubject,AuditCashOutlay as reimburseoutlay   FROM Reimburse_CashPay WHERE OutlayID=" + OutlayID + " AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,ReimburseDate,ReimburseNo,'转账支出' as reimbursetype,ExpenseSubject,reimburseoutlay  FROM Reimburse_AccountPay WHERE OutlayID=" + OutlayID + " AND [STATUS]=3 ");
        sql.Append(" union ");
        sql.Append(" SELECT  DeptId,ReimburseDate,ReimburseNo,'公务卡支出' as  reimbursetype,ExpenseSubject,reimburseoutlay FROM Reimburse_CardPay WHERE OutlayID=" + OutlayID + " AND [STATUS]=3 ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,convert(varchar(10),DeductTime,23) AS ReimburseDate,DeductNo AS ReimburseNo,'经费扣减' as reimbursetype, '经费扣减' as ExpenseSubject,deductoutlay as reimburseoutlay   FROM DeductOutlayDetail  WHERE SpecialOutlayID=" + OutlayID + " AND [Status]=2 ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,convert(varchar(10),MergeTime,23) AS ReimburseDate,'' AS ReimburseNo,'合并到公用' as reimbursetype,'合并到公用' as ExpenseSubject,SpecialOutlay as reimburseoutlay   FROM SpecialOutlayMergePublic WHERE outlayid=" + OutlayID + " AND [Status]=0) as a ");
        sql.Append(" JOIN Department AS d ON a.DeptId=d.DeptID ");
        string tableName = sql.ToString();
        string fieldStr = "a.*,d.deptname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "reimburseoutlay", "expensesubject", "合计"));
    }
    /// <summary>
    /// 导出专项经费支出明细
    /// </summary>
    public void ExportSpecialOutlaySpending()
    {
        //专项经费额度编号
        string OutlayID = "";
        if (!string.IsNullOrEmpty(Request.QueryString["outlayid"]))
            OutlayID = Request.QueryString["outlayid"];
        string where = SetQueryConditionForSpending();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select d.deptname,a.ReimburseDate,a.ReimburseNo,a.reimbursetype,a.ExpenseSubject,a.reimburseoutlay from ");
        sql.Append("(SELECT  DeptId,ReimburseDate,ReimburseNo,'现金支出' as  reimbursetype,ExpenseSubject,AuditCashOutlay as reimburseoutlay   FROM Reimburse_CashPay WHERE OutlayID=" + OutlayID + " AND ([STATUS]=3 OR [Status]=4) ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,ReimburseDate,ReimburseNo,'转账支出' as reimbursetype,ExpenseSubject,reimburseoutlay  FROM Reimburse_AccountPay WHERE OutlayID=" + OutlayID + " AND [STATUS]=3 ");
        sql.Append(" union ");
        sql.Append(" SELECT  DeptId,ReimburseDate,ReimburseNo,'公务卡支出' as  reimbursetype,ExpenseSubject,reimburseoutlay FROM Reimburse_CardPay WHERE OutlayID=" + OutlayID + " AND [STATUS]=3 ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,convert(varchar(10),DeductTime,23) AS ReimburseDate,DeductNo AS ReimburseNo,'经费扣减' as reimbursetype, '经费扣减' as ExpenseSubject,deductoutlay as reimburseoutlay   FROM DeductOutlayDetail  WHERE SpecialOutlayID=" + OutlayID + " AND [Status]=2 ");
        sql.Append(" union ");
        sql.Append(" SELECT DeptId,convert(varchar(10),MergeTime,23) AS ReimburseDate,'' AS ReimburseNo,'合并到公用' as reimbursetype,'合并到公用' as ExpenseSubject,SpecialOutlay as reimburseoutlay   FROM SpecialOutlayMergePublic WHERE outlayid=" + OutlayID + ") as a ");
        sql.Append(" JOIN Department AS d ON a.DeptId=d.DeptID ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "单位名称";
        dt.Columns[1].ColumnName = "支出日期";
        dt.Columns[2].ColumnName = "办理编号";
        dt.Columns[3].ColumnName = "支出方式";
        dt.Columns[4].ColumnName = "支出科目";
        dt.Columns[5].ColumnName = "支出金额";
        MyXls.CreateXls(dt, "专项经费(编号：" + OutlayID + ")支出明细.xls", "");
        Response.Flush();
        Response.End();
    }
    #endregion 经费支出明细

    /// <summary>
    /// 2018年1月4日 新增基层用户判断项：如果存在上年未送审的支出申请，返回true,默认显示全部未送审的申请，如果不存在则默认显示当年内容
    /// </summary>
    /// <param name="reimType">支出类别：cashpay,cardpay,accountpay</param>
    /// <returns></returns>
    public bool IsExistUnsendReimburse(string reimType)
    {
        StringBuilder sql = new StringBuilder();
        sql.Append("IF EXISTS (SELECT * FROM dbo.Reimburse_" + reimType + " WHERE status=0 AND LEFT(ReimburseDate,4)<>'" + DateTime.Now.Year.ToString() + "'  AND DeptId=" + deptid + ") ");
        sql.Append(" select 1   else select 0");
        int result = (int)SqlHelper.ExecuteScalar(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        if (result == 1)
            return true;
        else
            return false;
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}