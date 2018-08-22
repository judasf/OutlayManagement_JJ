<%@ WebHandler Language="C#" Class="OutlayLevel" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
/// <summary>
/// 支出科目操作
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
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
    /// <summary>
    /// 获取ExpenseSubject数据page:1 rows:10 sort:id order:asc
    public void GetExpenseSubjectInfo()
    {
        int total = 0;
        string where = "";
        //combogrid自动补全模式下获查询变量q
        if(!string.IsNullOrEmpty(Request.Form["q"]))
            where = "subjectnum like'%" + Request.Form["q"].ToString() + "%'";
        if(!string.IsNullOrEmpty(Request.Form["where"]))
            where = Server.UrlDecode(Request.Form["where"].ToString());
        DataSet ds = SqlHelper.GetPagination("ExpenseSubject", "*", Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds,total));
    }
    /// <summary>
    /// 通过id获取ExpenseSubject信息
    /// </summary>
    public void GetExpenseSubjectByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT * FROM ExpenseSubject WHERE id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存ExpenseSubject信息
    /// </summary>
    public void SaveExpenseSubject()
    {
        string subjectNum = Convert.ToString(Request.Form["subjectNum"]);
        string subjectName = Convert.ToString(Request.Form["subjectName"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@subjectNum",SqlDbType.VarChar),
            new SqlParameter("@subjectName",SqlDbType.NVarChar)
        };
        paras[0].Value = subjectNum;
        paras[1].Value = subjectName;
        string sql = "if not exists(select * from ExpenseSubject where subjectNum=@subjectNum) ";
        sql += "INSERT INTO ExpenseSubject VALUES(@subjectNum,@subjectName)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"支出科目编号已存在，请检查输入\"}");
    }
    public void UpdateExpenseSubject()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        string subjectNum = Convert.ToString(Request.Form["subjectNum"]);
        string subjectName = Convert.ToString(Request.Form["subjectName"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@subjectNum",SqlDbType.VarChar),
            new SqlParameter("@subjectName",SqlDbType.NVarChar)
        };
        paras[0].Value = id;
        paras[1].Value = subjectNum;
        paras[2].Value = subjectName;
        
        string sql = "UPDATE ExpenseSubject set subjectNum=@subjectNum,subjectName=@subjectName where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过id获取删除ExpenseSubject信息
    /// </summary>
    public void RemoveExpenseSubjectByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
      
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM ExpenseSubject WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 导出支出科目
    /// </summary>
    public void ExportExpenseSubject()
    {
        string sql = "select subjectnum,subjectname from ExpenseSubject ";

        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "支出科目编号";
        dt.Columns[1].ColumnName = "支出科目名称";
        MyXls.CreateXls(dt, "支出科目信息表.xls", "1");
        Response.Flush();
        Response.End();
    }
}