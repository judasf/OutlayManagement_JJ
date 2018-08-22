<%@ WebHandler Language="C#" Class="PublicOutlayAllocate" %>

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
/// 定额公用经费生成
/// </summary>
public class PublicOutlayAllocate : IHttpHandler, IRequiresSessionState
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
    /// 基层用户的部门编号
    /// </summary>
    string deptid;
    /// <summary>
    /// 当前用户名
    /// </summary>
    string username;
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
        else
        {
            UserDetail ud = new UserDetail();
            roleid = ud.LoginUser.RoleId.ToString();
            scopeDepts = ud.LoginUser.ScopeDepts;
            deptid = ud.LoginUser.DeptId.ToString();
            username = ud.LoginUser.UserName;
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
    #region 稽核操作
    /// <summary>
    /// 稽核生成全部单位定额公用经费
    /// </summary>
    public void CreateAllPublicOutlay()
    {
        string outlayMonth = Convert.ToString(Request.Form["OutlayMonth"]);
        if (outlayMonth == "")
        {
            Response.Write("{\"success\":false,\"msg\":\"请设置月份！\"}");
            return;
        }
        string where = "";
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            where += " where a.deptid=" + Request.Form["deptId"];
        else if (scopeDepts != "0")
            where += " where a.deptid in(" + scopeDepts + ")";

        StringBuilder sql = new StringBuilder();
        sql.Append("if not exists (select * from PublicOutlayDetail a join deptlevelinfo b");
        sql.Append("  on a.deptid=b.deptid and  a.outlaymonth=@outlayMonth " + where + ") ");
        sql.Append("insert into PublicOutlayDetail(outlaymonth,deptid,");
        sql.Append("deptname,leveloutlay,peoplenum,monthoutlay,status,outlaytime)");
        sql.Append("select @outlayMonth,a.deptid,deptname,leveloutlay,deptpeoplenum,leveloutlay*deptpeoplenum,");
        sql.Append("0,getdate() from deptlevelinfo a join  outlaylevel b on  a.levelid=b.levelid ");
        sql.Append("join department c on a.deptid=c.deptid ");
        sql.Append(where);
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), new SqlParameter("@outlayMonth", outlayMonth));
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"当月公用经费已生成，请不要重复操作！\"}");
    }
    /// <summary>
    /// 设置定额公用经费明细的查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForPublicOutlayDetail()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        if (!string.IsNullOrEmpty(Request.Form["outlayMonth"]))
            list.Add(" outlayMonth ='" + Request.Form["outlayMonth"] + "'");
        else//默认只显示当年数据
            list.Add(" left(outlayMonth,4) = YEAR(GETDATE())");
        if (!string.IsNullOrEmpty(Request.Form["deptid"]))
            list.Add(" deptid ='" + Request.Form["deptid"] + "'");
        if (!string.IsNullOrEmpty(Request.Form["status"]))
            list.Add(" status =" + Request.Form["status"]);
        //基层用户只显示本单位已下发的公用经费
        if (roleid == "1")
            list.Add(" deptid=" + deptid.ToString() + " and status=2 ");
        //稽核默认显示未送审和退回的信息，处长默认显示未审批的信息
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "2")
            list.Add(" status<1 ");
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "4")
            list.Add(" status=1 ");
        //管理员默认显示已下发额度
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "6")
            list.Add(" status=2 ");
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" deptid in (" + scopeDepts + ") ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取PublicOutlayDetail：基层单位生成的公用经费明细 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetPublicOutlayDetail()
    {
        int total = 0;
        string where = SetQueryConditionForPublicOutlayDetail();
        string tableName = "PublicOutlayDetail";
        string fieldStr = "*";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "monthoutlay", "peoplenum", "合计"));
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
    /// <summary>
    /// 稽核送审生成的公用经费到处长
    /// </summary>
    public void AuditPublicOutlay()
    {
        string id = Convert.ToString(Request.Form["id"]);
        if (id.Length == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"参数错误\"}");
            return;
        }
        id = "(" + id + ")";
        string sql = "if not exists(select * from PublicOutlayDetail where id in" + id + " and status>0) ";
        sql += "update  PublicOutlayDetail set status=1,Auditor='" + username + "',AuditTime=getdate() where id in" + id;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql);
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"该经费已送审，不要重复操作！\"}");
    }

    /// <summary>
    /// 稽核通过id删除未送审的PublicOutlayDetail信息
    /// </summary>
    public void RemovePublicOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM PublicOutlayDetail WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 导出定额公用经费——稽核
    /// </summary>
    public void ExportAuditPublicOutlayDetail()
    {
        string where = SetQueryConditionForPublicOutlayDetail();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select outlaymonth,deptname,leveloutlay,peoplenum,monthoutlay,audittime,approvetime,");
        sql.Append("status= case when status=-1 then '被退回' when status=0 then '待送审' ");
        sql.Append(" when status=1 then '待审批' when status=2 then '已下发' end");
        sql.Append(" from PublicOutlayDetail ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "月份";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "经费标准(每人：元/月)";
        dt.Columns[3].ColumnName = "单位人数";
        dt.Columns[4].ColumnName = "当月经费";
        dt.Columns[5].ColumnName = "生成时间";
        dt.Columns[6].ColumnName = "下发时间";
        dt.Columns[7].ColumnName = "状态";
        MyXls.CreateXls(dt, "定额公用经费明细.xls", "2,5,6");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 处长操作
    /// <summary>
    /// 处长审批并下发定额公用经费
    /// </summary>
    public void ApproverPublicOutlay()
    {
        string id = Convert.ToString(Request.Form["id"]);
        if (id.Length == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"参数错误\"}");
            return;
        }
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@ids", SqlDbType.VarChar),
            new SqlParameter("@approver", SqlDbType.NVarChar)
    };
        paras[0].Value = id;
        paras[1].Value = username;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "AllocateDeptPublicOutlay", paras);
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错！\"}");
    }
    /// <summary>
    /// 处长通过id退回PublicOutlayDetail生成的定额公用经费明细信息到稽核员
    /// </summary>
    public void BackPublicOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update PublicOutlayDetail set status=-1 WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 导出定额公用经费明细——处长
    /// </summary>
    public void ExportApprovePublicOutlay()
    {
        ExportAuditPublicOutlayDetail();
    }
    #endregion
    #region 基层用户操作
    /// <summary>
    /// 基层用户获取自己的汇总后的公用经费(单条信息),用于datagrid
    /// </summary>
    public void GetPublicOutlay()
    {
        string queryStr = "where ";
        //设置查询条件
        if (roleid == "1")
            queryStr += " a.deptid =" + deptid;
        else
            queryStr += " a.deptid ='" + Convert.ToString(Request.Form["deptid"]) + "'";
        string sql = "select a.*,deptname from publicoutlay a join department b on a.deptid=b.deptid " + queryStr;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, 1));
    }
    /// <summary>
    /// 基层用户获取自己的汇总后的公用经费(单条信息)
    /// </summary>
    public void GetPublicOutlayByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        string sql = "select a.*,deptname,'" + username + "' as username,'" + username + "' as reimburseuser from publicoutlay a join department b on a.deptid=b.deptid where a.id=@id";
        SqlParameter para = new SqlParameter("@id", SqlDbType.Int);
        para.Value = id;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 基层用户导出已生成定额公用经费
    /// </summary>
    public void ExportUserPublicOutlayDetail()
    {
        string where = SetQueryConditionForPublicOutlayDetail();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select outlaymonth,deptname,leveloutlay,peoplenum,monthoutlay,approvetime");
        sql.Append(" from PublicOutlayDetail ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "月份";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "经费标准(每人：元/月)";
        dt.Columns[3].ColumnName = "单位人数";
        dt.Columns[4].ColumnName = "当月经费";
        dt.Columns[5].ColumnName = "下发时间";
        MyXls.CreateXls(dt, "定额公用经费下发明细.xls", "2,5");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 管理员操作
    /// <summary>
    /// 管理员将已下发的定额公用经费申请退回到处长重新审批，操作数据表PublicOutlayDetail
    /// 1、公用经费根据deptid判断经费是否满足扣减
    /// 2、初始化处长和稽核确认的信息
    /// </summary>
    public void BackHasCreatePublicOutlayToApprove()
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
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "BackHasCreatePublicOutlayToApprove", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该项申请已退回处长审批！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该单位公用经费的可用额度不足，不能退回处长审批！\"}");
        if (result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    #endregion
}