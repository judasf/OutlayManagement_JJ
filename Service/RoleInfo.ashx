<%@ WebHandler Language="C#" Class="RoleInfo" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
/// <summary>
/// 角色操作
/// </summary>
public class RoleInfo : IHttpHandler, IRequiresSessionState
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
    /// 获取RoleInfo(经费级别表)数据page:1 rows:10 sort:id order:asc
    public void GetRoleInfo()
    {
        int total = 0;
        string where = "";
        if(!string.IsNullOrEmpty(Request.Form["where"]))
            where = Server.UrlDecode(Request.Form["where"].ToString());
        DataSet ds = SqlHelper.GetPagination("RoleInfo", "*", Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
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
    /// 通过roleId获取RoleInfo信息
    /// </summary>
    public void GetRoleInfoByID()
    {
        int roleId = Convert.ToInt32(Request.Form["roleId"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = roleId;
        string sql = "SELECT * FROM RoleInfo WHERE roleId=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存RoleInfo信息
    /// </summary>
    public void SaveRoleInfo()
    {
        string roleName = Convert.ToString(Request.Form["rolename"]);
        string roleDesc = Convert.ToString(Request.Form["roleDesc"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@roleName",SqlDbType.NVarChar),
            new SqlParameter("@roleDesc",SqlDbType.NVarChar)
        };
        paras[0].Value = roleName;
        paras[1].Value = roleDesc;
        string sql = "INSERT INTO RoleInfo VALUES(@roleName,@roleDesc,'0')";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    public void UpdateRoleInfo()
    {
        int roleId = Convert.ToInt32(Request.Form["roleId"]);
        string roleName = Convert.ToString(Request.Form["rolename"]);
        string roleDesc = Convert.ToString(Request.Form["roleDesc"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@roleId",SqlDbType.Int),
            new SqlParameter("@roleName",SqlDbType.NVarChar),
            new SqlParameter("@roleDesc",SqlDbType.NVarChar)
        };
        paras[0].Value = roleId;
        paras[1].Value = roleName;
        paras[2].Value = roleDesc;
        string sql = "UPDATE RoleInfo set rolename=@roleName,roleDesc=@roleDesc where roleId=@roleId";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过roleId获取删除RoleInfo信息
    /// </summary>
    public void RemoveRoleInfoByID()
    {
        int roleId = 0;
        int.TryParse(Request.Form["roleId"], out roleId);
      
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = roleId;
        string sql = "DELETE FROM RoleInfo WHERE roleId=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 生成roleinfo表的combobox使用的json字符串
    /// </summary>
    public void GetRoleInfoCombobox()
    {
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select RoleID,RoleName from roleinfo order by roleid");
        Response.Write(JsonConvert.CreateComboboxJson(ds.Tables[0]));
    }

}