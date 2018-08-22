<%@ WebHandler Language="C#" Class="Category" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
/// <summary>
/// 支出科目经费类别操作
/// </summary>
public class Category : IHttpHandler, IRequiresSessionState
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
    /// 获取Category 
    public void GetCategory()
    {
        string sql = "";
        if(string.IsNullOrEmpty(Request.QueryString["pid"]))
            sql = "select cid,cname,pid,clevel  from category";
        else
        {
            sql += "with CTEGetChild as  ( select * from Category where pid=" + Request.QueryString["pid"].ToString() + " UNION ALL";
            sql += " (SELECT a.* from Category as a inner join   CTEGetChild as b on a.pid=b.cid) ";
            sql += ")  SELECT * FROM CTEGetChild UNION ALL select * from Category where cid=2";
        }
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        Response.Write((new JsonConvert()).GetTreeJsonByTable(ds.Tables[0], "cid", "cname", "clevel", "pid", 0));

    }
    /// <summary>
    /// 通过clevel 获取Category 
    public void GetCategoryByLevel()
    {
        int clevel = Convert.ToInt32(Request.QueryString["clevel"]);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select cid,cname,pid,clevel  from category where clevel<=@clevel", new SqlParameter("@clevel", clevel));
        Response.Write((new JsonConvert()).GetTreeJsonByTable(ds.Tables[0], "cid", "cname", "clevel", "pid", 0));

    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
    /// <summary>
    /// 通过cid获取Category信息
    /// </summary>
    public void GetCategoryByID()
    {
        int cid = Convert.ToInt32(Request.Form["cid"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = cid;
        string sql = "SELECT * FROM Category WHERE cid=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存Category信息
    /// </summary>
    public void SaveCategory()
    {
        string cname = Convert.ToString(Request.Form["cname"]);
        int pid = Convert.ToInt32(Request.Form["pid"]);
        int clevel = Convert.ToInt32(Request.Form["clevel"]) + 1;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@cname",SqlDbType.NVarChar),
            new SqlParameter("@pid",SqlDbType.Int),
            new SqlParameter("@clevel",SqlDbType.Int)
            
        };
        paras[0].Value = cname;
        paras[1].Value = pid;
        paras[2].Value = clevel;
        string sql = "INSERT INTO Category VALUES(@pid,@cname,'',@clevel)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错！\"}");
    }
    /// <summary>
    /// 更新经费类别
    /// </summary>
    public void UpdateCategory()
    {
        int cid = Convert.ToInt32(Request.Form["cid"]);
        string cname = Convert.ToString(Request.Form["cname"]);
        int newPid = Convert.ToInt32(Request.Form["pid"]);

        if(newPid == cid)
        {
            Response.Write("{\"success\":false,\"msg\":\"上级经费类别不能是自己\"}");
            return;
        }
        //获取新level的值
        int newlevel = Convert.ToInt32(Request.Form["clevel"]) + 1;
        //如果是顶层目录则level为1
        if(newPid == 0)
            newlevel = 1;
        //定义当前节点更新前的pid和level
        int oldPid = 0, oldLevel = 0;
        //获取当前节点更新前的信息
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select * from category where cid=@cid", new SqlParameter("@cid", cid));
        if(ds.Tables[0].Rows.Count > 0)
        {
            oldPid = Convert.ToInt32(ds.Tables[0].Rows[0]["pid"]);
            oldLevel = Convert.ToInt32(ds.Tables[0].Rows[0]["clevel"]);
        }
        //获取当前节点所有子节点的值，在更新当前节点信息时需要批量更新子节点的level
        StringBuilder sb = new StringBuilder("with CTEGetChild as  (  ");
        sb.Append("select * from Category where pid=@cid UNION ALL  ");
        sb.Append("(SELECT a.* from Category as a inner join   CTEGetChild as b on a.pid=b.cid)  ");
        sb.Append(")  SELECT * FROM CTEGetChild ");
        ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sb.ToString(), new SqlParameter("@cid", cid));
        //清空sb
        sb.Remove(0, sb.Length);
        //定义参数集合
        List<SqlParameter> _paras = new List<SqlParameter>();
        _paras.Add(new SqlParameter("@increment", oldLevel - newlevel));
        //遍历所有子节点
        for(int i = 0 ; i < ds.Tables[0].Rows.Count ; i++)
        {
            sb.Append("update Category set clevel=clevel-@increment where cid=@cid" + i.ToString() + ";");
            _paras.Add(new SqlParameter("@cid" + i.ToString(), Convert.ToInt32(ds.Tables[0].Rows[i]["cid"])));
        }
        sb.Append("UPDATE Category set cname=@cname,pid=@pid,clevel=@clevel where cid=@cid;");
        _paras.Add(new SqlParameter("@cid", cid));
        _paras.Add(new SqlParameter("@cname", cname));
        _paras.Add(new SqlParameter("@pid", newPid));
        _paras.Add(new SqlParameter("@clevel", newlevel));
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sb.ToString(), _paras.ToArray());
        if(result > 0)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");

    }
    /// <summary>
    /// 通过cid获取删除Category信息
    /// </summary>
    public void RemoveCategory()
    {
        int cid = 0;
        int.TryParse(Request.Form["cid"], out cid);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = cid;
        string sql = "if not exists(select * from category where pid=@id) ";
        sql += "DELETE FROM category WHERE cid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"当前经费类别下有子类别，请逐级删除！\"}");
    }
}