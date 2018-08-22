<%@ WebHandler Language="C#" Class="ReportInfo" %>

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
/// 报表上报操作
/// </summary>
public class ReportInfo : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;
    /// <summary>
    /// 当前登陆用户名
    /// </summary>
    string userName;
    /// <summary>
    /// 用户角色编号
    /// </summary>
    string roleid;
    /// <summary>
    /// 单位编号
    /// </summary>
    string deptid;
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
        if(!Request.IsAuthenticated)
        {
            Response.Write("{\"success\":false,\"msg\":\"登陆超时，请重新登陆后再进行操作！\",\"total\":-1,\"rows\":[]}");
            return;
        }
        else
        {
            UserDetail ud = new UserDetail();
            roleid = ud.LoginUser.RoleId.ToString();
            deptid = ud.LoginUser.DeptId.ToString();
            userName = ud.LoginUser.UserName;
        }
        string method = HttpContext.Current.Request.PathInfo.Substring(1);
        if(method.Length != 0)
        {
            MethodInfo methodInfo = this.GetType().GetMethod(method);
            if(methodInfo != null)
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
    }
    /// <summary>
    /// 获取ReportInfo 数据page:1 rows:10 sort:id order:asc
    public void GetReportInfo()
    {
        int total = 0;
        string where = "";
        string tableName = "ReportInfo ";
        string fieldStr = "*,dbo.F_CheckReportHasReceipted(id) as receiptstatus";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //申请开始日期
        if(!string.IsNullOrEmpty(Request.Form["publish_sdate"]))
            list.Add(" PublishDate >='" + Request.Form["publish_sdate"] + "'");
        //申请截止日期
        if(!string.IsNullOrEmpty(Request.Form["publish_edate"]))
            list.Add(" PublishDate <='" + Request.Form["publish_edate"] + "'");
        //申请日期未选择，默认只显示当年数据
        if (string.IsNullOrEmpty(Request.Form["publish_sdate"]) && string.IsNullOrEmpty(Request.Form["publish_edate"]))
            list.Add(" left(PublishDate,4) = YEAR(GETDATE()) ");
        //按状态
        if(!string.IsNullOrEmpty(Request.Form["status"]))
            list.Add("status=" + Request.Form["status"]);
        //按回执情况
        if(!string.IsNullOrEmpty(Request.Form["receiptstatus"]))
            list.Add("dbo.F_CheckReportHasReceipted(id)=" + Request.Form["receiptstatus"]);
        //按用户名，稽核，出纳，统计员只能操作自己报送的报表
        if(roleid == "2" || roleid == "3" || roleid == "5")
            list.Add(" publisher='" + userName + "' ");
        if(list.Count > 0)
            where = string.Join(" and ", list.ToArray());
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
    /// <summary>
    /// 通过Id获取ReportInfo信息
    /// </summary>
    public void GetReportInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["ID"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT * FROM ReportInfo WHERE id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存ReportInfo信息
    /// </summary>
    public void SaveReportInfo()
    {
        string title = Convert.ToString(Request.Form["title"]);
        string content = Convert.ToString(Request.Form["content"]);
        string reportPath = "";
        if(!string.IsNullOrEmpty(Request.Form["report"]))
            reportPath = Request.Form["report"].ToString();
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@publishdate",SqlDbType.VarChar),
            new SqlParameter("@title",SqlDbType.NVarChar),
            new SqlParameter("@content",SqlDbType.NVarChar),
            new SqlParameter("@reportpath",SqlDbType.NVarChar),
            new SqlParameter("@publisher",SqlDbType.NVarChar)
            
        };
        paras[0].Value = DateTime.Now.ToString("yyyy-MM-dd");
        paras[1].Value = title;
        paras[2].Value = content;
        paras[3].Value = reportPath;
        paras[4].Value = userName;

        string sql = "INSERT INTO ReportInfo VALUES(@publishdate,'',@title,@content,@reportpath,@publisher,getdate(),0)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误，请检查输入！\"}");
    }
    /// <summary>
    /// 更新用户信息
    /// </summary>
    public void UpdateReportInfo()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        string title = Convert.ToString(Request.Form["title"]);
        string content = Convert.ToString(Request.Form["content"]);
        string reportPath = "";
        if(!string.IsNullOrEmpty(Request.Form["report"]))
            reportPath = Request.Form["report"].ToString();
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@publishdate",SqlDbType.VarChar),
            new SqlParameter("@title",SqlDbType.NVarChar),
            new SqlParameter("@content",SqlDbType.NVarChar),
            new SqlParameter("@reportpath",SqlDbType.NVarChar),
            new SqlParameter("@publisher",SqlDbType.NVarChar)
            
        };
        paras[0].Value = id;
        paras[1].Value = DateTime.Now.ToString("yyyy-MM-dd");
        paras[2].Value = title;
        paras[3].Value = content;
        paras[4].Value = reportPath;
        paras[5].Value = userName;
        string sql = "UPDATE ReportInfo set PublishDate=@publishdate,ReportTitle=@title,ReportContent=@content,ReportPath=@reportpath,Publisher=@publisher,PublishTime=getdate() where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");
    }
    /// <summary>
    /// 通过uid获取删除ReportInfo信息
    /// </summary>
    public void RemoveReportInfoByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM ReportInfo WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }

    /// <summary>
    /// 报送报表给基层用户
    /// </summary>
    public void SendReportToDepts()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //
        string receiveDepts = Convert.ToString(Request.Form["receiveDepts"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
          new SqlParameter("@receivedepts",SqlDbType.VarChar)
        };
        paras[0].Value = id;
        paras[1].Value = receiveDepts;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "SendReportToDepts", paras);
        if(result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"报送成功！\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");
    }
    /// <summary>
    /// 非基层用户通过报表id获取各基层单位报表回执信息
    /// </summary>
    public void GetReportReceiptDetailByReportId()
    {
        int reportId = 0;
        int.TryParse(Request.QueryString["reportid"], out reportId);
        int total = 0;
        string where = " a.reportid=" + reportId.ToString();
        if(!string.IsNullOrEmpty(Request.Form["IsReceipted"]))
            where += " and a.IsReceipted=" + Request.Form["IsReceipted"].ToString();
        string tableName = " ReportReceiptInfo a left join department b on a.deptid=b.deptid";
        string fieldStr = " a.*,b.deptname ";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
        
    }
    /// <summary>
    /// 基层用户获取自己的报表
    /// </summary>
    public void GetDeptReportInfoByDeptId()
    {
        int total = 0;
        string where = "";
        string tableName = " ReportInfo  a join ReportReceiptInfo b on a.id=b.reportid ";
        string fieldStr = " a.*,isread,isreceipted,receiptreport,receiptuser,receipttime ";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //申请开始日期
        if(!string.IsNullOrEmpty(Request.Form["publish_sdate"]))
            list.Add(" PublishDate >='" + Request.Form["publish_sdate"] + "'");
        //申请截止日期
        if(!string.IsNullOrEmpty(Request.Form["publish_edate"]))
            list.Add(" PublishDate <='" + Request.Form["publish_edate"] + "'");
        //申请日期未选择，默认只显示当年数据
        if (string.IsNullOrEmpty(Request.Form["publish_sdate"]) && string.IsNullOrEmpty(Request.Form["publish_edate"]))
            list.Add(" left(PublishDate,4) = YEAR(GETDATE()) ");
        //按状态
        if(!string.IsNullOrEmpty(Request.Form["isreceipted"]))
            list.Add(" isreceipted=" + Request.Form["isreceipted"]);
        //基层用户获取已报送给自己的报表
        if(roleid == "1")
        {
            list.Add(" deptid=" + deptid);
            list.Add(" status=1 ");
        }
        if(list.Count > 0)
            where = string.Join(" and ", list.ToArray());
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 通过ReportInfo的Id获取ReportReceiptInfo信息
    /// </summary>
    public void GetReceiptReportInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id", SqlDbType.Int), 
            new SqlParameter("@deptid", SqlDbType.Int) 
        };
        paras[0].Value = id;
        paras[1].Value = Int32.Parse(deptid);
        string sql = "SELECT  a.*,isread,isreceipted,receiptreport,receiptuser,receipttime FROM ReportInfo  a join ReportReceiptInfo b on a.id=b.reportid WHERE a.id=@id and deptid=@deptid";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 基层用户打开回执报表时设置报表已读
    /// </summary>
    public void SetReportHasRead()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id", SqlDbType.Int), 
            new SqlParameter("@deptid", SqlDbType.Int) 
        };
        paras[0].Value = id;
        paras[1].Value = Int32.Parse(deptid);
        string sql = "update ReportReceiptInfo set isread=1  WHERE ReportId=@id and deptid=@deptid";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 基层用户回执已接收的报表，ReportReceiptInfo表操作
    /// </summary>
    public void UpdateReceiptReportInfo()
    {
        int reportId = Convert.ToInt32(Request.Form["id"]);
        string receiptReport = "";
        if(!string.IsNullOrEmpty(Request.Form["report"]))
            receiptReport = Request.Form["report"].ToString();
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@reportid",SqlDbType.Int),
            new SqlParameter("@receiptreport",SqlDbType.NVarChar),
            new SqlParameter("@receiptuser",SqlDbType.NVarChar),
            new SqlParameter("@deptid",SqlDbType.NVarChar)
            
        };
        paras[0].Value = reportId;
        paras[1].Value = receiptReport;
        paras[2].Value = userName;
        paras[3].Value = Int32.Parse(deptid);
        string sql = "UPDATE ReportReceiptInfo set IsReceipted=1,ReceiptReport=@receiptreport,  ReceiptUser=@receiptuser,ReceiptTime=getdate() where ReportId=@reportid and deptid=@deptid";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");
    }
    /// <summary>
    /// 退回基层用户已回执的报表
    /// </summary>
    public void BackReceiptReport()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter para = new SqlParameter("@id", SqlDbType.Int);
        para.Value = id;
        string sql = "update ReportReceiptInfo set isreceipted=0  WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 管理员删除已报送的报表
    /// </summary>
    public void RemoveHasPublishedReport()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM ReportInfo WHERE id=@id ;";
        sql += "delete from ReportReceiptInfo where ReportId=@id;";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
}