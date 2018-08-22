<%@ WebHandler Language="C#" Class="DeptOutlay" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
/// <summary>
/// 部门公用经费标准操作
/// </summary>
public class DeptOutlay : IHttpHandler, IRequiresSessionState
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
    /// 获取DeptLevelInfo表数据page:1 rows:10 sort:id order:asc
    public void GetDeptOutlayInfo()
    {
        int total = 0;
        string where = "";
        if(!string.IsNullOrEmpty(Request["where"]))
            where = Server.UrlDecode(Request["where"].ToString());
        string fieldStr = "id,a.deptid,a.levelid,deptpeoplenum,deptname,levelname";
        string table = "deptlevelinfo a join department b on a.deptid=b.deptid join outlaylevel c on a.LevelID=c.LevelID";
        DataSet ds = SqlHelper.GetPagination(table, fieldStr, Request["sort"].ToString(), Request["order"].ToString(), where, Convert.ToInt32(Request["rows"]), Convert.ToInt32(Request["page"]), out total);
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
    /// 通过id获取DeptLevelInfo信息
    /// </summary>
    public void GetDeptOutlayByID()
    {
        int id = Convert.ToInt32(Request["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT * from DeptLevelInfo WHERE id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存DeptLevelInfo信息
    /// </summary>
    public void SaveDeptOutlay()
    {
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        int levelId = Convert.ToInt32(Request.Form["deptLevelId"]);
        int peopleNum = Convert.ToInt32(Request.Form["deptPeopleNum"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@deptId",SqlDbType.Int),
            new SqlParameter("@levelId",SqlDbType.Int),
            new SqlParameter("@peopleNum",SqlDbType.Int)
            
        };
        paras[0].Value = deptId;
        paras[1].Value = levelId;
        paras[2].Value = peopleNum;
        //判断当前部门是否存在
        string sql = "if not exists(select * from DeptLevelInfo where deptid=@deptId) ";
        sql += "INSERT INTO DeptLevelInfo VALUES(@deptId,@levelId,@peopleNum)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"该单位经费标准已存在，请不要重复输入！\"}");
    }
    /// <summary>
    /// 通过ID更新DeptLevelInfo表数据
    /// </summary>
    public void UpdateDeptOutlay()
    {
        int id = Convert.ToInt32(Request["id"]);
        int deptId = Convert.ToInt32(Request["deptId"]);
        int levelId = Convert.ToInt32(Request["deptLevelId"]);
        int peopleNum = Convert.ToInt32(Request["deptPeopleNum"]);
        SqlParameter[] paras = new SqlParameter[] {
         new SqlParameter("@id",SqlDbType.Int),
         new SqlParameter("@deptId",SqlDbType.Int),
         new SqlParameter("@levelId",SqlDbType.Int),
            new SqlParameter("@peopleNum",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Value = deptId;
        paras[2].Value = levelId;
        paras[3].Value = peopleNum;
        string sql = "UPDATE DeptLevelInfo set deptId=@deptId,LevelID=@levelId,deptPeopleNum=@peopleNum where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过id获取删除DeptLevelInfo信息
    /// </summary>
    public void RemoveDeptOutlayByID()
    {
        int id = 0;
        int.TryParse(Request["id"], out id);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM DeptLevelInfo WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 生成生成公用经费时，有公用经费的部门的DeptLevelInfo表的combobox使用的json字符串
    /// </summary>
    public void GetDeptLevelCombobox()
    {
        string where = "";
        //获取用户的管辖范围
        if(Request.IsAuthenticated)
        {
            UserDetail ud = new UserDetail();
            string scopeDepts = ud.LoginUser.ScopeDepts;
            if(scopeDepts != "0")
                where = "where a.deptid in (" + scopeDepts + ")";
        }
        string sql = "select b.* from deptlevelinfo  a join department b on a.deptid=b.deptid "+where+" order by a.deptid";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        Response.Write(JsonConvert.CreateComboboxJson(ds.Tables[0]));
    }
    /// <summary>
    /// 导出基层单位公用经费标准
    /// </summary>
    public void ExportDeptOutlay()
    {
        string sql = "select deptname,levelname,deptpeoplenum from deptlevelinfo a join department b on a.deptid=b.deptid join outlaylevel c on a.LevelID=c.LevelID ";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "单位名称";
        dt.Columns[1].ColumnName = "公用经费标准";
        dt.Columns[2].ColumnName = "单位人数";
        MyXls.CreateXls(dt, "基层单位公用经费标准.xls", "");
        Response.Flush();
        Response.End();
    }
}