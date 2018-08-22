<%@ WebHandler Language="C#" Class="AuditApplyOutlayAllocate" %>

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
/// 稽核申请的经费追加处理
/// </summary>
public class AuditApplyOutlayAllocate : IHttpHandler, IRequiresSessionState
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
            deptName = ud.LoginUser.UserDept;
            userName = ud.LoginUser.UserName;
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
    /// 设置稽核直接追加经费申请明细查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForAuditApplyOutlay()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按月份查询
        if (!string.IsNullOrEmpty(Request.Form["outlayMonth"]))
            list.Add(" outlayMonth ='" + Request.Form["outlayMonth"] + "'");
        else//默认只显示当年数据
            list.Add(" left(outlayMonth,4) = YEAR(GETDATE())");

        //按额度编号OutlayID
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" OutlayID like'%" + Request.Form["outlayid"] + "%'");
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
        //基层用户和管理员显示已生成(2)的信息，处长默认显示已送审(1)可查询已生成(2)的信息，稽核默认显示全部信息
        if (string.IsNullOrEmpty(Request.Form["status"]) && (roleid == "1" || roleid == "6"))
            list.Add(" status=2 ");
        //处长显示
        if (string.IsNullOrEmpty(Request.Form["status"]) && roleid == "4")
            list.Add(" status=1 ");
        //稽核显示
        //if(string.IsNullOrEmpty(Request.Form["status"]) && roleid == "2")
        //    list.Add(" status=3 ");
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" deptid in (" + scopeDepts + ") ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取稽核经费追加申请明细AuditApplyOutlayDetail 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetAuditApplyOutlayDetail()
    {
        int total = 0;
        string where = SetQueryConditionForAuditApplyOutlay();
        string tableName = "AuditApplyOutlayDetail left join category on outlaycategory=cid";
        string fieldStr = "AuditApplyOutlayDetail.*,cname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "applyoutlay", "applytitle", "合计"));
    }
    /// <summary>
    ///  通过ID获取AuditApplyOutlayDetail
    /// </summary>
    public void GetAuditApplyOutlayDetailByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT a.*,b.cname FROM AuditApplyOutlayDetail a left join category b on a.OutlayCategory=b.cid where  a.ID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #region 基层用户
    /// <summary>
    /// 基层用户导出已生成的直接拨付经费明细
    /// </summary>
    public void ExportHasCreateAuditApplyOutlay()
    {
        string where = SetQueryConditionForAuditApplyOutlay();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select outlaymonth,deptname,outlayid,applytitle,applyoutlay,");
        sql.Append("cname,usefor,applyuser,applytime,");
        sql.Append("status=case when status=-1  then '被退回' when status=0  then '待送审'");
        sql.Append(" when status=1  then '待审批' when status=2  then '已生成' end ");
        sql.Append(" from AuditApplyOutlayDetail left join category on outlaycategory=cid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "月份";
        dt.Columns[1].ColumnName = "单位名称";
        dt.Columns[2].ColumnName = "额度编号";
        dt.Columns[3].ColumnName = "标题";
        dt.Columns[4].ColumnName = "可用额度";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "用途";
        dt.Columns[7].ColumnName = "经办人";
        dt.Columns[8].ColumnName = "申请时间";
        dt.Columns[9].ColumnName = "状态";
        MyXls.CreateXls(dt, "直接拨付经费明细.xls", "3,6,8");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 稽核操作
    /// <summary>
    /// 保存AuditApplyOutlayDetail 表申请
    /// </summary>
    public void SaveAuditApplyOutlayDetail()
    {
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        string deptName = Convert.ToString(Request.Form["deptName"]);
        string title = Convert.ToString(Request.Form["title"]);
        string content = Convert.ToString(Request.Form["editorValue"]);
        int outlayCategory = Convert.ToInt32(Request.Form["outlayCategory"]);
        decimal applyOutlay = Convert.ToDecimal(Request.Form["applyOutlay"]);
        string usefor = Convert.ToString(Request.Form["usefor"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@deptid",SqlDbType.Int),
            new SqlParameter("@deptname",SqlDbType.NVarChar),
            new SqlParameter("@title",SqlDbType.NVarChar),
            new SqlParameter("@content",SqlDbType.NVarChar),
            new SqlParameter("@outlaycategory",SqlDbType.Int),
            new SqlParameter("@applyoutlay",SqlDbType.Decimal),
            new SqlParameter("@usefor",SqlDbType.NVarChar),
            new SqlParameter("@applyuser",SqlDbType.NVarChar),
            new SqlParameter("@outlaymonth",SqlDbType.NVarChar)
        };
        paras[0].Value = deptId;
        paras[1].Value = deptName;
        paras[2].Value = title;
        paras[3].Value = content;
        paras[4].Value = outlayCategory;
        paras[5].Value = applyOutlay;
        paras[6].Value = usefor;
        paras[7].Value = userName;
        paras[8].Value = DateTime.Now.ToString("yyyy年MM月");
        string sql = "INSERT INTO AuditApplyOutlayDetail(ApplyTime,DeptId,DeptName,ApplyTitle,ApplyContent,Status,ApplyUser,OutlayMonth,ApplyOutlay,OutlayCategory,UseFor) VALUES(getdate(),@deptid,@deptname,@title,@content,'0',@applyuser,@outlaymonth,@applyoutlay,@outlaycategory,@usefor);";
        sql += "SELECT CAST(scope_identity() AS int);";
        //获取插入记录的ID
        int AAOID = (Int32)SqlHelper.ExecuteScalar(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        StringBuilder insql = new StringBuilder();
        List<SqlParameter> _paras = new List<SqlParameter>();
        _paras.Add(new SqlParameter("@AuditApplyOutlayID", AAOID));
        //、获取附件信息
        //附件
        string filesNameStr = Convert.ToString(Request.Form["reportName"]);
        string filesPathStr = Convert.ToString(Request.Form["report"]);
        //获取附件名称
        if (!string.IsNullOrEmpty(filesNameStr))
        {
            string[] filesName = filesNameStr.Split(new String[] { "," }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < filesName.Length; i++)
            {
                _paras.Add(new SqlParameter("@AttFileName" + i.ToString(), filesName[i]));

            }
        }//获取附件路径
        if (!string.IsNullOrEmpty(filesPathStr))
        {
            string[] filesPath = filesPathStr.Split(new String[] { "," }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < filesPath.Length; i++)
            {
                _paras.Add(new SqlParameter("@AttFilePath" + i.ToString(), filesPath[i]));
                insql.Append("Insert into AuditApplyOutlay_Attachment values(@AuditApplyOutlayID,@AttFileName" + i.ToString() + ",@AttFilePath" + i.ToString() + ");");
            }
            SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, insql.ToString(), _paras.ToArray());
        }

        if (AAOID > 0)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 批量追加经费
    /// </summary>
    public void SaveAuditBatchApplyOutlayDetail()
    {
        int outlayCategory = Convert.ToInt32(Request.Form["outlayCategory"]);
        string title = Convert.ToString(Request.Form["title"]);
        string usefor = Convert.ToString(Request.Form["usefor"]);
        //获取数据行数
        int rowsCount = 0;
        Int32.TryParse(Request.Form["rowsCount"], out rowsCount);
        if (rowsCount == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"请录入追加经费申请信息\"}");
            return;
        }
        //根据数据行数生成sql语句和参数列表
        StringBuilder sql = new StringBuilder();
        List<SqlParameter> paras = new List<SqlParameter>();
        paras.Add(new SqlParameter("@outlaycategory", outlayCategory));
        paras.Add(new SqlParameter("@title", title));
        paras.Add(new SqlParameter("@usefor", usefor));
        paras.Add(new SqlParameter("@applyuser", userName));
        paras.Add(new SqlParameter("@outlaymonth", DateTime.Now.ToString("yyyy年MM月")));
        for (int i = 1; i <= rowsCount; i++)
        {
            paras.Add(new SqlParameter("@deptid" + i.ToString(), Request.Form["deptId" + i.ToString()]));
            paras.Add(new SqlParameter("@deptname" + i.ToString(), Request.Form["deptName" + i.ToString()]));
            paras.Add(new SqlParameter("@applyoutlay" + i.ToString(), Request.Form["applyOutlay" + i.ToString()]));
            sql.Append("INSERT INTO AuditApplyOutlayDetail(ApplyTime,DeptId,DeptName,ApplyTitle,ApplyContent,Status,ApplyUser,OutlayMonth,ApplyOutlay,OutlayCategory,UseFor) VALUES ");
            sql.Append("(getdate(),@deptid" + i.ToString() + ",@deptname" + i.ToString() + ",@title,");
            sql.Append("'','0',@applyuser,@outlaymonth,@applyoutlay" + i.ToString() + ",");
            sql.Append("@outlaycategory,@usefor);");
        }
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras.ToArray());
        if (result > 0)
            Response.Write("{\"success\":true,\"msg\":\"批量申请提交成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }


    /// <summary>
    /// 更新申请报告
    /// </summary>
    public void UpdateAuditApplyOutlayDetail()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        int deptId = Convert.ToInt32(Request.Form["deptId"]);
        string deptName = Convert.ToString(Request.Form["deptName"]);
        string title = Convert.ToString(Request.Form["title"]);
        string content = Convert.ToString(Request.Form["editorValue"]);
        int outlayCategory = Convert.ToInt32(Request.Form["outlayCategory"]);
        decimal applyOutlay = Convert.ToDecimal(Request.Form["applyOutlay"]);
        string usefor = Convert.ToString(Request.Form["usefor"]);
        List<SqlParameter> paras = new List<SqlParameter>();
        paras.Add(new SqlParameter("@deptid", SqlDbType.Int));
        paras.Add(new SqlParameter("@deptname", SqlDbType.NVarChar));
        paras.Add(new SqlParameter("@title", SqlDbType.NVarChar));
        paras.Add(new SqlParameter("@content", SqlDbType.NVarChar));
        paras.Add(new SqlParameter("@outlaycategory", SqlDbType.Int));
        paras.Add(new SqlParameter("@applyoutlay", SqlDbType.Decimal));
        paras.Add(new SqlParameter("@usefor", SqlDbType.NVarChar));
        paras.Add(new SqlParameter("@outlaymonth", SqlDbType.NVarChar));
        paras.Add(new SqlParameter("@id", SqlDbType.Int));
        paras[0].Value = deptId;
        paras[1].Value = deptName;
        paras[2].Value = title;
        paras[3].Value = content;
        paras[4].Value = outlayCategory;
        paras[5].Value = applyOutlay;
        paras[6].Value = usefor;
        paras[7].Value = DateTime.Now.ToString("yyyy年MM月");
        paras[8].Value = id;
        StringBuilder sql = new StringBuilder();
        sql.Append("update  AuditApplyOutlayDetail set ApplyTime=getdate(),DeptId=@deptid,DeptName=@deptname,");
        sql.Append("ApplyTitle=@title,ApplyContent=@content,OutlayMonth=@outlaymonth,ApplyOutlay=@applyoutlay,");
        sql.Append("OutlayCategory=@outlaycategory,UseFor=@usefor  where id=@id;");
       
        //、获取附件信息
        //附件
        string filesNameStr = Convert.ToString(Request.Form["reportName"]);
        string filesPathStr = Convert.ToString(Request.Form["report"]);
        //获取附件名称
        if (!string.IsNullOrEmpty(filesNameStr))
        {
            string[] filesName = filesNameStr.Split(new String[] { "," }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < filesName.Length; i++)
            {
                paras.Add(new SqlParameter("@AttFileName" + i.ToString(), filesName[i]));

            }
        }//获取附件路径
        if (!string.IsNullOrEmpty(filesPathStr))
        {
            string[] filesPath = filesPathStr.Split(new String[] { "," }, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < filesPath.Length; i++)
            {
                paras.Add(new SqlParameter("@AttFilePath" + i.ToString(), filesPath[i]));
                sql.Append("Insert into AuditApplyOutlay_Attachment values(@id,@AttFileName" + i.ToString() + ",@AttFilePath" + i.ToString() + ");");
            }
        }
         //使用事务提交操作
        using (SqlConnection conn = SqlHelper.GetConnection())
        {
            conn.Open();
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    SqlHelper.ExecuteNonQuery(trans, CommandType.Text, sql.ToString(), paras.ToArray());
                    trans.Commit();
                    Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
                }
                catch
                {
                    trans.Rollback();
                    Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
                    throw;
                }
            }
        }
    }
    /// <summary>
    /// 送审经费申请到处长审批
    /// </summary>
    public void SendAuditApplyOutlay()
    {
        if (string.IsNullOrEmpty(Request.Form["id"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"请求参数无效！\"}");
            return;
        }
        int result = 0;
        //遍历请求ID
        string[] ids = Convert.ToString(Request.Form["id"]).Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        foreach (string id in ids)
        {
            SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
            paras.Value = id;
            string sql = "update AuditApplyOutlayDetail set status=1 WHERE id=@id";
            result += SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        }
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行失败\"}");
    }
    /// <summary>
    /// 通过id删除AuditApplyOutlayDetail 表申请记录
    /// </summary>
    public void RemoveAuditApplyOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM AuditApplyOutlayDetail WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 导出直接拨付经费明细——稽核
    /// </summary>
    public void ExportAuditApplyOutlayDetail()
    {
        ExportHasCreateAuditApplyOutlay();
    }
    #endregion
    #region 处长操作
    /// <summary>
    /// 退回追加经费申请到稽核
    /// </summary>
    public void BackAuditApplyOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update AuditApplyOutlayDetail set status=-1 WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过稽核申请的追加经费，并生成经费明细和汇总,自动生成经费额度编号，根据经费类别的不同生成公用或专项可用额度
    /// </summary>
    public void ApproveAuditApplyOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        //经费申请额度编号，自动生成格式为：2014001
        int applyOutlayNo;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select top 1  ApplyOutlayNo from autono");
        string currentNo = ds.Tables[0].Rows[0][0].ToString();
        if (currentNo.Substring(0, 4) == DateTime.Now.ToString("yyyy"))
            applyOutlayNo = int.Parse(currentNo) + 1;
        else
            applyOutlayNo = int.Parse(DateTime.Now.ToString("yyyy") + "001");

        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@applyoutlayno",SqlDbType.Int),
            new SqlParameter("@approver",SqlDbType.NVarChar)
        };
        paras[0].Value = id;
        paras[1].Value = applyOutlayNo;
        paras[2].Value = userName;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "ApproveAuditApplyOutlay", paras);
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");

    }

    /// <summary>
    /// 通过稽核申请的追加经费，并生成经费明细和汇总,自动生成经费额度编号，根据经费类别的不同生成公用或专项可用额度
    /// </summary>
    public void ApproveAllAuditApplyOutlay()
    {
        if (string.IsNullOrEmpty(Request.Form["id"]))
        {
            Response.Write("{\"success\":false,\"msg\":\"请求参数无效！\"}");
            return;
        }
        int result = 0;
        //遍历请求ID
        string[] ids = Convert.ToString(Request.Form["id"]).Split(new char[] { ',' });
        foreach (string id in ids)
        {
            //经费申请额度编号，自动生成格式为：2014001
            int applyOutlayNo;
            DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select top 1  ApplyOutlayNo from autono");
            string currentNo = ds.Tables[0].Rows[0][0].ToString();
            if (currentNo.Substring(0, 4) == DateTime.Now.ToString("yyyy"))
                applyOutlayNo = int.Parse(currentNo) + 1;
            else
                applyOutlayNo = int.Parse(DateTime.Now.ToString("yyyy") + "001");

            SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@applyoutlayno",SqlDbType.Int),
            new SqlParameter("@approver",SqlDbType.NVarChar)
        };
            paras[0].Value = id;
            paras[1].Value = applyOutlayNo;
            paras[2].Value = userName;
            result += SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "ApproveAuditApplyOutlay", paras);
        }
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行失败\"}");
    }
    /// <summary>
    /// 导出直接拨付经费明细——处长
    /// </summary>
    public void ExportApproveAuditApplyOutlayDetail()
    {
        ExportHasCreateAuditApplyOutlay();
    }
    #endregion
    #region 稽核经费追加申请图片
    /// <summary>
    /// 通过追加申请表ID :AAOID获取附件列表
    /// </summary>
    public void GetAttachmentByAAOID()
    {
        string id = Convert.ToString(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT * FROM AuditApplyOutlay_Attachment  where AuditApplyOutlayID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 通过id删除附件
    /// </summary>
    public void RemoveAttachmentByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM AuditApplyOutlay_Attachment WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
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