<%@ WebHandler Language="C#" Class="Portal" %>

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
/// portal各类用户获取代办事项操作
/// </summary>
public class Portal : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;

    /// <summary>
    /// 用户角色编号
    /// </summary>
    string roleid;
    /// <summary>
    /// 单位编号
    /// </summary>
    int deptid;
    /// <summary>
    /// 用户uid
    /// </summary>
    int uid;
    /// <summary>
    /// 非基层单位的负责单位
    /// </summary>
    string scopeDepts;
    /// <summary>
    /// 用户名
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
            deptid = ud.LoginUser.DeptId;
            uid = ud.LoginUser.UID;
            scopeDepts = ud.LoginUser.ScopeDepts;
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
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }
    #region 基层用户获取信息
    /// <summary>
    /// 获取经费额度信息
    /// </summary>
    public void BaseUser_GetOutlayInfo()
    {
        SqlParameter para = new SqlParameter("@deptid", SqlDbType.Int);
        para.Value = deptid;
        StringBuilder sql = new StringBuilder("select  top 10 * from (");
        //定额公用
        sql.Append("select * from ( select top 10 ");
        sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),audittime,23)))+'年'+");
        sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),audittime,23)))+'月'+");
        sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),audittime,23)))+'日'+");
        sql.Append("'下达'+convert(varchar(10),count(1))+'笔定额公用经费' as title,");
        sql.Append("convert(varchar(10),audittime,23) as thisdate from PublicOutlayDetail where deptid=@deptid and status=2 and datediff(dd,audittime,getdate())<=5 ");
        sql.Append(" group by convert(varchar(10),audittime,23) order by convert(varchar(10),audittime,23) desc) a union ");
        //申请追加
        sql.Append("select * from (select top 10 ");
        sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),audittime,23)))+'年'+");
        sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),audittime,23)))+'月'+");
        sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),audittime,23)))+'日'+");
        sql.Append("'下达'+convert(varchar(10),count(1))+'笔申请追加经费' as title,");
        sql.Append("convert(varchar(10),audittime,23) as thisdate from SpecialOutlayApplyDetail where deptid=@deptid and status=6 and datediff(dd,audittime,getdate())<=5 ");
        sql.Append("group by convert(varchar(10),audittime,23) order by  convert(varchar(10),audittime,23) desc) b  union ");
        //直接追加
        sql.Append("select * from (select top 10 ");
        sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),approvetime,23)))+'年'+");
        sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),approvetime,23)))+'月'+");
        sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),approvetime,23)))+'日'+");
        sql.Append("'下达'+convert(varchar(10),count(1))+'笔直接拨付经费' as title,");
        sql.Append("convert(varchar(10),approvetime,23) as thisdate from AuditApplyOutlayDetail where deptid=@deptid and status=2 and datediff(dd,approvetime,getdate())<=5 ");
        sql.Append("group by convert(varchar(10),approvetime,23) order by  convert(varchar(10),approvetime,23) desc ) c union ");
        //经费扣减
        sql.Append("select * from ( select top 10 ");
        sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),approvetime,23)))+'年'+");
        sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),approvetime,23)))+'月'+");
        sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),approvetime,23)))+'日'+");
        sql.Append("'扣减'+convert(varchar(10),count(1))+'笔经费' as title,");
        sql.Append("convert(varchar(10),approvetime,23) as thisdate from DeductOutlayDetail where deptid=@deptid and status=2 and datediff(dd,approvetime,getdate())<=5 ");
        sql.Append(" group by convert(varchar(10),approvetime,23) order by  convert(varchar(10),approvetime,23) desc ) d");
        //待取回现金支出额度
        sql.Append(" union ");
        sql.Append(" SELECT CASE WHEN outlayid=0 THEN '【公用经费】' when outlayid<>0 then '【专项经费】额度编号为'+convert(varchar(50),outlayID)+'；'  end + '办理编号为：'+ convert(varchar(50),reimburseno) +' 的现金支出，存在被退回的单笔额度，请及时取回' as title,convert(varchar(10),getdate(),23) as thisdate FROM (SELECT  deptid,rcp.ReimburseNo,rcp.OutlayID  FROM Reimburse_CashPayDetail  AS rcpd JOIN Reimburse_CashPay AS rcp ON rcp.ReimburseNo = rcpd.ReimburseNo WHERE  rcpd.STATUS=-1 and rcp.deptid=@deptid GROUP BY deptid,rcp.ReimburseNo,rcp.OutlayID ) AS back ");
        if (roleid == "1")//基层用户
        {
            //被退回的专项经费追加申请
            sql.Append(" union ");
            sql.Append("select * from (select top 10 ");
            sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),applytime,23)))+'年'+");
            sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),applytime,23)))+'月'+");
            sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),applytime,23)))+'日'+");
            sql.Append("'申请的追加经费被退回' as title,");
            sql.Append("convert(varchar(10),applytime,23) as thisdate from SpecialOutlayApplyDetail where deptid=@deptid and status=-1 and datediff(dd,applytime,getdate())<=5 ");
            sql.Append("group by convert(varchar(10),applytime,23) order by  convert(varchar(10),applytime,23) desc) bb   ");
            //被退回的项目申报表
            sql.Append(" union ");
            sql.Append("select * from (select top 10 ");
            sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),inputtime,23)))+'年'+");
            sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),inputtime,23)))+'月'+");
            sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),inputtime,23)))+'日'+");
            sql.Append("'申报的采购项目被退回' as title,");
            sql.Append("convert(varchar(10),inputtime,23) as thisdate from ProjectApplyInfo where deptid=@deptid and status=-1 and datediff(dd,inputtime,getdate())<=5 ");
            sql.Append("group by convert(varchar(10),inputtime,23) order by  convert(varchar(10),inputtime,23) desc) bdm  ");
        }
        if (roleid == "8") //部门负责人
        {
            //待审批的专项经费申请
            sql.Append(" union ");
            sql.Append("select * from (select top 10 ");
            sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),applytime,23)))+'年'+");
            sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),applytime,23)))+'月'+");
            sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),applytime,23)))+'日'+");
            sql.Append("ApplyUser+'申请的追加经费未审核，请处理' as title,");
            sql.Append("convert(varchar(10),applytime,23) as thisdate from SpecialOutlayApplyDetail where deptid=@deptid and status=1 ");
            sql.Append("group by convert(varchar(10),applytime,23),ApplyUser order by  convert(varchar(10),applytime,23) desc) dm  ");
            //待审核的项目申报表
            sql.Append(" union ");
            sql.Append("select * from (select top 10 ");
            sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),inputtime,23)))+'年'+");
            sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),inputtime,23)))+'月'+");
            sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),inputtime,23)))+'日'+");
            sql.Append("username+'申报的采购项目未审核，请处理' as title,");
            sql.Append("convert(varchar(10),inputtime,23) as thisdate from ProjectApplyInfo where deptid=@deptid and status=1 ");
            sql.Append("group by convert(varchar(10),inputtime,23),username order by  convert(varchar(10),inputtime,23) desc) dm  ");
        }
        if (roleid == "9") //部门主管领导
        {
            //待审批的专项经费申请
            sql.Append(" union ");
            sql.Append("select * from (select top 10 ");
            sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),applytime,23)))+'年'+");
            sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),applytime,23)))+'月'+");
            sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),applytime,23)))+'日'+");
            sql.Append("ApplyUser+'申请的追加经费未审核，请处理' as title,");
            sql.Append("convert(varchar(10),applytime,23) as thisdate from SpecialOutlayApplyDetail where deptid=@deptid and status=2 ");
            sql.Append("group by convert(varchar(10),applytime,23),ApplyUser order by  convert(varchar(10),applytime,23) desc) dm  ");
            //待审核的项目申报表
            sql.Append(" union ");
            sql.Append("select * from (select top 10 ");
            sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),inputtime,23)))+'年'+");
            sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),inputtime,23)))+'月'+");
            sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),inputtime,23)))+'日'+");
            sql.Append("username+'申报的采购项目未审核，请处理' as title,");
            sql.Append("convert(varchar(10),inputtime,23) as thisdate from ProjectApplyInfo where deptid=@deptid and status=2 ");
            sql.Append("group by convert(varchar(10),inputtime,23),username order by  convert(varchar(10),inputtime,23) desc) dm  ");
        }
        //审核通过的项目申报表
        sql.Append(" union ");
        sql.Append("select * from (select top 10 ");
        sql.Append(" convert(varchar(4),datepart(yyyy,convert(varchar(10),inputtime,23)))+'年'+");
        sql.Append(" convert(varchar(2),datepart(MM,convert(varchar(10),inputtime,23)))+'月'+");
        sql.Append(" convert(varchar(2),datepart(dd,convert(varchar(10),inputtime,23)))+'日'+");
        sql.Append("username+'申报的采购项目已通过审批' as title,");
        sql.Append("convert(varchar(10),inputtime,23) as thisdate from ProjectApplyInfo where deptid=@deptid and status=5 and datediff(dd,inputtime,getdate())<=5 ");
        sql.Append("group by convert(varchar(10),inputtime,23),username order by  convert(varchar(10),inputtime,23) desc) dm  ");

        //结尾
        sql.Append(" ) e order by e.thisdate desc ");

        //Response.Write(sql.ToString());
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), para);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 获取基层用户未读的报表和未读的已回复的意见
    /// </summary>
    public void BaseUser_GetUnReadReportAndNotice()
    {
        SqlParameter para = new SqlParameter("@deptid", SqlDbType.Int);
        para.Value = deptid;
        StringBuilder sql = new StringBuilder("select  * from (");
        //报表
        sql.Append("select convert(varchar(4),datepart(yyyy,PublishDate))+'年'+");
        sql.Append("convert(varchar(2),datepart(MM,PublishDate))+'月'+convert(varchar(2),datepart(dd,PublishDate))+'日'+");
        sql.Append("Publisher+'下发了标题为“'+ReportTitle+'”的报表，请查收' as title ,PublishDate from reportinfo ");
        sql.Append(" a join ReportReceiptInfo b on a.id=b.reportid and b.deptid=@deptid and a.status=1 and b.isread=0");
        sql.Append(" union ");
        //意见
        sql.Append("select '标题为“'+noticetitle+'”的意见已回复，请查看！' as title,PublishDate from ");
        sql.Append(" noticeinfo where deptid=@deptid and isreply=1 and IsPublisherReadReply=0 ");
        //结尾
        sql.Append(" ) a order by publishdate desc");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), para);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #endregion

    #region 稽核操作
    /// <summary>
    /// 稽核获取行财主管领导批转来的已审批的申请追加经费
    /// </summary>
    public void Auditor_GetUnAuditApproveOutlay()
    {
        string scopeWhere = "";
        if (scopeDepts != "0")
            scopeWhere = "and deptid in (" + scopeDepts + ")";
        StringBuilder sql = new StringBuilder();
        sql.Append("select  convert(varchar(4),datepart(yyyy,FinanceleadAudittime))+'年'+");
        sql.Append("convert(varchar(2),datepart(MM,FinanceleadAudittime))+'月'+convert(varchar(2),datepart(dd,FinanceleadAudittime))+'日'+");
        sql.Append("'行财主管领导批转'+deptname+'的追加经费申请,请处理' as title ");
        sql.Append(" from SpecialOutlayApplyDetail where status=5 " + scopeWhere);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 稽核或者统计员获取报送报表的回执信息和接收的意见信息
    /// </summary>
    public void Auditor_GetReportAndNotice()
    {
        SqlParameter para = new SqlParameter("@uname", SqlDbType.NVarChar);
        para.Value = userName;
        StringBuilder sql = new StringBuilder("select * from ( ");
        //报表信息   
        sql.Append("select  convert(varchar(4),datepart(yyyy,publishdate))+'年'+");
        sql.Append("convert(varchar(2),datepart(MM,publishdate))+'月'+convert(varchar(2),datepart(dd,publishdate))+'日'+");
        sql.Append("'报送的报表“'+reporttitle+'”，存在未回执的单位，请处理' as title ,publishdate from reportinfo");
        sql.Append(" where publisher=@uname and status=1 and dbo.F_CheckReportHasReceipted(id)=1 union ");
        sql.Append("select  convert(varchar(4),datepart(yyyy,publishdate))+'年'+");
        sql.Append("convert(varchar(2),datepart(MM,publishdate))+'月'+convert(varchar(2),datepart(dd,publishdate))+'日'+");
        sql.Append("deptname+'发来意见，请处理' as title,publishdate from noticeinfo a join department b ");
        sql.Append(" on a.deptid=b.deptid where isreceiverread =0 and receivername=@uname ");
        //结尾
        sql.Append(") a order by publishdate desc");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), para);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #endregion

    #region 处长,行财主管领导操作
    /// <summary>
    /// 处长获取未审批的各项经费
    /// </summary>
    public void Director_GetOutlayUnApprove()
    {
        string scopeWhere = "";
        if (scopeDepts != "0")
            scopeWhere = "and deptid in (" + scopeDepts + ")";
        StringBuilder sql = new StringBuilder("select * from ( ");
        if (roleid == "4")
        { //行财科长
          //定额公用经费
            sql.Append("select outlaymonth+'的定额公用经费未审批，请处理' as title,");
            sql.Append("audittime as thisdate from PublicOutlayDetail where status=1 " + scopeWhere + " union ");
            //申请追加
            sql.Append("select  convert(varchar(4),datepart(yyyy,applytime))+'年'+");
            sql.Append("convert(varchar(2),datepart(MM,applytime))+'月'+convert(varchar(2),datepart(dd,applytime))+'日'+");
            sql.Append("deptname+'申请的追加经费未审批，请处理' as title,applytime as thisdate");
            sql.Append(" from  SpecialOutlayApplyDetail where status=3 " + scopeWhere + " union ");
            //直接追加
            sql.Append("select  convert(varchar(4),datepart(yyyy,applytime))+'年'+");
            sql.Append("convert(varchar(2),datepart(MM,applytime))+'月'+convert(varchar(2),datepart(dd,applytime))+'日'+");
            sql.Append("applyuser+'申请的追加经费未审批，请处理' as title,applytime as thisdate ");
            sql.Append(" from  AuditApplyOutlayDetail where status=1 " + scopeWhere + " union ");
            //扣减经费
            sql.Append("select  convert(varchar(4),datepart(yyyy,deducttime))+'年'+");
            sql.Append("convert(varchar(2),datepart(MM,deducttime))+'月'+convert(varchar(2),datepart(dd,deducttime))+'日'+");
            sql.Append("applyuser+'申请的扣减经费未审批，请处理' as title,deducttime as thisdate ");
            sql.Append("from  DeductOutlayDetail where status=1 " + scopeWhere + " ");
            //采购项目申报表
            sql.Append("union select  convert(varchar(4),datepart(yyyy,inputtime))+'年'+");
            sql.Append("convert(varchar(2),datepart(MM,inputtime))+'月'+convert(varchar(2),datepart(dd,inputtime))+'日'+");
            sql.Append("deptname+'申报的采购项目未审批，请处理' as title,inputtime as thisdate");
            sql.Append(" from  ProjectApplyInfo where status=3 " + scopeWhere);
        }
        if (roleid == "10")//行财主管领导
        {
            //申请追加
            sql.Append("select  convert(varchar(4),datepart(yyyy,applytime))+'年'+");
            sql.Append("convert(varchar(2),datepart(MM,applytime))+'月'+convert(varchar(2),datepart(dd,applytime))+'日'+");
            sql.Append("deptname+'申请的追加经费未审批，请处理' as title,applytime as thisdate");
            sql.Append(" from  SpecialOutlayApplyDetail where status=4 " + scopeWhere + " union ");
            //采购项目申报表
            sql.Append("select  convert(varchar(4),datepart(yyyy,inputtime))+'年'+");
            sql.Append("convert(varchar(2),datepart(MM,inputtime))+'月'+convert(varchar(2),datepart(dd,inputtime))+'日'+");
            sql.Append("deptname+'申报的采购项目未审批，请处理' as title,inputtime as thisdate");
            sql.Append(" from  ProjectApplyInfo where status=4 " + scopeWhere);
        }
        //结尾
        sql.Append(") a order by thisdate desc");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 处长或出纳获取未读的意见
    /// </summary>
    public void Director_GetUnReadNotice()
    {
        SqlParameter para = new SqlParameter("@uname", SqlDbType.NVarChar);
        para.Value = userName;
        StringBuilder sql = new StringBuilder();
        sql.Append("select  convert(varchar(4),datepart(yyyy,publishdate))+'年'+");
        sql.Append("convert(varchar(2),datepart(MM,publishdate))+'月'+convert(varchar(2),datepart(dd,publishdate))+'日'+");
        sql.Append("deptname+'发来意见，请处理' as title from noticeinfo a join department b ");
        sql.Append(" on a.deptid=b.deptid where isreceiverread =0 and receiverName=@uname");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), para);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    #endregion

}