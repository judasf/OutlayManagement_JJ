<%@ WebHandler Language="C#" Class="UserInfo" %>

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
/// 用户信息操作
/// </summary>
public class UserInfo : IHttpHandler, IRequiresSessionState
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
        if (!Request.IsAuthenticated)
        {
            Response.Write("{\"success\":false,\"msg\":\"登陆超时，请重新登陆后再进行操作！\",\"total\":-1,\"rows\":[]}");
            return;
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
    }
    /// <summary>
    /// 设置用户管理查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForUserInfo()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        if (!string.IsNullOrEmpty(Request.Form["userNum"]))
            list.Add(" usernum like'%" + Request.Form["userNum"] + "%'");
        if (!string.IsNullOrEmpty(Request.Form["userName"]))
            list.Add(" userName like'%" + Request.Form["userName"] + "%'");
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            list.Add(" a.deptId =" + Request.Form["deptId"]);
        if (!string.IsNullOrEmpty(Request.Form["roleId"]))
            list.Add(" a.roleId =" + Request.Form["roleId"]);
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取UserInfo 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetUserInfo()
    {
        int total = 0;
        string where = SetQueryConditionForUserInfo();
        string tableName = "userinfo a join roleinfo b on a.roleid=b.roleid left join department c on a.deptid=c.deptid";
        string fieldStr = "UID,UserNum,UserName,DeptName,RoleName,a.RoleID,ScopeDepts,userstatus";
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
    /// 通过uId获取UserInfo信息
    /// </summary>
    public void GetUserInfoByID()
    {
        int uid = Convert.ToInt32(Request.Form["UID"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = uid;
        string sql = "SELECT * FROM UserInfo WHERE UID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 保存UserInfo信息
    /// </summary>
    public void SaveUserInfo()
    {
        string userNum = Convert.ToString(Request.Form["userNum"]);
        string userName = Convert.ToString(Request.Form["userName"]);
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        int roleId = Convert.ToInt32(Request.Form["roleId"]);
        //非基层用户、部门负责人、部门主管领导外没有部门编号
        if (roleId != 1 &&roleId != 8 &&roleId != 9)
            deptId = 0;
        string userPwd = System.Web.Security.FormsAuthentication.HashPasswordForStoringInConfigFile("888888", "MD5");
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@userNum",SqlDbType.VarChar),
            new SqlParameter("@userName",SqlDbType.NVarChar),
            new SqlParameter("@deptId",SqlDbType.Int),
            new SqlParameter("@roleId",SqlDbType.Int),
            new SqlParameter("@userPwd",SqlDbType.NVarChar)
        };
        paras[0].Value = userNum;
        paras[1].Value = userName;
        paras[2].Value = deptId;
        paras[3].Value = roleId;
        paras[4].Value = userPwd;
        //scopeDepts(管辖范围默认值：'0'),基层用户指自己单位，非基层用户默认全部基层单位，初始密码：888888
        //判断用户编号是否存在
        string sql = "if not exists(select * from userinfo where usernum=@userNum) ";
        sql += "INSERT INTO UserInfo VALUES(@userNum,@userPwd,@userName,@deptId,@roleId,'0',0)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"用户编号已存在，请检查输入！\"}");
    }
    /// <summary>
    /// 更新用户信息
    /// </summary>
    public void UpdateUserInfo()
    {
        int uid = Convert.ToInt32(Request.Form["uid"]);
        string userNum = Convert.ToString(Request.Form["userNum"]);
        string userName = Convert.ToString(Request.Form["userName"]);
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        int roleId = Convert.ToInt32(Request.Form["roleId"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@uid",SqlDbType.Int),
          new SqlParameter("@userNum",SqlDbType.VarChar),
            new SqlParameter("@userName",SqlDbType.NVarChar),
            new SqlParameter("@deptId",SqlDbType.Int),
            new SqlParameter("@roleId",SqlDbType.Int)
        };
        paras[0].Value = uid;
        paras[1].Value = userNum;
        paras[2].Value = userName;
        paras[3].Value = deptId;
        paras[4].Value = roleId;

        string sql = "UPDATE UserInfo set usernum=@userNum,userName=@userName,deptId=@deptId,roleId=@roleId where uid=@uid";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");
    }
    /// <summary>
    /// 通过uid获取删除UserInfo信息
    /// </summary>
    public void RemoveUserInfoByID()
    {
        int uid = 0;
        int.TryParse(Request.Form["uid"], out uid);

        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = uid;
        string sql = "DELETE FROM UserInfo WHERE uid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过uid恢复用户密码
    /// </summary>
    public void ResetPwdByID()
    {
        int uid = 0;
        int.TryParse(Request.Form["uid"], out uid);
        string userPwd = System.Web.Security.FormsAuthentication.HashPasswordForStoringInConfigFile("888888", "MD5");
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@id", SqlDbType.Int),
            new SqlParameter("@userPwd", SqlDbType.VarChar)
        };
        paras[0].Value = uid;
        paras[1].Value = userPwd;
        string sql = "update UserInfo set UserPwd=@userPwd WHERE uid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 锁定一般用户
    /// </summary>
    public void LockUserByID()
    {
        int uid = 0;
        int.TryParse(Request.Form["uid"], out uid);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = uid;
        string sql = "update UserInfo set userstatus=1 WHERE uid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 锁定全部一般用户
    /// </summary>
    public void LockAllUser()
    {
        string sql = "update UserInfo set userstatus=1 WHERE roleid=1";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql);
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 解锁一般用户
    /// </summary>
    public void UnLockUserByID()
    {
        int uid = 0;
        int.TryParse(Request.Form["uid"], out uid);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = uid;
        string sql = "update UserInfo set userstatus=0 WHERE uid=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 解锁全部一般用户
    /// </summary>
    public void UnLockAllUser()
    {
        string sql = "update UserInfo set userstatus=0 WHERE roleid=1";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql);
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 设置非基层用户审批范围
    /// </summary>
    public void SetScopeDepts()
    {
        int uid = 0;
        int.TryParse(Request.Form["uid"], out uid);
        string scopeDepts = Convert.ToString(Request.Form["scopeDepts"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@uid",SqlDbType.Int),
          new SqlParameter("@scopeDepts",SqlDbType.VarChar)
        };
        paras[0].Value = uid;
        paras[1].Value = scopeDepts;
        string sql = "UPDATE UserInfo set scopeDepts=@scopeDepts where uid=@uid";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"设置成功！\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行错误\"}");
    }
    /// <summary>
    /// 获取非基层用户的信息列表combobgrid使用的json字符串
    /// </summary>
    public void GetManagerInfo()
    {
        int total = 0;
        string where = " a.roleid<>1 ";
        string table = " userinfo a join roleinfo b on a.roleid=b.roleid ";
        string fieldStr = "a.uid,a.username,b.rolename";
        DataSet ds = SqlHelper.GetPagination(table, fieldStr, Request["sort"].ToString(), Request["order"].ToString(), where, Convert.ToInt32(Request["rows"]), Convert.ToInt32(Request["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 获取非基层用户的信息列表combobox使用的json字符串
    /// </summary>
    public void GetManagerInfoCombobox()
    {
        string sql = "select uid,username from userinfo where roleid<>1 order by uid";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        Response.Write(JsonConvert.CreateComboboxJson(ds.Tables[0]));
    }
    /// <summary>
    /// 修改密码
    /// </summary>
    public void EditPasswd()
    {
        int uid = 0;
        int.TryParse(Request.Form["uid"], out uid);
        string oldPwd = System.Web.Security.FormsAuthentication.HashPasswordForStoringInConfigFile(Convert.ToString(Request.Form["oldPwd"]), "MD5");
        string pwd = System.Web.Security.FormsAuthentication.HashPasswordForStoringInConfigFile(Convert.ToString(Request.Form["pwd"]), "MD5");
        string rePwd = System.Web.Security.FormsAuthentication.HashPasswordForStoringInConfigFile(Convert.ToString(Request.Form["rePwd"]), "MD5");
        if (pwd != rePwd)
        {
            Response.Write("{\"success\":false,\"msg\":\"两次密码输入不一致！\"}");
            return;
        }
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@uid",SqlDbType.Int),
          new SqlParameter("@oldPwd",SqlDbType.VarChar),
            new SqlParameter("@pwd",SqlDbType.NVarChar)
        };
        paras[0].Value = uid;
        paras[1].Value = oldPwd;
        paras[2].Value = pwd;
        StringBuilder sql = new StringBuilder();
        sql.Append("if exists(select * from userinfo  where uid=@uid and userpwd=@oldPwd)");
        sql.Append("update userinfo set userpwd=@pwd where uid =@uid");
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"修改成功！\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"原密码不正确！\"}");

    }
    /// <summary>
    /// 导出用户信息
    /// </summary>
    public void ExportUserInfo()
    {
        string where = SetQueryConditionForUserInfo();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select UserNum,RoleName,UserName,DeptName ");
        sql.Append(" from userinfo a join roleinfo b on a.roleid=b.roleid  ");
        sql.Append(" left join department c on a.deptid=c.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "用户编号";
        dt.Columns[1].ColumnName = "角色名称";
        dt.Columns[2].ColumnName = "用户名";
        dt.Columns[3].ColumnName = "单位名称";
        MyXls.CreateXls(dt, "用户信息表.xls", "");
        Response.Flush();
        Response.End();
    }
   
}