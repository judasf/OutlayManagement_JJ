<%@ WebHandler Language="C#" Class="PaymentBaseInfo" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
/// <summary>
/// 转账支出和公务卡支出基本信息表维护
/// </summary>
public class PaymentBaseInfo : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;
    /// <summary>
    /// 登陆用户的部门编号
    /// </summary>
    int deptid;
    /// <summary>
    /// 登陆用户的角色编号
    /// </summary>
    int roleId;
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
            deptid = ud.LoginUser.DeptId;
            roleId = ud.LoginUser.RoleId;
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
    /// 获取转账账号信息表PayeeInfo表数据page:1 rows:10 sort:id order:asc
    public void GetPayeeInfo()
    {
        int total = 0;
        string where = "";
        string table = "payeeinfo";
        string fieldStr = "*";
        //设置查询条件
        List<string> list = new List<string>();
        //combogrid自动补全模式下获查询变量q
        if(!string.IsNullOrEmpty(Request.Form["q"]))
            list.Add("PayeeName like'%" + Request.Form["q"].ToString() + "%'");
        //收款单位
        if(!string.IsNullOrEmpty(Request.Form["PayeeName"]))
            list.Add("PayeeName like'%" + Request.Form["PayeeName"].ToString() + "%'");
        //收款银行账号
        if(!string.IsNullOrEmpty(Request.Form["accountnumber"]))
            list.Add("accountnumber like'%" + Request.Form["accountnumber"].ToString() + "%'");
        if(list.Count > 0)
            where = string.Join(" and ", list.ToArray());
        DataSet ds = SqlHelper.GetPagination(table, fieldStr, Request["sort"].ToString(), Request["order"].ToString(), where, Convert.ToInt32(Request["rows"]), Convert.ToInt32(Request["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 通过id获取转账信息
    /// </summary>
    public  void GetPayeeInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT * FROM payeeinfo WHERE PayeeID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存转账信息
    /// </summary>
    public void SavePayeeInfo()
    {
        //收款单位
        string payeeName = Convert.ToString(Request.Form["payeeName"]);
        //银行账号
        string accountNumber = Convert.ToString(Request.Form["accountNumber"]);
        //开户行
        string bankName = Convert.ToString(Request.Form["bankName"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@payeename",payeeName),
            new SqlParameter("@accountnumber",accountNumber),
            new SqlParameter("@bankname",bankName)
        };
        StringBuilder sql = new StringBuilder();
        //不存在当前收款账号信息，则插入新数据
        sql.Append("if not exists (select * from payeeinfo where  accountnumber=@accountnumber)");
        sql.Append(" insert into payeeinfo values(@payeename,@accountnumber,@bankname); ");
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"银行账号已存在，请检查输入！\"}");
    }
    /// <summary>
    /// 更新转账信息
    /// </summary>
    public void UpdatePayeeInfo()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        //收款单位
        string payeeName = Convert.ToString(Request.Form["payeeName"]);
        //银行账号
        string accountNumber = Convert.ToString(Request.Form["accountNumber"]);
        //开户行
        string bankName = Convert.ToString(Request.Form["bankName"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@payeename",payeeName),
            new SqlParameter("@accountnumber",accountNumber),
            new SqlParameter("@bankname",bankName)
        };
        string sql="update payeeinfo set PayeeName=@payeename,BankName=@bankname,AccountNumber=@accountnumber where payeeid=@id;";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错！\"}");
    }
    /// <summary>
    /// 通过id删除转账信息
    /// </summary>
    public  void RemovePayeeInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter para = new SqlParameter("@id", id);
        string sql = "delete from payeeinfo where payeeid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错！\"}");
    }
    /// <summary>
    /// 获取公务卡信息表CardInfo表数据page:1 rows:10 sort:id order:asc
    public void GetCardInfo()
    {
        int total = 0;
        string where = "";
        string table = "CardInfo  a left join department b on a.deptid=b.deptid";
        string fieldStr = "a.*,deptname";
        //设置查询条件
        List<string> list = new List<string>();
        //combogrid自动补全模式下获查询变量q
        if(!string.IsNullOrEmpty(Request.Form["q"]))
            list.Add("cardholder like'%" + Request.Form["q"].ToString() + "%'");
        //持卡人
        if(!string.IsNullOrEmpty(Request.Form["cardholder"]))
            list.Add("cardholder like'%" + Request.Form["cardholder"].ToString() + "%'");
        //卡号
        if(!string.IsNullOrEmpty(Request.Form["cardnumber"]))
            list.Add("cardnumber like'%" + Request.Form["cardnumber"].ToString() + "%'");
        //只获取当前登陆基层单位的信息
        if(roleId==1)
        list.Add("a.deptid=" + deptid.ToString());
        else
        {
            if(!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" a.deptid ='" + Request.Form["deptid"] + "'");
        }
        if(list.Count > 0)
            where = string.Join(" and ", list.ToArray());
        DataSet ds = SqlHelper.GetPagination(table, fieldStr, Request["sort"].ToString(), Request["order"].ToString(), where, Convert.ToInt32(Request["rows"]), Convert.ToInt32(Request["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 通过ID获取公务卡信息
    /// </summary>
    public void GetCardInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT * FROM Cardinfo  WHERE CardID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存公务卡信息
    /// </summary>
    public void SaveCardInfo()
    {
        //单位编号
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        //持卡人
        string cardholder = Convert.ToString(Request.Form["cardholder"]);
        //卡号
        string cardNumber = Convert.ToString(Request.Form["cardNumber"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@deptid",deptId),
            new SqlParameter("@cardholder",cardholder),
            new SqlParameter("@cardnumber",cardNumber)
        };
        StringBuilder sql = new StringBuilder();
        //不存在当前单位的该公务卡信息，则插入新数据
        sql.Append("if not exists (select * from cardinfo where deptid=@deptid and cardnumber=@cardnumber)");
        sql.Append(" insert into cardinfo values(@deptid,@cardholder,@cardnumber);  ");
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"该单位已存在当前公务卡信息，请检查输入！\"}");
    }
    /// <summary>
    /// 更新公务卡信息
    /// </summary>
    public void UpdateCardInfo()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        //单位编号
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        //持卡人
        string cardholder = Convert.ToString(Request.Form["cardholder"]);
        //卡号
        string cardNumber = Convert.ToString(Request.Form["cardNumber"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@deptid",deptId),
            new SqlParameter("@cardholder",cardholder),
            new SqlParameter("@cardnumber",cardNumber)
        };
        string sql = "update cardinfo set deptid=@deptid,cardholder=@cardholder,cardnumber=@cardnumber where cardid=@id;";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错！\"}");
    }
    /// <summary>
    /// 通过id删除公务卡信息
    /// </summary>
    public void RemoveCardInfoByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter para = new SqlParameter("@id", id);
        string sql = "delete from Cardinfo where cardid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错！\"}");
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
  
  
}