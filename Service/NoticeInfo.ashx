<%@ WebHandler Language="C#" Class="NoticeInfo" %>

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
/// 意见信箱操作
/// </summary>
public class NoticeInfo : IHttpHandler, IRequiresSessionState
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
    /// 当前登陆用户id
    /// </summary>
    int UID;
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
            UID = ud.LoginUser.UID;
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
    /// 获取NoticeInfo 数据page:1 rows:10 sort:id order:asc
    public void GetNoticeInfo()
    {
        int total = 0;
        string where = "";
        string tableName = "NoticeInfo a left join department b on a.deptid=b.deptid ";
        string fieldStr = "a.*,deptname";
        //设置查询条件
        List<string> list = new List<string>();
        //按办理日期查询
        //申请开始日期
        if(!string.IsNullOrEmpty(Request.Form["publish_sdate"]))
            list.Add(" PublishDate >='" + Request.Form["publish_sdate"] + "'");
        //申请截止日期
        if(!string.IsNullOrEmpty(Request.Form["publish_edate"]))
            list.Add(" PublishDate <='" + Request.Form["publish_edate"] + "'");
        //未选择日期，默认只显示当年数据
        if (string.IsNullOrEmpty(Request.Form["publish_sdate"]) && string.IsNullOrEmpty(Request.Form["publish_edate"]))
            list.Add(" left(PublishDate,4) = YEAR(GETDATE())");
        //按状态
        if(!string.IsNullOrEmpty(Request.Form["IsReply"]))
            list.Add("IsReply=" + Request.Form["IsReply"]);
        //按用户名，非基层只能操作自己接收的意见
        if(roleid=="1")
            list.Add(" publisher='" + userName + "' ");
        else if(roleid!="6")
            list.Add(" ReceiverUID=" +UID);
            
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
    /// 通过Id获取NoticeInfo信息
    /// </summary>
    public void GetNoticeInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["ID"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT a.*,deptname FROM NoticeInfo a left join department b on a.deptid=b.deptid WHERE a.id=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存NoticeInfo信息
    /// </summary>
    public void SaveNoticeInfo()
    {
        int receiverUID = Convert.ToInt32(Request.Form["receiverUID"]);
        string receiverName = Convert.ToString(Request.Form["receiverName"]);
        string title = Convert.ToString(Request.Form["title"]);
        string content = Convert.ToString(Request.Form["content"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@publishdate",SqlDbType.VarChar),
            new SqlParameter("@receiveruid",SqlDbType.Int),
            new SqlParameter("@receivername",SqlDbType.VarChar),
            new SqlParameter("@title",SqlDbType.NVarChar),
            new SqlParameter("@content",SqlDbType.NVarChar),
            new SqlParameter("@deptid",SqlDbType.Int),
            new SqlParameter("@publisher",SqlDbType.NVarChar)
            
        };
        paras[0].Value = DateTime.Now.ToString("yyyy-MM-dd");
        paras[1].Value = receiverUID;
        paras[2].Value = receiverName;
        paras[3].Value = title;
        paras[4].Value = content;
        paras[5].Value = deptid;
        paras[6].Value = userName;

        string sql = "INSERT INTO NoticeInfo VALUES(@publishdate,@receiveruid,@receivername,@title,@content,@deptid,@publisher,getdate(),0,0,null,null,0)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误，请检查输入！\"}");
    }
   
    /// <summary>
    /// 通过id删除已回复并且发信人已读的信息
    /// </summary>
    public void RemovePublisherHasReadNotice()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM NoticeInfo WHERE id=@id and IsReply=1 and IsPublisherReadReply=1";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 非基层用户打开收到意见时设置已读
    /// </summary>
    public void SetNoticeHasReceiverRead()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update NoticeInfo set IsReceiverRead=1  WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 基层用户查看详情时设置回复的意见已读
    /// </summary>
    public void SetNoticeHasPublisherReadReply()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update NoticeInfo set IsPublisherReadReply=1  WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 非基层用户回复已接收的意见
    /// </summary>
    public void ReplyNoticeInfo()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        string  replycontent = Convert.ToString(Request.Form["replycontent"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@replycontent",SqlDbType.NVarChar)
        };
        paras[0].Value = id;
        paras[1].Value = replycontent;
        string sql = "UPDATE NoticeInfo set IsReply=1,ReplyContent=@replycontent,ReplyTime=getdate() where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");
    }
  
}