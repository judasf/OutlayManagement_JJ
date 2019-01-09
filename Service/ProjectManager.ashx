<%@ WebHandler Language="C#" Class="ProjectManager" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections;
using System.Collections.Generic;
using Aspose.Words;
using Aspose.Words.Saving;
/// <summary>
/// 项目申报管理
/// </summary>
public class ProjectManager : IHttpHandler, IRequiresSessionState
{
    HttpRequest Request;
    HttpResponse Response;
    HttpSessionState Session;
    HttpServerUtility Server;
    HttpCookie Cookie;
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
    /// <summary>
    /// 用户角色id
    /// </summary>
    int roleid;
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
            deptid = ud.LoginUser.DeptId.ToString();
            deptName = ud.LoginUser.UserDept;
            userName = ud.LoginUser.UserName;
            roleid = ud.LoginUser.RoleId;
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
    /// <summary>
    /// 设置查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForNews()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按提交日期查询
        //提交开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" convert(varchar(50),inputtime,23) >='" + Request.Form["sdate"] + "'");
        //提交截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" convert(varchar(50),inputtime,23) <='" + Request.Form["edate"] + "'");
        //按项目申请编号
        if (!string.IsNullOrEmpty(Request.Form["pjno"]))
            list.Add(" pjno like'%" + Request.Form["pjno"] + "%'");
        //按申请单位
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            list.Add(" deptid  =" + Request.Form["deptId"]);
        //按项目状态：项目审批状态：-1：被退回；0：待送审（发起态）；1：待部门负责人审核；2：待部门主管领导审核；3：待行财部门审核；4：待行财主管领导审核；5：审批完结
        if (!string.IsNullOrEmpty(Request.Form["status"]))
            list.Add(" status =" + Request.Form["status"].ToString());
        //---接收菜单提交的项目状态-------//
        if (!string.IsNullOrEmpty(Request.QueryString["currentStatus"]))
            list.Add(" status =" + Request.QueryString["currentStatus"].ToString());
        //单位用户、部门负责人、部门主管领导只获取自己的信息
        if (roleid == 1 || roleid == 8 || roleid == 9)
            list.Add(" deptname= '" + deptName + "'");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取申请项目明细ProjectApplyInfo 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetProjectInfo()
    {
        int total = 0;
        string where = SetQueryConditionForNews();
        string tableName = " ProjectApplyInfo ";
        string fieldStr = "*,convert(varchar(50),inputtime,120) as applytime";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    ///  通过ID获取ProjectApplyInfo
    /// </summary>
    public void GetProjectApplyInfoById()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        StringBuilder sql = new StringBuilder();
        //string sql = "SELECT *,convert(varchar(50),inputtime,120) as applytime FROM ProjectApplyInfo where ID=@id";
        sql.Append("SELECT id,pjno,deptname,linkman,linkmantel,projectcontent,CONVERT(VARCHAR(50),inputtime,120) as applytime,");
        sql.Append("deptmananame,(CASE  WHEN deptmanacomment IS NULL THEN deptmanaaudit ELSE deptmanaaudit+'，'+deptmanacomment end) as dm, CONVERT(VARCHAR(50),deptmanaaudittime,120)  as dmtime,");
        sql.Append("deptleadname,(CASE  WHEN deptleadcomment IS NULL THEN deptleadaudit ELSE deptleadaudit+'，'+deptleadcomment end) as dl,CONVERT(VARCHAR(50),deptleadaudittime,120) as dltime,");
        sql.Append("financemananame,(CASE  WHEN financemanacomment IS NULL THEN financemanaaudit ELSE financemanaaudit+'，'+financemanacomment end) as fm,CONVERT(VARCHAR(50),financemanaaudittime,120) as fmtime,");
        sql.Append("financeleadname,(CASE  WHEN financeleadcomment IS NULL THEN financeleadaudit ELSE financeleadaudit+'，'+financeleadcomment end) as fl,CONVERT(VARCHAR(50),financeleadaudittime,120) as fltime ");
        sql.Append(" FROM ProjectApplyInfo WHERE id=@id");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    ///  通过ID获取审批页面项目申请信息详情ProjectApplyInfo
    /// </summary>
    public void GetProjectApplyDetailById()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        string sql = "SELECT *,convert(varchar(50),inputtime,120) as applytime FROM ProjectApplyInfo where ID=@id";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 通过项目编号pjno获取采购项目列表
    /// </summary>
    public void GetItemListByNoForList()
    {
        int pjno = 0;
        int.TryParse(Request.Form["no"], out pjno);
        SqlParameter paras = new SqlParameter("@pjno", SqlDbType.VarChar);
        paras.Value = pjno;
        string sql = "SELECT * FROM ProjectAdditional  where pjno=@pjno";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// 获取项目上报流水号即项目编号,判断编号前6为是否为当年当月，如果是则追加1，不是设置为001
    /// </summary>
    /// <returns></returns>
    public int GetProjectNo()
    {
        int ProjectNo;
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "select top 1  ProjectNo from autono");
        string currentNo = ds.Tables[0].Rows[0][0].ToString();
        if (currentNo.Substring(0, 6) == DateTime.Now.ToString("yyyyMM"))
            ProjectNo = int.Parse(currentNo) + 1;
        else
            ProjectNo = int.Parse(DateTime.Now.ToString("yyyyMM") + "001");
        return ProjectNo;
    }
    /// <summary>
    /// 保存项目申请信息
    /// </summary>
    public void SaveProjectApplyInfo()
    {
        //1、获取项目编号
        int ProjectNo = GetProjectNo();
        StringBuilder sql = new StringBuilder();
        //更新项目编号
        sql.Append("update autono set ProjectNo=@pjno;");
        //2、获取参数
        string deptname = Convert.ToString(Request.Form["deptname"]);
        string linkman = Convert.ToString(Request.Form["linkman"]);
        string linkmantel = Convert.ToString(Request.Form["linkmantel"]);
        string projectcontent = Convert.ToString(Request.Form["projectcontent"]);
        //生成参数
        List<SqlParameter> paras = new List<SqlParameter>();
        paras.Add(new SqlParameter("@pjno", ProjectNo));
        paras.Add(new SqlParameter("@deptid", deptid));
        paras.Add(new SqlParameter("@deptname", deptName));
        paras.Add(new SqlParameter("@linkman", linkman));
        paras.Add(new SqlParameter("@linkmantel", linkmantel));
        paras.Add(new SqlParameter("@projectcontent", projectcontent));
        paras.Add(new SqlParameter("@username", userName));
        //3、获取采购项目数据行数
        int rowsCount = 0;
        Int32.TryParse(Request.Form["rowsCount"], out rowsCount);
        if (rowsCount == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"请添加采购项目信息\"}");
            return;
        }
        ///获取提交采购项目信息并根据数据行数生成sql语句和参数列表
        for (int i = 1; i <= rowsCount; i++)
        {
            paras.Add(new SqlParameter("@purchasename" + i.ToString(), Request.Form["purchasename" + i.ToString()]));
            paras.Add(new SqlParameter("@units" + i.ToString(), Request.Form["units" + i.ToString()]));
            paras.Add(new SqlParameter("@number" + i.ToString(), Request.Form["number" + i.ToString()]));
            paras.Add(new SqlParameter("@price" + i.ToString(), Request.Form["price" + i.ToString()]));
            paras.Add(new SqlParameter("@budgetamount" + i.ToString(), Request.Form["budgetamount" + i.ToString()]));
            paras.Add(new SqlParameter("@techrequirement" + i.ToString(), Request.Form["techrequirement" + i.ToString()]));

            sql.Append(" INSERT INTO ProjectAdditional	VALUES(	@pjno,@purchasename" + i.ToString() + ",@units" + i.ToString() + ",@number" + i.ToString() + ",@price" + i.ToString() + ",@budgetamount" + i.ToString() + ",@techrequirement" + i.ToString() + "); ");
        }
        //6、保存项目信息
        sql.Append("insert ProjectApplyInfo(pjno,deptid,deptname,linkman,linkmantel,projectcontent,status,username,inputtime) values(@pjno,@deptid,@deptname,@linkman,@linkmantel,@projectcontent,1,@username,getdate());");

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
    /// 更新项目基础信息
    /// </summary>
    public void UpdateProjectApplyInfo()
    {
        //获取编号
        int id = Convert.ToInt32(Request.Form["id"]);
        //2、获取参数
        string pjno = Convert.ToString(Request.Form["pjno"]);
        string deptname = Convert.ToString(Request.Form["deptname"]);
        string linkman = Convert.ToString(Request.Form["linkman"]);
        string linkmantel = Convert.ToString(Request.Form["linkmantel"]);
        string projectcontent = Convert.ToString(Request.Form["projectcontent"]);
        StringBuilder sql = new StringBuilder();
        //生成参数
        List<SqlParameter> paras = new List<SqlParameter>();
        paras.Add(new SqlParameter("@id", id));
        paras.Add(new SqlParameter("@pjno", pjno));
        paras.Add(new SqlParameter("@deptid", deptid));
        paras.Add(new SqlParameter("@deptname", deptName));
        paras.Add(new SqlParameter("@linkman", linkman));
        paras.Add(new SqlParameter("@linkmantel", linkmantel));
        paras.Add(new SqlParameter("@projectcontent", projectcontent));
        paras.Add(new SqlParameter("@username", userName));
        //3、获取采购项目数据行数
        int rowsCount = 0;
        Int32.TryParse(Request.Form["rowsCount"], out rowsCount);
        if (rowsCount == 0)
        {
            Response.Write("{\"success\":false,\"msg\":\"请添加采购项目信息\"}");
            return;
        }
        //删除该项目下旧的采购项目数据
        sql.Append("DELETE FROM ProjectAdditional where pjno=@pjno;");
        ///获取提交采购项目信息并根据数据行数生成sql语句和参数列表
        for (int i = 1; i <= rowsCount; i++)
        {
            paras.Add(new SqlParameter("@purchasename" + i.ToString(), Request.Form["purchasename" + i.ToString()]));
            paras.Add(new SqlParameter("@units" + i.ToString(), Request.Form["units" + i.ToString()]));
            paras.Add(new SqlParameter("@number" + i.ToString(), Request.Form["number" + i.ToString()]));
            paras.Add(new SqlParameter("@price" + i.ToString(), Request.Form["price" + i.ToString()]));
            paras.Add(new SqlParameter("@budgetamount" + i.ToString(), Request.Form["budgetamount" + i.ToString()]));
            paras.Add(new SqlParameter("@techrequirement" + i.ToString(), Request.Form["techrequirement" + i.ToString()]));

            sql.Append(" INSERT INTO ProjectAdditional	VALUES(	@pjno,@purchasename" + i.ToString() + ",@units" + i.ToString() + ",@number" + i.ToString() + ",@price" + i.ToString() + ",@budgetamount" + i.ToString() + ",@techrequirement" + i.ToString() + "); ");
        }
        //6、更新信息
        sql.Append("update ProjectApplyInfo set linkman=@linkman,linkmantel=@linkmantel,projectcontent=@projectcontent,username=@username,inputtime=getdate() where id=@id;");

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
    /// 项目审批
    /// </summary>
    public void AuditProjectInfo()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
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

        string updateFields = "";
        //根据不同的权限设置要更新审核意见的字段
        switch (roleid)
        {
            case 8://部门负责人
                updateFields = nextStatus + "deptmananame=@audituser,deptmanaaudit=@audit,deptmanaComment=@comment,deptmanaaudittime=getdate() ";
                break;
            case 9://部门主管领导
                updateFields = nextStatus + "deptleadname=@audituser,deptleadaudit=@audit,deptleadComment=@comment,deptleadaudittime=getdate() ";
                break;
            case 4://行财科长
                updateFields = nextStatus + "financemananame=@audituser,FinancemanaAudit=@audit,FinancemanaComment=@comment,FinancemanaAudittime=getdate() ";
                break;
            case 10://财务主管领导
                updateFields = nextStatus + "financeleadname=@audituser,FinanceleadAudit=@audit,FinanceleadComment=@comment,FinanceleadAudittime=getdate() ";
                break;
            case 6://管理员，跳过当前审批状态
                updateFields = " status=status+1 ";
                break;
            default:
                updateFields = "";
                break;
        }
        string sql = "update ProjectApplyInfo set " + updateFields + " where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),new SqlParameter("@audituser",userName),new SqlParameter("@audit",audit),new SqlParameter("@comment",comment)};
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 通过项目编号PjNo获取附件列表
    /// </summary>
    public void GetAttachmentByPjNo()
    {
        string pjno = Convert.ToString(Request.Form["pjno"]);
        SqlParameter paras = new SqlParameter("@pjno", SqlDbType.Int);
        paras.Value = pjno;
        string sql = "SELECT * FROM Attachment  where pjno=@pjno";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 删除申请项目信息；1、项目基础信息；2、上传的附件
    /// </summary>
    public void DelProjectInfoByPjNo()
    {
        string pjno = Convert.ToString(Request.Form["pjno"]);
        SqlParameter paras = new SqlParameter("@pjno", SqlDbType.VarChar);
        paras.Value = pjno;
        StringBuilder sql = new StringBuilder();
        sql.Append("DELETE FROM ProjectApplyInfo WHERE pjno=@pjno;");
        sql.Append("DELETE FROM ProjectAdditional WHERE pjno=@pjno;");
        //使用事务提交操作
        using (SqlConnection conn = SqlHelper.GetConnection())
        {
            conn.Open();
            using (SqlTransaction trans = conn.BeginTransaction())
            {
                try
                {
                    SqlHelper.ExecuteNonQuery(trans, CommandType.Text, sql.ToString(), paras);
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
    /// 更新项目时间
    /// </summary>
    public void EditProjectInfoTimeByID()
    {
        int id = 0;
        int.TryParse(Request.Form["id"], out id);
        string inputtime = Convert.ToString(Request.Form["inputtime"]);
        string dmtime = Convert.ToString(Request.Form["dmtime"]);
        string dltime = Convert.ToString(Request.Form["dltime"]);
        string fmtime = Convert.ToString(Request.Form["fmtime"]);
        string fltime = Convert.ToString(Request.Form["fltime"]);
        string updateFields = "inputtime=@inputtime,deptmanaaudittime=@dmtime,deptleadaudittime=@dltime,FinancemanaAudittime=@fmtime,FinanceleadAudittime=@fltime "; ;
        string sql = "update ProjectApplyInfo set " + updateFields + " where id=@id";
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@id",id),new SqlParameter("@inputtime",inputtime),new SqlParameter("@dmtime",dmtime),new SqlParameter("@dltime",dltime),new SqlParameter("@fmtime",fmtime),new SqlParameter("@fltime",fltime)};
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"执行成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    #region 生成word文档
    /// <summary>
    /// 导出已归档申请到word
    /// </summary>
    public void ExportWordByID()
    {
        int id = Convert.ToInt32(Request.Form["id"]);
        SqlParameter paras = new SqlParameter("@id", SqlDbType.Int);
        paras.Value = id;
        StringBuilder sql = new StringBuilder();
        string path = Server.MapPath("../ProjectManager/TPL/"); //目录地址
        string templatePath = path + "Template.doc";  //自己做好的word
        string FileName = "安阳市交警支队自行采购项目申报表.pdf";
        sql.Append("SELECT pjno,deptname,linkman,linkmantel,projectcontent,CONVERT(VARCHAR(50),inputtime,23) as applytime,");
        sql.Append("(CASE  WHEN deptmanacomment IS NULL THEN deptmanaaudit ELSE deptmanaaudit+'，'+deptmanacomment end) as dm, CONVERT(VARCHAR(50),deptmanaaudittime,120)  as dmtime,");
        sql.Append("(CASE  WHEN deptleadcomment IS NULL THEN deptleadaudit ELSE deptleadaudit+'，'+deptleadcomment end) as dl,CONVERT(VARCHAR(50),deptleadaudittime,120) as dltime,");
        sql.Append("(CASE  WHEN financemanacomment IS NULL THEN financemanaaudit ELSE financemanaaudit+'，'+financemanacomment end) as fm,CONVERT(VARCHAR(50),financemanaaudittime,120) as fmtime,");
        sql.Append("(CASE  WHEN financeleadcomment IS NULL THEN financeleadaudit ELSE financeleadaudit+'，'+financeleadcomment end) as fl,CONVERT(VARCHAR(50),financeleadaudittime,120) as fltime ");
        sql.Append(" FROM ProjectApplyInfo WHERE id=@id");
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        if (ds.Tables[0].Rows.Count == 1)
        {
            try
            {

                Aspose.Words.Document doc = new Aspose.Words.Document(templatePath);
                Aspose.Words.DocumentBuilder builder = new Aspose.Words.DocumentBuilder(doc);
                DataRow dr = ds.Tables[0].Rows[0];
                //遍历数据，替换模板中标签
                foreach (DataColumn dc in ds.Tables[0].Columns)
                {

                    if (dc.ColumnName == "applytime")
                    {
                        string[] date = dr["applytime"].ToString().Split(new char[] { '-' });
                        string formatDate = date[0] + "年" + date[1] + "月" + date[2] + "日";
                        if (doc.Range.Bookmarks["applytime"] != null)
                        {
                            doc.Range.Bookmarks["applytime"].Text = formatDate;
                        }
                    }
                    else
                    {//替换word中指定书签的位置
                        if (doc.Range.Bookmarks[dc.ColumnName] != null)
                        {
                            doc.Range.Bookmarks[dc.ColumnName].Text = dr[dc.ColumnName].ToString();
                        }
                    }
                }
                Aspose.Words.NodeCollection allTables = doc.GetChildNodes(Aspose.Words.NodeType.Table, true); //获取word中所有表格table
                Aspose.Words.Tables.Table table1 = allTables[1] as Aspose.Words.Tables.Table;//拿到第2个表格,需要判断是第几个表格
                Aspose.Words.Tables.Row roww1 = table1.Rows[3]; //获取第3行
                DataSet ds2 = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, "Select purchasename,units,number,price,budgetamount,techrequirement from ProjectAdditional a join ProjectApplyInfo b on a.pjno=b.pjno where b.id=@id", paras);
                DataTable dt2 = ds2.Tables[0];

                for (int i = 0; i < dt2.Rows.Count - 1; i++)    //dt2为数据源  datatable
                {

                    Aspose.Words.Node row1 = roww1.Clone(true);//复制第3行,从第0行开始，数到需要填充数据的行，
                    table1.Rows.Insert(3 + i, row1);//将复制的行插入当前行的上方

                    builder.MoveToCell(1, 3 + i, 1, 0); //移动到第一个表格的第3第2个格子
                    builder.Write((i + 1).ToString()); //单元格填充文字


                    builder.MoveToCell(1, 3 + i, 2, 0); //移动到第一个表格的第3行第3个格子
                    builder.Write(dt2.Rows[i][0].ToString()); //单元格填充文字

                    builder.MoveToCell(1, 3 + i, 3, 0); //移动到第一个表格的第3行第4个格子
                    builder.Write(dt2.Rows[i][1].ToString()); //单元格填充文字

                    builder.MoveToCell(1, 3 + i, 4, 0); //移动到第一个表格的第3行第5个格子
                    builder.Write(dt2.Rows[i][2].ToString()); //单元格填充文字

                    builder.MoveToCell(1, 3 + i, 5, 0); //移动到第一个表格的第3行第6个格子
                    builder.Write(dt2.Rows[i][3].ToString()); //单元格填充文字

                    builder.MoveToCell(1, 3 + i, 6, 0); //移动到第一个表格的第3行第7个格子
                    builder.Write(dt2.Rows[i][4].ToString()); //单元格填充文字

                    builder.MoveToCell(1, 3 + i, 7, 0); //移动到第一个表格的第3行第8个格子
                    builder.Write(dt2.Rows[i][5].ToString()); //单元格填充文字
                }
                table1.Rows.RemoveAt(3 + dt2.Rows.Count - 1); //移除模板需要填数据的空行

                doc.Save(System.Web.HttpContext.Current.Response, FileName, ContentDisposition.Attachment, SaveOptions.CreateSaveOptions(SaveFormat.Pdf));
            }
            catch (Exception ex)
            {
            }
        }
    }
    #endregion
    /// <summary>
    /// 导出费用申请明细
    /// </summary>
    public void ExportCostsInfo()
    {
        string where = SetQueryConditionForNews();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append("SELECT pjname,");
        sql.Append("CASE PjStatus WHEN -1 THEN '已退回' when 0 then '办事处审核中' when 1  then '维护中心审核中'  WHEN 2 THEN '建维部经理审批中' when 3 then '财务审核中'  when 4 then '副总经理审批中'  when 5 then '总经理审批中'  when 6 then '待验收项目' when 7 then '待归档申请' when 8 then '已归档' end as pjstatus,");
        sql.Append("stationname,stationno,dwunit,townagency,applytime,budgetamount,MaintenanceContent,feelist,");
        sql.Append("(CASE  WHEN AgencyComment IS NULL THEN AgencyAudit ELSE AgencyAudit+'，'+AgencyComment end) as ag,");
        sql.Append("(CASE  WHEN MaintenanceCenterComment IS NULL THEN MaintenanceCenterAudit ELSE MaintenanceCenterAudit+'，'+MaintenanceCenterComment end) as mc,");
        sql.Append("(CASE  WHEN BuildingGMComment IS NULL THEN BuildingGMAudit ELSE BuildingGMAudit+'，'+BuildingGMComment end) as bgm,");
        sql.Append("(CASE  WHEN FinanceComment IS NULL THEN FinanceAudit ELSE FinanceAudit+'，'+FinanceComment end) as finance,");
        sql.Append("(CASE  WHEN DeputyGMComment IS NULL THEN DeputyGMAudit ELSE DeputyGMAudit+'，'+DeputyGMComment end) as dgm,");
        sql.Append("(CASE  WHEN GMComment IS NULL THEN GMAudit ELSE GMAudit+'，'+GMComment end) as gm,");
        sql.Append("Acceptance FROM ProjectApplyInfo AS c LEFT JOIN  ");
        sql.Append(" (SELECT pjno,(SELECT SingleClass+'('+convert(varchar(20),SingleFee) +') 元   ' FROM SingleFeeDetail  WHERE pjno=A.pjno FOR XML PATH('')) AS feelist FROM SingleFeeDetail A  GROUP BY pjno ) ");
        sql.Append(" AS b ON c.pjno=b.pjno ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "项目名称";
        dt.Columns[1].ColumnName = "项目进度";
        dt.Columns[2].ColumnName = "基站名称";
        dt.Columns[3].ColumnName = "基站编号";
        dt.Columns[4].ColumnName = "代维单位";
        dt.Columns[5].ColumnName = "铁塔县办事处";
        dt.Columns[6].ColumnName = "申请时间";
        dt.Columns[7].ColumnName = "预算金额";
        dt.Columns[8].ColumnName = "维修事项";
        dt.Columns[9].ColumnName = "维修单项";
        dt.Columns[10].ColumnName = "办事处意见";
        dt.Columns[11].ColumnName = "维护中心意见";
        dt.Columns[12].ColumnName = "建维部经理审批";
        dt.Columns[13].ColumnName = "财务审核";
        dt.Columns[14].ColumnName = "副总经理审批";
        dt.Columns[15].ColumnName = "总经理审批";
        dt.Columns[16].ColumnName = "验收情况";
        //ExcelHelper.ExportByWeb(dt, "", "安阳铁塔维护费用明细.xls", "Sheet1");
    }

    #region 显示统计信息明细
    /// <summary>
    /// 获取按办事处统计申请审批项目明细ProjectApplyInfo 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetAgStatisticsList()
    {
        int total = 0;
        string where = SetQueryConditionForNews();
        string tableName = " SingleFeeDetail AS s  JOIN ProjectApplyInfo  ON s.Pjno=ProjectApplyInfo.Pjno AND PjStatus>-1 ";
        string fieldStr = "ProjectApplyInfo.*";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 获取按代维单位统计申请审批项目明细ProjectApplyInfo 数据page:1 rows:10 sort:id order:asc
    /// </summary>
    public void GetDWStatisticsList()
    {
        int total = 0;
        string where = SetQueryConditionForNews();
        string tableName = " SingleFeeDetail AS s  JOIN ProjectApplyInfo  ON s.Pjno=ProjectApplyInfo.Pjno AND PjStatus>-1 ";
        string fieldStr = "ProjectApplyInfo.*";
        DataSet ds = SqlHelper.GetPagination(tableName, fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 设置统计详情导出查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForStatisticsExport()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按提交日期查询
        //提交开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            list.Add(" convert(varchar(50),applytime,23) >='" + Request.Form["sdate"] + "'");
        //提交截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            list.Add(" convert(varchar(50),applytime,23) <='" + Request.Form["edate"] + "'");
        //按项目名称
        if (!string.IsNullOrEmpty(Request.Form["pjname"]))
            list.Add(" pjname like'%" + Request.Form["pjname"] + "%'");
        //基站名称
        if (!string.IsNullOrEmpty(Request.Form["stationname"]))
            list.Add(" stationname  like '%" + Request.Form["stationname"] + "%'");
        //按办事处
        if (!string.IsNullOrEmpty(Request.Form["townagency"]))
            list.Add(" townagency  ='" + Request.Form["townagency"] + "'");
        //按代维单位
        if (!string.IsNullOrEmpty(Request.Form["dwunit"]))
            list.Add(" dwunit  ='" + Request.Form["dwunit"] + "'");
        //按项目状态：费用审批状态：-1：被退回；0：待办事处审核；1：待维护中心审核；2：待建维部经理审核；3：待财务审核；4：待副总经理审核；5：待总经理审核；6：审批完结，施工中,待验收；7：施工完成，已验收，待归档；8：已归档
        if (!string.IsNullOrEmpty(Request.Form["pjstatus"]))
        {
            string pjstr = "";
            switch (Request.Form["pjstatus"])
            {
                case "0":
                    pjstr = "办事处审核中";
                    break;
                case "1":
                    pjstr = "维护中心审核中";
                    break;
                case "2":
                    pjstr = "建维部经理审批中";
                    break;
                case "3":
                    pjstr = "财务审核中";
                    break;
                case "4":
                    pjstr = "副总经理审批中";
                    break;
                case "5":
                    pjstr = "总经理审批中";
                    break;
                case "6":
                    pjstr = "待验收项目";
                    break;
                case "7":
                    pjstr = "待归档申请";
                    break;
                case "8":
                    pjstr = "已归档";
                    break;
                default:
                    break;
            }
            list.Add("pjstatus='" + pjstr + "'");
        }
        //代维单位用户只获取自己的信息
        if (roleid == 7)
            list.Add(" dwunit= '" + deptName + "'");
        //铁塔县办事处用户只获取自己的信息
        if (roleid == 1)
            list.Add(" townagency= '" + deptName + "'");
        //2016年7月18日新增办事处统计页面显示费用申请详情 begin
        //按维修单项 sc，为“总计”时显示全部维修单项
        if (!string.IsNullOrEmpty(Request.QueryString["sc"]) && Request.QueryString["sc"] != "总计")
            list.Add(" s.SingleClass ='" + Request.QueryString["sc"] + "'");
        //按办事处前缀查询 ap
        if (!string.IsNullOrEmpty(Request.QueryString["ap"]))
            list.Add(" TownAgency ='" + Request.QueryString["ap"] + "办事处'");
        //统计开始日期
        if (!string.IsNullOrEmpty(Request.QueryString["sdate"]))
            list.Add(" convert(varchar(50),applytime,23) >='" + Request.QueryString["sdate"] + "'");
        //统计截止日期
        if (!string.IsNullOrEmpty(Request.QueryString["edate"]))
            list.Add(" convert(varchar(50),applytime,23) <='" + Request.QueryString["edate"] + "'");
        //------导出页面查询---------------//
        //按维修单项 sc，为“总计”时显示全部维修单项
        if (!string.IsNullOrEmpty(Request.Form["sc"]) && Request.Form["sc"] != "总计")
            list.Add(" s.SingleClass ='" + Request.Form["sc"] + "'");
        //按办事处前缀查询 ap
        if (!string.IsNullOrEmpty(Request.Form["ap"]))
            list.Add(" TownAgency ='" + Request.Form["ap"] + "办事处'");
        //按代维单位查询 2016年8月5日
        if (!string.IsNullOrEmpty(Request.Form["dw"]))
            list.Add(" dwunit ='" + Request.Form["dw"] + "'");
        //2016年7月18日新增办事处统计页面显示费用申请详情 end

        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 导出办事处统计申请费用申请明细
    /// </summary>
    public void ExportAgStatisticsList()
    {
        string where = SetQueryConditionForStatisticsExport();
        if (where != "")
            where = " where " + where;
        StringBuilder sql = new StringBuilder();
        sql.Append(" SELECT pjname,pjstatus,stationname,stationno,dwunit,townagency,applytime,budgetamount,MaintenanceContent,feelist,ag,mc, bgm,finance,dgm,gm,Acceptance from SingleFeeDetail AS s  JOIN (");
        sql.Append("SELECT c.pjno,pjname,pjstatus as pjst,");
        sql.Append("CASE PjStatus WHEN -1 THEN '已退回' when 0 then '办事处审核中' when 1  then '维护中心审核中'  WHEN 2 THEN '建维部经理审批中' when 3 then '财务审核中'  when 4 then '副总经理审批中'  when 5 then '总经理审批中'  when 6 then '待验收项目' when 7 then '待归档申请' when 8 then '已归档' end as pjstatus,");
        sql.Append("stationname,stationno,dwunit,townagency,applytime,budgetamount,MaintenanceContent,feelist,");
        sql.Append("(CASE  WHEN AgencyComment IS NULL THEN AgencyAudit ELSE AgencyAudit+'，'+AgencyComment end) as ag,");
        sql.Append("(CASE  WHEN MaintenanceCenterComment IS NULL THEN MaintenanceCenterAudit ELSE MaintenanceCenterAudit+'，'+MaintenanceCenterComment end) as mc,");
        sql.Append("(CASE  WHEN BuildingGMComment IS NULL THEN BuildingGMAudit ELSE BuildingGMAudit+'，'+BuildingGMComment end) as bgm,");
        sql.Append("(CASE  WHEN FinanceComment IS NULL THEN FinanceAudit ELSE FinanceAudit+'，'+FinanceComment end) as finance,");
        sql.Append("(CASE  WHEN DeputyGMComment IS NULL THEN DeputyGMAudit ELSE DeputyGMAudit+'，'+DeputyGMComment end) as dgm,");
        sql.Append("(CASE  WHEN GMComment IS NULL THEN GMAudit ELSE GMAudit+'，'+GMComment end) as gm,");
        sql.Append("Acceptance FROM ProjectApplyInfo AS c LEFT JOIN  ");
        sql.Append(" (SELECT pjno,(SELECT SingleClass+'('+convert(varchar(20),SingleFee) +') 元   ' FROM SingleFeeDetail  WHERE pjno=A.pjno FOR XML PATH('')) AS feelist FROM SingleFeeDetail A  GROUP BY pjno ) ");
        sql.Append(" AS b ON c.pjno=b.pjno) as a  ON s.Pjno=a.Pjno  and pjst>-1 ");
        sql.Append(where);
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString());
        DataTable dt = ds.Tables[0];
        dt.Columns[0].ColumnName = "项目名称";
        dt.Columns[1].ColumnName = "项目进度";
        dt.Columns[2].ColumnName = "基站名称";
        dt.Columns[3].ColumnName = "基站编号";
        dt.Columns[4].ColumnName = "代维单位";
        dt.Columns[5].ColumnName = "铁塔县办事处";
        dt.Columns[6].ColumnName = "申请时间";
        dt.Columns[7].ColumnName = "预算金额";
        dt.Columns[8].ColumnName = "维修事项";
        dt.Columns[9].ColumnName = "维修单项";
        dt.Columns[10].ColumnName = "办事处意见";
        dt.Columns[11].ColumnName = "维护中心意见";
        dt.Columns[12].ColumnName = "建维部经理审批";
        dt.Columns[13].ColumnName = "财务审核";
        dt.Columns[14].ColumnName = "副总经理审批";
        dt.Columns[15].ColumnName = "总经理审批";
        dt.Columns[16].ColumnName = "验收情况";
        string sheetName = !string.IsNullOrEmpty(Request.Form["sc"]) ? Request.Form["sc"] : "Sheet1";
        //ExcelHelper.ExportByWeb(dt, "", "维护费用明细—分类统计.xls", sheetName);
    }
    #endregion
}