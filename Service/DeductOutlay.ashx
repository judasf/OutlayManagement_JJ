<%@ WebHandler Language="C#" Class="DeductOutlay" %>

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
/// 稽核申请的经费扣减处理
/// </summary>
public class DeductOutlay : IHttpHandler, IRequiresSessionState
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
    /// 用户部门编号
    /// </summary>
    string deptid;
    /// <summary>
    /// 登陆用户部门名
    /// </summary>
    string deptName;
    /// <summary>
    /// 当前登陆用户名
    /// </summary>
    string userName;
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
            scopeDepts = ud.LoginUser.ScopeDepts;
            deptid = ud.LoginUser.DeptId.ToString();
            deptName = ud.LoginUser.UserDept;
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
    /// 设置经费扣减明细查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForDeductOutlay()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按月份查询
        if (!string.IsNullOrEmpty(Request.Form["outlayMonth"]))
            list.Add(" outlayMonth ='" + Request.Form["outlayMonth"] + "'");
        else//默认只显示当年数据 
            list.Add(" left(outlayMonth,4) = YEAR(GETDATE())");
        //按专项经费额度编号OutlayID
        if (!string.IsNullOrEmpty(Request.Form["SpecialOutlayID"]))
            list.Add(" SpecialOutlayID like'%" + Request.Form["SpecialOutlayID"] + "%'");
        //按单位名称
        //基层用户只获取自己的信息
        if (roleid == "1")
            list.Add(" deptid= " + deptid);
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" deptid ='" + Request.Form["deptid"] + "'");
        }
        //按状态查询
        if (!string.IsNullOrEmpty(Request.Form["status"]))
            list.Add(" status =" + Request.Form["status"]);
        //按经费类别
        if (!string.IsNullOrEmpty(Request.Form["outlaycategory"]))
            list.Add(" outlaycategory =" + Request.Form["outlaycategory"]);
        //基层用户和管理员显示已扣减(2)的信息，处长默认显示已送审(1)可查询已扣减(2)的信息，稽核默认显示全部信息
        if (string.IsNullOrEmpty(Request.Form["status"]) && (roleid == "1" || roleid == "6"))
            list.Add(" status=2 ");
        //处长显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "4")
            list.Add(" status=1 ");
        //稽核显示全部
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" deptid in (" + scopeDepts + ") ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取稽核经费扣减申请明细DeductOutlayDetail 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetDeductOutlayDetail()
    {
        int total = 0;
        string where = SetQueryConditionForDeductOutlay();
        string tableName = "DeductOutlayDetail left join category on outlaycategory=cid";
        string fieldStr = "DeductOutlayDetail.*,cname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "deductoutlay", "cname", "合计"));
    }
    /// <summary>
    ///  通过ID获取DeductOutlayDetail
    /// </summary>
    public void GetDeductOutlayDetailByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT DeductOutlayDetail.*,cname FROM DeductOutlayDetail left join category on outlaycategory=cid  where  ID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #region 基层用户
    /// <summary>
    /// 基层用户导出已扣减的扣减经费明细
    /// </summary>
    public void ExportUserDeductOutlayDetail()
    {
        string where = SetQueryConditionForDeductOutlay();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select outlaymonth,deptname,deductno,cname,deductoutlay,");
        sql.Append("specialoutlayid=case when specialoutlayid=0 then '无' else convert(varchar(50),specialoutlayid) end,");
        sql.Append(" deductreason,applyuser,approvetime,");
        sql.Append("status= case when status=-1 then '被退回' when status=0 then '待送审'");
        sql.Append(" when status=1 then '待审批' when status=2 then '已扣减' end ");
        sql.Append(" from DeductOutlayDetail left join category on outlaycategory=cid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "月份";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "扣减编号";
        dt.Columns[3].ColumnName = "经费类别";
        dt.Columns[4].ColumnName = "扣减额度";
        dt.Columns[5].ColumnName = "被扣减额度编号";
        dt.Columns[6].ColumnName = "扣减原因";
        dt.Columns[7].ColumnName = "经办人";
        dt.Columns[8].ColumnName = "扣减时间";
        dt.Columns[9].ColumnName = "状态";
        MyXls.CreateXls(dt, "扣减经费明细.xls", "6,8");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 稽核操作
    /// <summary>
    /// 保存DeductOutlayDetail 表扣减额度申请
    /// </summary>
    public void SaveDeductOutlayDetail()
    {
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        string deptName = Convert.ToString(Request.Form["deptName"]);
        int outlayCategory = Convert.ToInt32(Request.Form["outlayCategory"]);
        int specialOutlayID = Convert.ToInt32(Request.Form["specialOutlayID"]);
        decimal deductOutlay = Convert.ToDecimal(Request.Form["deductOutlay"]);
        string deductReason = Convert.ToString(Request.Form["deductReason"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@deptid",SqlDbType.Int),
            new SqlParameter("@deptname",SqlDbType.NVarChar),
            new SqlParameter("@outlaycategory",SqlDbType.Int),
            new SqlParameter("@specialoutlayid",SqlDbType.Int),
            new SqlParameter("@deductoutlay",SqlDbType.Decimal),
            new SqlParameter("@deductReason",SqlDbType.NVarChar),
            new SqlParameter("@applyuser",SqlDbType.NVarChar),
            new SqlParameter("@outlaymonth",SqlDbType.NVarChar)
        };
        paras[0].Value = deptId;
        paras[1].Value = deptName;
        paras[2].Value = outlayCategory;
        paras[3].Value = specialOutlayID;
        paras[4].Value = deductOutlay;
        paras[5].Value = deductReason;
        paras[6].Value = userName;
        paras[7].Value = DateTime.Now.ToString("yyyy年MM月");
        string sql = "INSERT INTO DeductOutlayDetail(OutlayMonth,DeductTime,DeptId,DeptName,OutlayCategory,DeductOutlay,SpecialOutlayID,Status,DeductReason,ApplyUser) VALUES(@outlaymonth,getdate(),@deptid,@deptname,@outlaycategory,@deductoutlay,@specialoutlayid,'0',@deductReason,@applyuser)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 更新申请报告
    /// </summary>
    public void UpdateDeductOutlayDetail()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        string deptName = Convert.ToString(Request.Form["deptName"]);
        int outlayCategory = Convert.ToInt32(Request.Form["outlayCategory"]);
        int specialOutlayID = Convert.ToInt32(Request.Form["specialOutlayID"]);
        decimal deductOutlay = Convert.ToDecimal(Request.Form["deductOutlay"]);
        string deductReason = Convert.ToString(Request.Form["deductReason"]);
        SqlParameter[] paras = new SqlParameter[] {
             new SqlParameter("@deptid",SqlDbType.Int),
            new SqlParameter("@deptname",SqlDbType.NVarChar),
            new SqlParameter("@outlaycategory",SqlDbType.Int),
            new SqlParameter("@specialoutlayid",SqlDbType.Int),
            new SqlParameter("@deductoutlay",SqlDbType.Decimal),
            new SqlParameter("@deductReason",SqlDbType.NVarChar),
            new SqlParameter("@applyuser",SqlDbType.NVarChar),
            new SqlParameter("@outlaymonth",SqlDbType.NVarChar),
            new SqlParameter("@id",SqlDbType.Int)
        };
        paras[0].Value = deptId;
        paras[1].Value = deptName;
        paras[2].Value = outlayCategory;
        paras[3].Value = specialOutlayID;
        paras[4].Value = deductOutlay;
        paras[5].Value = deductReason;
        paras[6].Value = userName;
        paras[7].Value = DateTime.Now.ToString("yyyy年MM月");
        paras[8].Value = id;
        StringBuilder sql = new StringBuilder();
        sql.Append("update  DeductOutlayDetail set DeductTime=getdate(),DeptId=@deptid,DeptName=@deptname,");
        sql.Append("OutlayMonth=@outlaymonth,specialoutlayid=@specialoutlayid,deductoutlay=@deductoutlay,");
        sql.Append("OutlayCategory=@outlaycategory,deductReason=@deductReason  where id=@id");
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 送审经费申请到处长审批
    /// </summary>
    public void SendDeductOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update DeductOutlayDetail set status=1 WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过id删除DeductOutlayDetail 表申请记录
    /// </summary>
    public void RemoveDeductOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM DeductOutlayDetail WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过deptid获取基层用户的公用经费可用额度
    /// </summary>
    public void GetPublicUnusedOutlayByDeptID()
    {
        int deptId = 0;
        int.TryParse(Request.Form["deptId"], out deptId);
        string sql = "select UnusedOutlay from publicoutlay where deptid=@deptid";
        SqlParameter para = new SqlParameter("@deptId", SqlDbType.Int);
        para.Value = deptId;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if(ds.Tables[0].Rows.Count > 0)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\",\"val\":\"" + ds.Tables[0].Rows[0][0].ToString() + "\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"该单位无公用经费额度！\"}");
    }
    /// <summary>
    /// 通过deptid和outlayid获取基层用户的专项经费的可用额度
    /// </summary>
    public void GetSpecialUnusedOutlayByDeptIDAndOutlayID()
    {
        int deptId = 0;
        int.TryParse(Request.Form["deptId"], out deptId);
        int outlayId = 0;
        int.TryParse(Request.Form["outlayId"], out outlayId);
        string sql = "select UnusedOutlay from SpecialOutlay where deptid=@deptid and outlayId=@outlayid";
        SqlParameter[] para = new SqlParameter[] {
            new SqlParameter("@deptId", SqlDbType.Int),
            new SqlParameter("@outlayid", SqlDbType.Int)
        };
        para[0].Value = deptId;
        para[1].Value = outlayId;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        if(ds.Tables[0].Rows.Count > 0)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\",\"val\":\"" + ds.Tables[0].Rows[0][0].ToString() + "\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"该单位无可用的专项经费额度！\"}");
    }
    /// <summary>
    /// 通过deptid获取基层用户已生成的专项额度 SpecialOutlay,来初始化specialOutlayID的combogrid
    /// </summary>
    public void GetSpecialOutlayByDeptID()
    {
        string sendDeptId = Convert.ToString(Request.QueryString["deptId"]);
        int total = 0;
        string where = "";
        string tableName = "SpecialOutlay left join category on outlaycategory=cid";
        string fieldStr = "SpecialOutlay.*,cname";
        //设置查询条件
        List<string> list = new List<string>();
        list.Add(" UnusedOutlay>0 ");
        list.Add(" deptid=" + sendDeptId);
        if(list.Count > 0)
            where = string.Join(" and ", list.ToArray());
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 导出扣减经费明细——稽核
    /// </summary>
    public void ExportDeductOutlayApplyDetail()
    {
        ExportUserDeductOutlayDetail();
    }
    #endregion
    #region 处长操作
    /// <summary>
    /// 退回追加经费申请到稽核
    /// </summary>
    public void BackDeductOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update DeductOutlayDetail set status=-1 WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过稽核申请的扣减经费，经费类别的不同扣减对应的经费，公用经费通过deptid扣减，专项经费通过deptid和specialoutlayid进行扣减
    /// </summary>
    public void ApproveDeductOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //经费扣减编号，自动生成格式为：2014001
        int deductOutlayNo;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select top 1  DeductOutlayNo from autono");
        string currentNo = ds.Tables[0].Rows[0][0].ToString();
        if(currentNo.Substring(0, 4) == DateTime.Now.ToString("yyyy"))
            deductOutlayNo = int.Parse(currentNo) + 1;
        else
            deductOutlayNo = int.Parse(DateTime.Now.ToString("yyyy") + "001");
        //存储过程返回值
        int result;
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@deductoutlayno",SqlDbType.Int),
            new SqlParameter("@approver",SqlDbType.NVarChar),
            new SqlParameter("@result",SqlDbType.Int)
        };
        paras[0].Value = id;
        paras[1].Value = deductOutlayNo;
        paras[2].Value = userName;
        paras[3].Direction = ParameterDirection.ReturnValue;
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "ApproveDeductOutlayApply", paras);
        result = (int)paras[3].Value;
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        if(result == -1)
            Response.Write("{\"success\":false,\"msg\":\"被扣减经费可用额度不足，请退回该项申请！\"}");
        if(result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，扣减申请不存在\"}");
    }
    #endregion
    #region 管理员操作
    /// <summary>
    /// 管理员将已扣减的稽核扣减经费申请退回到处长重新审批，并恢复被扣减的额度，操作数据表DeductOutlayDetail
    /// 1、根据经费类别，判断是公用经费还是专项经费，公用经费根据deptid恢复被扣减额度，专项经费根据deptid和额度编号outlayid在表SpecialOutlay中恢复被扣减额度
    /// 2、初始化处长和稽核确认的信息
    /// </summary>
    public void BackHasDeductOutlayApplyToApprove()
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
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "BackHasDeductOutlayApplyToApprove", paras);
        result = (int)paras[1].Value;
        if(result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该经费扣减申请已退回处长审批，并已恢复被扣减额度！\"}");
        if(result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    #endregion 
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
}