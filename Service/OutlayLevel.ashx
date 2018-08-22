<%@ WebHandler Language="C#" Class="OutlayLevel" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
/// <summary>
/// 公用经费标准操作
/// </summary>
public class OutlayLevel : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;
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
    /// 获取Outlay(经费级别表)数据page:1 rows:10 sort:id order:asc
    public void getOutlayLevelInfo()
    {
        int total = 0;
        string where = "";
        if(!string.IsNullOrEmpty(Request.Form["where"]))
            where = Server.UrlDecode(Request.Form["where"].ToString());
        DataSet ds = SqlHelper.GetPagination("outlaylevel", "*", Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds,total));
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
    /// <summary>
    /// 通过levelid获取outlaylevel信息
    /// </summary>
    public void getOutlayLevelByID()
    {
        int levelid = Convert.ToInt32(Request.Form["levelid"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = levelid;
        string sql = "SELECT * FROM OutlayLevel WHERE levelid=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存outlaylevel信息
    /// </summary>
    public void SaveOutlayLevel()
    {
        string levelName = Convert.ToString(Request.Form["levelname"]);
        decimal levelOutlay = Convert.ToDecimal(Request.Form["leveloutlay"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@levelName",SqlDbType.NVarChar),
            new SqlParameter("@levelOutlay",SqlDbType.Money)
        };
        paras[0].Value = levelName;
        paras[1].Value = levelOutlay;
        string sql = "INSERT INTO OutlayLevel VALUES(@levelName,@levelOutlay)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    public void UpdateOutlayLevel()
    {
        int levelID = Convert.ToInt32(Request.Form["levelid"]);
        string levelName = Convert.ToString(Request.Form["levelname"]);
        decimal levelOutlay = Convert.ToDecimal(Request.Form["leveloutlay"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@levelid",SqlDbType.Int),
            new SqlParameter("@levelName",SqlDbType.NVarChar),
            new SqlParameter("@levelOutlay",SqlDbType.Money)
        };
        paras[0].Value = levelID;
        paras[1].Value = levelName;
        paras[2].Value = levelOutlay;
        string sql = "UPDATE OutlayLevel set levelname=@levelName,leveloutlay=@levelOutlay where levelid=@levelid";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过levelid获取删除outlaylevel信息
    /// </summary>
    public void RemovelayLevelByID()
    {
        int levelid = 0;
        int.TryParse(Request.Form["levelid"], out levelid);
      
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = levelid;
        string sql = "DELETE FROM OutlayLevel WHERE levelid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }

}