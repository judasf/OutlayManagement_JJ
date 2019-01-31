<%@ WebHandler Language="C#" Class="SpecialOutlayAllocate" %>

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
/// 经费追加处理
/// </summary>
public class SpecialOutlayAllocate : IHttpHandler, IRequiresSessionState
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
    /// 设置经费申请明细查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForApplyOutlayDetail()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按月份查询
        if (!string.IsNullOrEmpty(Request.Form["outlayMonth"]))
            list.Add(" outlayMonth ='" + Request.Form["outlayMonth"] + "'");
        else//默认只显示当年数据
            list.Add(" left(outlayMonth,4) = YEAR(GETDATE())");
        //按额度编号SpecialOutlayID
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" SpecialOutlayID like'%" + Request.Form["outlayid"] + "%'");
        //按单位名称
        //基层用户，部门负责人，部门主管领导只获取自己的信息
        if (roleid == "1" || roleid == "8" || roleid == "9")
            list.Add(" deptid= " + deptid);
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" deptid ='" + Request.Form["deptid"] + "'");
        }
        //按状态查询
        if (!string.IsNullOrEmpty(Request.Form["status"]) && Request.Form["status"] != "99") //99:全部状态
        {
            list.Add(" status =" + Request.Form["status"]);
        }
        //按经费类别
        if (!string.IsNullOrEmpty(Request.Form["outlaycategory"]))
            list.Add(" outlaycategory =" + Request.Form["outlaycategory"]);
        //-1：已退回，0:未送审，1：部门负责人审核中，2：部门主管领导审批中，3：行财部门审核中，4：行财主管领导审批中，5：审批通过费用生成中，6：费用已生成
        //基层用户显示全部信息但只能修改未送审(0)和被处长退回(-1)的信息；
        //部门负责人默认显示：1
        //部门主管领导默认显示：2
        //行财科长：3
        //行财主管领导：4
        //稽核默认显示：5;
        //管理员默认显示已生成(6)的信息可查询全部信息
        //if(string.IsNullOrEmpty(Request.Form["status"]) && roleid=="1")
        //    list.Add(" status<1 ");
        if (string.IsNullOrEmpty(Request.Form["status"]))
        {
            switch (roleid)
            {
                case "8"://部门负责人
                    list.Add(" status=1 ");
                    break;
                case "9"://部门主管领导
                    list.Add(" status=2 ");
                    break;
                case "4"://行财科长
                    list.Add(" status=3 ");
                    break;
                case "10"://财务主管领导
                    list.Add(" status=4 ");
                    break;
                case "2"://稽核员
                    list.Add(" status=5 ");
                    break;
                    //case "6"://管理员
                    //    list.Add(" status=6");
                    //    break;
            }

        }
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0" && (roleid!="1" && roleid!="8" && roleid!="9"))
            list.Add(" deptid in (" + scopeDepts + ") ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;

    }
    /// <summary>
    /// 获取专项经费追加申请明细SpecialOutlayApplyDetail 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetApplyOutlayDetail()
    {
        int total = 0;
        string where = SetQueryConditionForApplyOutlayDetail();
        string tableName = "SpecialOutlayApplyDetail left join category on outlaycategory=cid";
        string fieldStr = "SpecialOutlayApplyDetail.*,cname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        //Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "applyoutlay", "applytitle", "合计"));
    }
    /// <summary>
    ///  通过ID获取SpecialOutlayApplyDetail
    /// </summary>
    public void SpecialOutlayApplyDetailByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT a.*,b.cname FROM SpecialOutlayApplyDetail a left join category b on a.OutlayCategory=b.cid where  a.ID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #region 基层用户操作
    /// <summary>
    /// 保存SpecialOutlayApplyDetail 表申请
    /// </summary>
    public void SaveSpecialOutlayApplyDetail()
    {
        string linkman = Convert.ToString(Request.Form["linkman"]);
        string linkmantel = Convert.ToString(Request.Form["linkmantel"]);
        string applycontent = Convert.ToString(Request.Form["applycontent"]);
        decimal applyOutlay = Convert.ToDecimal(Request.Form["applyOutlay"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@deptid",SqlDbType.Int),
            new SqlParameter("@deptname",SqlDbType.NVarChar),
            new SqlParameter("@linkman",SqlDbType.NVarChar),
            new SqlParameter("@linkmantel",SqlDbType.NVarChar),
            new SqlParameter("@applycontent",SqlDbType.NVarChar),
            new SqlParameter("@applyuser",SqlDbType.NVarChar),
            new SqlParameter("@outlaymonth",SqlDbType.NVarChar),
            new SqlParameter("@applyOutlay",SqlDbType.Decimal)
        };
        paras[0].Value = deptid;
        paras[1].Value = deptName;
        paras[2].Value = linkman;
        paras[3].Value = linkmantel;
        paras[4].Value = applycontent;
        paras[5].Value = userName;
        paras[6].Value = DateTime.Now.ToString("yyyy年MM月");
        paras[7].Value = applyOutlay;
        string sql = "INSERT INTO SpecialOutlayApplyDetail(ApplyTime,DeptId,DeptName,linkman,linkmantel,ApplyContent,Status,ApplyUser,OutlayMonth,applyOutlay) VALUES(getdate(),@deptid,@deptname,@linkman,@linkmantel,@applycontent,'0',@applyuser,@outlaymonth,@applyOutlay)";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 更新申请报告
    /// </summary>
    public void UpdateSpecialOutlayApplyDetail()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        string linkman = Convert.ToString(Request.Form["linkman"]);
        string linkmantel = Convert.ToString(Request.Form["linkmantel"]);
        string applycontent = Convert.ToString(Request.Form["applycontent"]);
        decimal applyOutlay = Convert.ToDecimal(Request.Form["applyOutlay"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@linkman",SqlDbType.NVarChar),
            new SqlParameter("@linkmantel",SqlDbType.NVarChar),
            new SqlParameter("@applycontent",SqlDbType.NVarChar),
            new SqlParameter("@applyOutlay",SqlDbType.Decimal)
        };
        paras[0].Value = id;
        paras[1].Value = linkman;
        paras[2].Value = linkmantel;
        paras[3].Value = applycontent;
        paras[4].Value = applyOutlay;
        string sql = "update  SpecialOutlayApplyDetail set linkman=@linkman,linkmantel=@linkmantel,applycontent=@applycontent,applyOutlay=@applyOutlay where id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 送审经费申请
    /// </summary>
    public void SendApplyOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update SpecialOutlayApplyDetail set status=1,deptmanaaudit=null,deptmanaComment=null,deptmanaaudittime=null,deptleadaudit=null,deptleadComment=null,deptleadaudittime=null,FinancemanaAudit=null,FinancemanaComment=null,FinancemanaAudittime=null,FinanceleadAudit=null,FinanceleadComment=null,FinanceleadAudittime=null WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过id删除SpecialOutlayApplyDetail 表申请信息
    /// </summary>
    public void RemoveApplyOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "DELETE FROM SpecialOutlayApplyDetail WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 设置已生成的专项经费的查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForSpecialOutlay()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        ////按月份查询
        //if (!string.IsNullOrEmpty(Request.Form["outlayMonth"]))
        //    list.Add(" outlayMonth ='" + Request.Form["outlayMonth"] + "'");
        //else//默认只显示当年数据
        //    list.Add(" left(outlayMonth,4) = YEAR(GETDATE())");
        //按额度编号OutlayID
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" OutlayID like'%" + Request.Form["outlayid"] + "%'");
        //按单位名称
        //基层用户只获取自己的信息
        if (roleid == "1")
        {
            //按单位
            list.Add(" deptid= " + deptid);
            //专项经费支出报销页面中使用
            //按办理日期查询
            //开始日期
            if (!string.IsNullOrEmpty(Request.Form["sdate"]))
                list.Add(" convert(varchar(10),OutlayTime,120) >='" + Request.Form["sdate"] + "'");
            //截止日期
            if (!string.IsNullOrEmpty(Request.Form["edate"]))
                list.Add(" convert(varchar(10),OutlayTime,120) <='" + Request.Form["edate"] + "'");
            ////办理日期未选择，默认只显示当年数据
            //if (string.IsNullOrEmpty(Request.Form["sdate"]) && string.IsNullOrEmpty(Request.Form["edate"]))
            //    list.Add(" left(convert(varchar(10),OutlayTime,120),4) = YEAR(GETDATE())");
            //有可用额度
            if (!string.IsNullOrEmpty(Request.Form["unusedOutlay"]))
            {
                if (Request.Form["unusedOutlay"].ToString() == "1")
                    list.Add(" UnusedOutlay>0");
            }
            else
                list.Add(" UnusedOutlay>0");
        }
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" deptid ='" + Request.Form["deptid"] + "'");
        }
        //按经费类别
        if (!string.IsNullOrEmpty(Request.Form["outlaycategory"]))
            list.Add(" outlaycategory =" + Request.Form["outlaycategory"]);
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" deptid in (" + scopeDepts + ") ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取已生成的专项额度 SpecialOutlay
    /// </summary>
    public void GetSpecialOutlay()
    {
        int total = 0;
        string where = SetQueryConditionForSpecialOutlay();
        //Response.Write(SetQueryConditionForSpecialOutlay());
        string tableName = "SpecialOutlay left join category on outlaycategory=cid";
        string fieldStr = "SpecialOutlay.*,cname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "unusedoutlay,alloutlay", "outlaytime", "合计"));
    }
    /// <summary>
    /// 可用额度查询页面获取已生成的专项额度 SpecialOutlay
    /// </summary>
    public void GetUnUsedSpecialOutlay()
    {
        int total = 0;
        string outlaySch = "";
        //有可用额度
        if (!string.IsNullOrEmpty(Request.Form["unusedOutlay"]))
        {
            if (Request.Form["unusedOutlay"].ToString() == "1")
                outlaySch = " and UnusedOutlay<>0";
        }
        else
            outlaySch = " and UnusedOutlay<>0";
        string where = " deptid ='" + Convert.ToString(Request.Form["deptid"]) + "'" + outlaySch;
        string tableName = "SpecialOutlay left join category on outlaycategory=cid";
        string fieldStr = "SpecialOutlay.*,cname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "unusedoutlay,alloutlay", "outlaytime", "合计"));
    }
    /// <summary>
    /// 基层用户通过ID获取专项经费信息
    /// </summary>
    public void GetSpecialOutlayByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        string sql = "select a.*,b.cname,'" + userName + "' as username,'" + userName + "' as reimburseuser from SpecialOutlay a left join category b on a.outlaycategory=b.cid where a.id=@id";
        SqlParameter para = new SqlParameter("@id", SqlDbType.Int);
        para.Value = id;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, para);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 基层用户导出已生成的专项经费明细
    /// </summary>
    public void ExportSpecialOutlayDetail()
    {
        string where = SetQueryConditionForSpecialOutlay();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select outlayid,unusedoutlay,alloutlay,outlaytime,deptname,");
        sql.Append("cname,usefor,");
        sql.Append(" zjnd=case when datepart(yyyy,outlaytime)=datepart(yyyy,getdate()) then '当年下达' ");
        sql.Append("when datepart(yyyy,outlaytime)<datepart(yyyy,getdate()) then '上年结余' end ");
        sql.Append(" from SpecialOutlay  left join category  on outlaycategory=cid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "额度编号";
        dt.Columns[1].ColumnName = "可用额度";
        dt.Columns[2].ColumnName = "下达额度";
        dt.Columns[3].ColumnName = "下达额度时间";
        dt.Columns[4].ColumnName = "单位名称";
        dt.Columns[5].ColumnName = "经费类别";
        dt.Columns[6].ColumnName = "用途";
        dt.Columns[7].ColumnName = "资金年度";
        MyXls.CreateXls(dt, "专项经费明细.xls", "3,6");
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 基层用户导出申请追加经费明细
    /// </summary>
    public void ExportUserApplyOutlayDetail()
    {
        string where = SetQueryConditionForApplyOutlayDetail();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select outlaymonth,deptname,specialoutlayid,applytitle,applyoutlay,");
        sql.Append("cname,usefor,applyuser,applytime,");
        sql.Append(" status=case when status=-1 then '被退回' when status=0 then '待送审'  ");
        sql.Append("when status=1 then '待审批' when status=2 then '待审批' ");
        sql.Append("when status=3 then '待确认' when status=4 then '已生成'  end");
        sql.Append(" from SpecialOutlayApplyDetail left join category on outlaycategory=cid ");
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
        MyXls.CreateXls(dt, "申请追加经费明细.xls", "3,6,8");
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 专项经费合并操作
    /// <summary>
    /// 通过id将专项经费合并到公用
    /// </summary>
    public void MergeToPublicOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        StringBuilder sql = new StringBuilder();
        sql.Append("UPDATE  p set p.unusedoutlay=p.Unusedoutlay+s.Unusedoutlay,p.LastOutlayTime=GETDATE() FROM PublicOutlay AS p JOIN SpecialOutlay AS s ON p.DeptId=s.DeptId AND s.ID=@id;");
        sql.Append("INSERT INTO specialOutlayMergePublic  SELECT s.DeptId,s.OutlayId,s.UnusedOutlay,@username,GETDATE(),0    FROM PublicOutlay AS p JOIN SpecialOutlay AS s ON p.DeptId=s.DeptId AND s.ID=@id;");
        sql.Append("UPDATE SpecialOutlay SET UnusedOutlay = 0 WHERE id=@id;");
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@id", SqlDbType.Int),
            new SqlParameter("@username",SqlDbType.NVarChar)
        };
        paras[0].Value = id;
        paras[1].Value = userName;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result == 3)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过id撤销额度合并操作
    /// </summary>
    public void CancelMergePublic()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        StringBuilder sql = new StringBuilder();
        sql.Append("UPDATE  p set p.unusedoutlay=p.Unusedoutlay-s.SpecialOutlay,p.LastOutlayTime=GETDATE() FROM PublicOutlay AS p JOIN SpecialOutlayMergePublic AS s ON p.DeptId=s.DeptId AND s.ID=@id;");
        sql.Append("UPDATE  sp set sp.UnusedOutlay=sp.UnusedOutlay+spm.SpecialOutlay from  SpecialOutlay as sp join  SpecialOutlayMergePublic as spm on sp.DeptId=spm.DeptId and sp.OutlayId=spm.OutlayId and  spm.id=@id;");
        sql.Append("Update specialOutlayMergePublic set [status]=1 where id=@id; ");
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@id", SqlDbType.Int)
        };
        paras[0].Value = id;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (result == 3)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 设置专项经费合并明细的查询条件
    /// </summary>
    /// <returns>生成的where语句</returns>
    public string SetQueryConditionForSpecialOutlayMerge()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按额度编号OutlayID
        if (!string.IsNullOrEmpty(Request.Form["outlayid"]))
            list.Add(" OutlayID like'%" + Request.Form["outlayid"] + "%'");
        //按办理日期查询
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" convert(varchar(10),MergeTime,120) >='" + Request.Form["sdate"] + "'");
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" convert(varchar(10),MergeTime,120) <='" + Request.Form["edate"] + "'");
        //申请日期未选择，默认只显示当年数据
        if (string.IsNullOrEmpty(Request.Form["sdate"]) && string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" left(convert(varchar(10),MergeTime,120),4) = YEAR(GETDATE())");
        //按单位名称
        //基层用户只获取自己的信息
        if (roleid == "1")
        {
            //按单位
            list.Add(" d.deptid= " + deptid);

        }
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptid"]))
                list.Add(" d.deptid ='" + Request.Form["deptid"] + "'");
        }
        //根据非基层用户的管辖范围获取记录
        if (scopeDepts != "0")
            list.Add(" d.deptid in (" + scopeDepts + ") ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取专项经费追合并明细SpecialOutlayMergePublic 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetSpecialOutlayMergeDetail()
    {
        int total = 0;
        string where = SetQueryConditionForSpecialOutlayMerge();
        string tableName = "SpecialOutlayMergePublic   left join Department d on SpecialOutlayMergePublic.deptid=d.deptid";
        string fieldStr = "SpecialOutlayMergePublic.*,deptname";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
        //Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], total, true, "applyoutlay", "applytitle", "合计"));
    }
    /// <summary>
    /// 导出专项经费合并到公用明细
    /// </summary>
    public void ExportSpecialOutlayMergeDetail()
    {
        string where = SetQueryConditionForSpecialOutlayMerge();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("select deptname,outlayid,SpecialOutlay,UserName,MergeTime");
        sql.Append(" from dbo.SpecialOutlayMergePublic s left join Department d on s.deptid=d.deptid ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "单位名称";
        dt.Columns[1].ColumnName = "专项经费额度编号";
        dt.Columns[2].ColumnName = "合并额度";
        dt.Columns[3].ColumnName = "经办人";
        dt.Columns[4].ColumnName = "合并时间";
        MyXls.CreateXls(dt, "专项经费合并到公用明细.xls", "4");
        Response.Flush();
        Response.End();
    }
    #endregion 专项经费合并操作

    /// <summary>
    /// 追加经费申请逐级审批,8:部门负责人，9：部门主管领导，4：行财科长，10：财务主管领导,6：管理员
    /// </summary>
    public void ApproverApplyOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        decimal applyOutlay = Convert.ToDecimal(Request.Form["applyOutlay"]);
        string audit = Convert.ToString(Request.Form["audit"]);
        string comment = Convert.ToString(Request.Form["comment"]);
        //根据不同的审核权限roleid获取当前项目的下一进度
        string nextStatus;
        if (audit == "同意")
        {
            nextStatus = " status=status+1, ";
        }
        else
        {
            if (comment.Trim().Length == 0)
            {
                Response.Write("{\"success\":false,\"msg\":\"请填写具体意见！\"}");
                return;
            }
            else
                nextStatus = " status=-1,";
        }

        string updateFields = " applyOutlay=@applyOutlay,";
        //根据不同的权限设置要更新审核意见的字段
        switch (roleid)
        {
            case "8"://部门负责人
                updateFields += nextStatus + "deptmanaaudit=@audit,deptmanaComment=@comment,deptmanaaudittime=getdate() ";
                break;
            case "9"://部门主管领导
                updateFields += nextStatus + "deptleadaudit=@audit,deptleadComment=@comment,deptleadaudittime=getdate() ";
                break;
            case "4"://行财科长
                updateFields += nextStatus + "FinancemanaAudit=@audit,FinancemanaComment=@comment,FinancemanaAudittime=getdate() ";
                break;
            case "10"://行财主管领导
                updateFields += nextStatus + "FinanceleadAudit=@audit,FinanceleadComment=@comment,FinanceleadAudittime=getdate() ";
                break;
            case "6"://管理员，跳过当前审批状态
                updateFields = " status=status+1 ";
                break;
            default:
                updateFields = "";
                break;
        }
        string sql = "if exists(select * from SpecialOutlayApplyDetail where id=@id and status>0)";
        sql += "update SpecialOutlayApplyDetail set " + updateFields + " where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),
            new SqlParameter("@applyOutlay",applyOutlay),
            new SqlParameter("@audit",audit),
            new SqlParameter("@comment",comment)};
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    #region 处长操作
    /*
/// <summary>
/// 经费申请通过审批
/// </summary>
public void ApproverApplyOutlay()
{
    int id = Convert.ToInt32(Request.Form["id"]);
    decimal outlay = Convert.ToDecimal(Request.Form["applyOutlay"]);

    SqlParameter[] paras = new SqlParameter[] {
        new SqlParameter("@id",SqlDbType.Int),
        new SqlParameter("@outlay",SqlDbType.Decimal),
        new SqlParameter("@approver",SqlDbType.NVarChar)
    };
    paras[0].Value = id;
    paras[1].Value = outlay;
    paras[2].Value = userName;
    string sql = "if not exists(select * from SpecialOutlayApplyDetail where id=@id and status>2) ";
    sql += "update  SpecialOutlayApplyDetail set status=3,applyoutlay=@outlay,approver=@approver,approvetime=getdate() where id=@id";
    int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
    if (result == 1)
        Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
    else
        Response.Write("{\"success\":false,\"msg\":\"该申请已通过审批，不要重复操作！\"}");
}
/// <summary>
/// 退回追加经费申请到基层用户
/// </summary>
public void BackApplyOutlay()
{
    int id = 0;
    int.TryParse(Request.Form["id"], out id);
    SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
    paras.Value = id;
    string sql = "update SpecialOutlayApplyDetail set status=-1 WHERE id=@id";
    int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
    if (result == 1)
        Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
    else
        Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
}
    */
    /// <summary>
    /// 导出申请追加经费明细——处长
    /// </summary>
    public void ExportApproveApplyOutlayDetail()
    {
        ExportUserApplyOutlayDetail();
    }
    #endregion
    #region 稽核员操作
    /// <summary>
    /// 确认经费申请审批并生成经费明细和汇总,自动生成经费额度编号
    /// </summary>
    public void AuditApproveOutlay()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        int catid = 0;
        int.TryParse(Request.Form["outlayCategory"], out catid);
        //经费申请额度编号，自动生成格式为：2014001
        int applyOutlayNo;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select top 1  ApplyOutlayNo from autono");
        string currentNo = ds.Tables[0].Rows[0][0].ToString();
        if (currentNo.Substring(0, 4) == DateTime.Now.ToString("yyyy"))
            applyOutlayNo = int.Parse(currentNo) + 1;
        else
            applyOutlayNo = int.Parse(DateTime.Now.ToString("yyyy") + "001");


        //string outlayId = Convert.ToString(Request.Form["outlayId"]);
        string usefor = Convert.ToString(Request.Form["usefor"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",SqlDbType.Int),
            new SqlParameter("@outlaycategory",SqlDbType.Int),
            new SqlParameter("@usefor",SqlDbType.NVarChar),
            new SqlParameter("@applyoutlayno",SqlDbType.Int),
            new SqlParameter("@auditor",SqlDbType.NVarChar)
        };
        paras[0].Value = id;
        paras[1].Value = catid;
        paras[2].Value = usefor;
        paras[3].Value = applyOutlayNo;
        paras[4].Value = userName;
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "AuditAppentOutlayApply", paras);
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");

    }
    /// <summary>
    /// 退回经费审批到处长
    /// </summary>
    public void BackApprover()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "update SpecialOutlayApplyDetail set status=2 WHERE id=@id";
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 导出申请追加经费明细——稽核
    /// </summary>
    public void ExportAuditApproveOutlayDetail()
    {
        ExportUserApplyOutlayDetail();
    }
    #endregion
    #region 管理员操作
    /// <summary>
    /// 管理员将已生成的基层用户申请追加经费退回到处长重新审批，操作数据表SpecialOutlayApplyDetail
    /// 1、根据经费类别，判断是公用经费还是专项经费，公用经费根据deptid判断经费是否满足扣减，专项经费根据deptid和额度编号outlayid在表SpecialOutlay中判断unusedoutlay是否满足扣减
    /// 2、初始化处长和稽核确认的信息
    /// </summary>
    public void BackHasCreateAppendOutlayToApprove()
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
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "BackHasCreateAppendOutlayApplyToApprove", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该项申请已退回处长审批！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该单位公用经费的可用额度不足，不能退回处长审批！\"}");
        if (result == -2)
            Response.Write("{\"success\":false,\"msg\":\"该专项经费额度已支出，不能退回处长审批！\"}");
        if (result == 0)
            Response.Write("{\"success\":false,\"msg\":\"执行出错，申请不存在\"}");
    }
    /// <summary>
    /// 管理员将已生成的稽核直接追加经费退回到处长重新审批，操作数据表AuditApplyOutlayDetail
    /// 1、根据经费类别，判断是公用经费还是专项经费，公用经费根据deptid判断经费是否满足扣减，专项经费根据deptid和额度编号outlayid在表SpecialOutlay中判断unusedoutlay是否满足扣减
    /// 2、初始化处长和稽核确认的信息
    /// </summary>
    public void BackHasCreateAuditApplyOutlayToApprove()
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
        SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.StoredProcedure, "BackHasCreateAuditApplyOutlayToApprove", paras);
        result = (int)paras[1].Value;
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功,该项申请已退回处长审批！\"}");
        if (result == -1)
            Response.Write("{\"success\":false,\"msg\":\"该单位公用经费的可用额度不足，不能退回处长审批！\"}");
        if (result == -2)
            Response.Write("{\"success\":false,\"msg\":\"该专项经费额度已支出，不能退回处长审批！\"}");
        if (result == 0)
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