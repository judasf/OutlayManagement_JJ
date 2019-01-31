<%@ WebHandler Language="C#" Class="DataStatistics" %>

using System;
using System.Web;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections;
using System.Collections.Generic;
using org.in2bits.MyXls;
/// <summary>
/// 报表统计功能
/// </summary>
public class DataStatistics : IHttpHandler, IRequiresSessionState
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
    /// 用户单位名称
    /// </summary>
    string deptName;
    /// <summary>
    /// 管辖范围
    /// </summary>
    string scopeDepts;
    /// <summary>
    /// 角色编号
    /// </summary>
    string roleid;
    public void ProcessRequest(HttpContext context)
    {
        //不让浏览器缓存
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
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
            scopeDepts = ud.LoginUser.ScopeDepts;
            roleid = ud.LoginUser.RoleId.ToString();
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
        Response.End();
    }
    #region 一般用户操作
    /// <summary>
    /// 一般用户获取经费收支余额总表
    /// </summary>
    public void GetDeptAllOutlayDetail()
    {
        string smonth = DateTime.Now.ToString("yyyy-01");
        string emonth = DateTime.Now.ToString("yyyy-MM");
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            smonth = Convert.ToString(Request.Form["sdate"].ToString().Replace("年", "-").Replace("月", ""));
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            emonth = Convert.ToString(Request.Form["edate"].ToString().Replace("年", "-").Replace("月", ""));
        string sql = "SELECT * FROM  [dbo].[F_GetDeptAllOutlayDetail](" + deptid + ",'" + smonth + "','" + emonth + "')";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], ds.Tables[0].Rows.Count, true, "income,spending,unusedoutlay", "outlaymonth", "合计"));
    }
    /// <summary>
    /// 一般用户获取经费收支分类统计表
    /// </summary>
    public void GetDeptOutlayTypeStatistics()
    {
        string smonth = DateTime.Now.ToString("yyyy-01");
        string emonth = DateTime.Now.ToString("yyyy-MM");
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            smonth = Convert.ToString(Request.Form["sdate"].ToString().Replace("年", "-").Replace("月", ""));
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            emonth = Convert.ToString(Request.Form["edate"].ToString().Replace("年", "-").Replace("月", ""));
        string sql = "SELECT * FROM  [dbo].[F_GetDeptOutlayTypeStatistics](" + deptid + ",'" + smonth + "','" + emonth + "')";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], ds.Tables[0].Rows.Count, true, "pbo,app_pb,app_sp,ddo,reim_pb,reim_sp,balance", "outlaymonth", "合计"));
    }
    #endregion
    #region 稽核操作
    /// <summary>
    /// 稽核获取各单位经费收支余额总表,2017-12-29修改按天统计
    /// </summary>
    public void GetAllDeptAllOutlayDetailForAudit()
    {
        string sdate = DateTime.Now.ToString("yyyy-01-01");//默认当年1月1日
        string edate = DateTime.Now.ToString("yyyy-MM-dd");//默认当天
        string deptid = "";
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            sdate = Convert.ToString(Request.Form["sdate"]);
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            edate = Convert.ToString(Request.Form["edate"]);
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            deptid = Convert.ToString(Request.Form["deptId"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@scopeDepts",scopeDepts),
            new SqlParameter("@deptid",deptid),
            new SqlParameter("@sdate",sdate),
            new SqlParameter("@edate",edate)
        };
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.StoredProcedure, "GetAllDeptAllOutlayDetailForAudit", paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], ds.Tables[0].Rows.Count, true, "income,spending,unusedoutlay", "deptname", "合计"));
    }
    /// <summary>
    /// 稽核获取各单位经费收支分类统计表
    /// </summary>
    public void GetAllDeptOutlayTypeStatisticsForAudit()
    {
        string sdate = DateTime.Now.ToString("yyyy-01-01");//默认当年1月1日
        string edate = DateTime.Now.ToString("yyyy-MM-dd");//默认当天
        string deptid = "";
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            sdate = Convert.ToString(Request.Form["sdate"]);
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            edate = Convert.ToString(Request.Form["edate"]);
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            deptid = Convert.ToString(Request.Form["deptId"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@scopeDepts",scopeDepts),
            new SqlParameter("@deptid",deptid),
            new SqlParameter("@sdate",sdate),
            new SqlParameter("@edate",edate)
        };
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.StoredProcedure, "GetAllDeptOutlayTypeStatisticsForAudit", paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds.Tables[0], ds.Tables[0].Rows.Count, true, "pbo,app_pb,app_sp,ddo,reim_pb,reim_sp,balance", "deptname", "合计"));
    }
    /// <summary>
    /// 稽核导出各单位经费收支余额总表
    /// </summary>
    public void ExportDeptAllOutlayStatistics()
    {
        string smonth = DateTime.Now.ToString("yyyy-MM");
        string emonth = smonth;
        string deptid = "";
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            smonth = Convert.ToString(Request.Form["sdate"].ToString().Replace("年", "-").Replace("月", ""));
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            emonth = Convert.ToString(Request.Form["edate"].ToString().Replace("年", "-").Replace("月", ""));
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            deptid = Convert.ToString(Request.Form["deptId"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@scopeDepts",scopeDepts),
            new SqlParameter("@deptid",deptid),
            new SqlParameter("@sdate",smonth),
            new SqlParameter("@edate",emonth)
        };
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.StoredProcedure, "GetAllDeptAllOutlayDetailForAudit", paras);
        DataTable dt = new DataTable();
        DataColumn dtc = new DataColumn("deptname", typeof(string));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("income", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("spending", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("unusedoutlay", typeof(decimal));
        dt.Columns.Add(dtc);
        foreach (DataRow dr in ds.Tables[0].Rows)
        {
            DataRow row = dt.NewRow();
            row[0] = dr[1];
            row[1] = dr[2];
            row[2] = dr[3];
            row[3] = dr[4];
            dt.Rows.Add(row);
        }
        //添加合计行
        DataRow lastRow = dt.NewRow();
        lastRow[0] = "合计";
        lastRow[1] = dt.Compute("sum(income)", "");
        lastRow[2] = dt.Compute("sum(spending)", "");
        lastRow[3] = dt.Compute("sum(unusedoutlay)", "");
        dt.Rows.Add(lastRow);
        //设置列标题
        dt.Columns[0].ColumnName = "单位";
        dt.Columns[1].ColumnName = "收入";
        dt.Columns[2].ColumnName = "支出";
        dt.Columns[3].ColumnName = "可用额度";
        string dateStr = "日期：";
        if (smonth == emonth)
            dateStr += smonth.Replace("-", "年") + "月";
        else
            dateStr += smonth.Replace("-", "年") + "月—" + emonth.Replace("-", "年") + "月";

        CreateAllOutlayStatisticsXls(dt, "单位经费收支余额总表.xls", dateStr);
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 稽核导出单位经费收支分类统计表
    /// </summary>
    public void ExportDeptOutlayTypeStatistics()
    {
        string smonth = DateTime.Now.ToString("yyyy-MM");
        string emonth = smonth;
        string deptid = "";
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            smonth = Convert.ToString(Request.Form["sdate"].ToString().Replace("年", "-").Replace("月", ""));
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            emonth = Convert.ToString(Request.Form["edate"].ToString().Replace("年", "-").Replace("月", ""));
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            deptid = Convert.ToString(Request.Form["deptId"]);
        SqlParameter[] paras = new SqlParameter[] {
            new SqlParameter("@scopeDepts",scopeDepts),
            new SqlParameter("@deptid",deptid),
            new SqlParameter("@sdate",smonth),
            new SqlParameter("@edate",emonth)
        };
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.StoredProcedure, "GetAllDeptOutlayTypeStatisticsForAudit", paras);
        DataTable dt = new DataTable();
        DataColumn dtc = new DataColumn("deptname", typeof(string));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("pbo", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("app_pb", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("app_sp", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("ddo", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("reim_pb", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("reim_sp", typeof(decimal));
        dt.Columns.Add(dtc);
        dtc = new DataColumn("balance", typeof(decimal));
        dt.Columns.Add(dtc);
        foreach (DataRow dr in ds.Tables[0].Rows)
        {
            DataRow row = dt.NewRow();
            row[0] = dr[1];
            row[1] = dr[2];
            row[2] = dr[3];
            row[3] = dr[4];
            row[4] = dr[5];
            row[5] = dr[6];
            row[6] = dr[7];
            row[7] = dr[8];
            dt.Rows.Add(row);
        }
        //添加合计行
        DataRow lastRow = dt.NewRow();
        lastRow[0] = "合计";
        lastRow[1] = dt.Compute("sum(pbo)", "");
        lastRow[2] = dt.Compute("sum(app_pb)", "");
        lastRow[3] = dt.Compute("sum(app_sp)", "");
        lastRow[4] = dt.Compute("sum(ddo)", "");
        lastRow[5] = dt.Compute("sum(reim_pb)", "");
        lastRow[6] = dt.Compute("sum(reim_sp)", "");
        lastRow[7] = dt.Compute("sum(balance)", "");
        dt.Rows.Add(lastRow);
        //设置列标题
        dt.Columns[0].ColumnName = "单位";
        dt.Columns[1].ColumnName = "定额公用";
        dt.Columns[2].ColumnName = "追加公用";
        dt.Columns[3].ColumnName = "追加专项";
        dt.Columns[4].ColumnName = "扣减经费";
        dt.Columns[5].ColumnName = "公用经费支出";
        dt.Columns[6].ColumnName = "专项经费支出";
        dt.Columns[7].ColumnName = "余额";
        string dateStr = "日期：";
        if (smonth == emonth)
            dateStr += smonth.Replace("-", "年") + "月";
        else
            dateStr += smonth.Replace("-", "年") + "月—" + emonth.Replace("-", "年") + "月";

        CreateOutlayTypeStatisticsXls(dt, "单位经费收支分类统计表.xls", dateStr);
        Response.Flush();
        Response.End();
    }
    #endregion

    #region 一般用户导出excel
    /// <summary>
    ///导出一般用户经费收支余额总表
    /// </summary>
    public void ExportBaseUserAllOutlayStatistics()
    {
        string smonth = DateTime.Now.ToString("yyyy-MM");
        string emonth = smonth;
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            smonth = Convert.ToString(Request.Form["sdate"].ToString().Replace("年", "-").Replace("月", ""));
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            emonth = Convert.ToString(Request.Form["edate"].ToString().Replace("年", "-").Replace("月", ""));
        string sql = "SELECT REPLACE(outlaymonth+'月','-','年')as outlaymonth ,income,spending,unusedoutlay FROM  [dbo].[F_GetDeptAllOutlayDetail](" + deptid + ",'" + smonth + "','" + emonth + "')";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        DataTable dt = ds.Tables[0];
        //添加合计行
        DataRow row = dt.NewRow();
        row[0] = "合计";
        row[1] = dt.Compute("sum(income)", "");
        row[2] = dt.Compute("sum(spending)", "");
        row[3] = dt.Rows[dt.Rows.Count - 1][3];
        dt.Rows.Add(row);
        //设置列标题
        dt.Columns[0].ColumnName = "日期";
        dt.Columns[1].ColumnName = "收入";
        dt.Columns[2].ColumnName = "支出";
        dt.Columns[3].ColumnName = "可用额度";
        string deptStr = "单位：" + deptName;
        CreateAllOutlayStatisticsXls(dt, "经费收支余额总表.xls", deptStr);
        Response.Flush();
        Response.End();
    }
    /// <summary>
    ///导出一般用户经费收支分类统计表
    /// </summary>
    public void ExportBaseUserOutlayTypeStatistics()
    {
        string smonth = DateTime.Now.ToString("yyyy-MM");
        string emonth = smonth;
        //开始日期
        if (!string.IsNullOrEmpty(Request.Form["sdate"]))
            smonth = Convert.ToString(Request.Form["sdate"].ToString().Replace("年", "-").Replace("月", ""));
        //截止日期
        if (!string.IsNullOrEmpty(Request.Form["edate"]))
            emonth = Convert.ToString(Request.Form["edate"].ToString().Replace("年", "-").Replace("月", ""));
        string sql = "SELECT REPLACE(outlaymonth+'月','-','年')as outlaymonth,pbo,app_pb,app_sp,ddo,reim_pb,reim_sp,balance ";
        sql += "FROM  [dbo].[F_GetDeptOutlayTypeStatistics](" + deptid + ",'" + smonth + "','" + emonth + "')";
        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql);
        DataTable dt = ds.Tables[0];
        //添加合计行
        DataRow row = dt.NewRow();
        row[0] = "合计";
        row[1] = dt.Compute("sum(pbo)", "");
        row[2] = dt.Compute("sum(app_pb)", "");
        row[3] = dt.Compute("sum(app_sp)", "");
        row[4] = dt.Compute("sum(ddo)", "");
        row[5] = dt.Compute("sum(reim_pb)", "");
        row[6] = dt.Compute("sum(reim_sp)", "");
        row[7] = dt.Compute("sum(balance)", "");

        dt.Rows.Add(row);
        //设置列标题
        dt.Columns[0].ColumnName = "日期";
        dt.Columns[1].ColumnName = "定额公用";
        dt.Columns[2].ColumnName = "追加公用";
        dt.Columns[3].ColumnName = "追加专项";
        dt.Columns[4].ColumnName = "扣减经费";
        dt.Columns[5].ColumnName = "公用经费支出";
        dt.Columns[6].ColumnName = "专项经费支出";
        dt.Columns[7].ColumnName = "余额";
        string deptStr = "单位：" + deptName;
        CreateOutlayTypeStatisticsXls(dt, "经费收支分类统计表.xls", deptStr);
        Response.Flush();
        Response.End();
    }
    #endregion
    #region 生成统计数据Excel
    /// <summary>
    /// 生成经费收支余额总表
    /// </summary>
    /// <param name="ds">获取DataSet数据集</param>
    /// <param name="xlsName">报表表名</param>
    private void CreateAllOutlayStatisticsXls(DataTable dt, string xlsName, string secLineStr)
    {
        XlsDocument xls = new XlsDocument();
        xls.FileName = Server.UrlEncode(xlsName);
        int rowIndex = 3;
        int colIndex = 0;
        Worksheet sheet = xls.Workbook.Worksheets.Add("sheet");//状态栏标题名称
        Cells cells = sheet.Cells;
        //设置列格式
        ColumnInfo colInfo = new ColumnInfo(xls, sheet);
        colInfo.ColumnIndexStart = 0;
        colInfo.ColumnIndexEnd = 4;
        colInfo.Width = 14 * 256;
        sheet.AddColumnInfo(colInfo);
        //设置样式
        XF xf = xls.NewXF();
        xf.HorizontalAlignment = HorizontalAlignments.Centered;
        xf.VerticalAlignment = VerticalAlignments.Centered;
        xf.TextWrapRight = true;
        xf.UseBorder = true;
        xf.TopLineStyle = 1;
        xf.TopLineColor = Colors.Black;
        xf.BottomLineStyle = 1;
        xf.BottomLineColor = Colors.Black;
        xf.LeftLineStyle = 1;
        xf.LeftLineColor = Colors.Black;
        xf.RightLineStyle = 1;
        xf.RightLineColor = Colors.Black;
        xf.Font.Bold = true;
        xf.Font.Height = 16 * 20;
        //设置单位或日期样式
        XF xfSec = xls.NewXF();
        xfSec.HorizontalAlignment = HorizontalAlignments.Left;
        xfSec.VerticalAlignment = VerticalAlignments.Centered;
        xfSec.TextWrapRight = true;
        xfSec.UseBorder = true;
        xfSec.TopLineStyle = 1;
        xfSec.TopLineColor = Colors.Black;
        xfSec.BottomLineStyle = 1;
        xfSec.BottomLineColor = Colors.Black;
        xfSec.LeftLineStyle = 1;
        xfSec.LeftLineColor = Colors.Black;
        xfSec.RightLineStyle = 1;
        xfSec.RightLineColor = Colors.Black;
        xfSec.Font.Bold = false;
        //
        MergeRegion(ref sheet, xf, xlsName.Substring(0, xlsName.Length - 4), 1, 1, 1, 4);
        MergeRegion(ref sheet, xfSec, secLineStr, 2, 2, 1, 4);
        //填充标题
        foreach (DataColumn col in dt.Columns)
        {
            colIndex++;
            Cell cell = cells.Add(3, colIndex, col.ColumnName, xf);
            cell.Font.Bold = false;
            cell.Font.Height = 9 * 20;
        }
        //填充数据
        foreach (DataRow row in dt.Rows)
        {
            rowIndex++;
            colIndex = 0;
            foreach (DataColumn col in dt.Columns)
            {
                colIndex++;
                Cell cell = cells.Add(rowIndex, colIndex, row[col.ColumnName].ToString(), xf);//转换为数字型
                                                                                              //如果你数据库里的数据都是数字的话 最好转换一下，不然导入到Excel里是以字符串形式显示。
                cell.Font.FontFamily = FontFamilies.Roman; //字体
                cell.Font.Bold = false;
                cell.Font.Height = 9 * 20;
            }

        }
        //设置行高
        sheet.Rows[1].RowHeight = 24 * 20;
        xls.Send();
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 生成经费收支分类统计表
    /// </summary>
    /// <param name="ds">获取DataSet数据集</param>
    /// <param name="xlsName">报表表名</param>
    private void CreateOutlayTypeStatisticsXls(DataTable dt, string xlsName, string secLineStr)
    {
        XlsDocument xls = new XlsDocument();
        xls.FileName = Server.UrlEncode(xlsName);
        int rowIndex = 4;
        int colIndex = 0;
        Worksheet sheet = xls.Workbook.Worksheets.Add("sheet");//状态栏标题名称
        Cells cells = sheet.Cells;
        //设置列格式
        ColumnInfo colInfo = new ColumnInfo(xls, sheet);
        colInfo.ColumnIndexStart = 0;
        colInfo.ColumnIndexEnd = 8;
        colInfo.Width = 16 * 256;
        sheet.AddColumnInfo(colInfo);
        //设置标题样式
        XF xfTitle = xls.NewXF();
        xfTitle.HorizontalAlignment = HorizontalAlignments.Centered;
        xfTitle.VerticalAlignment = VerticalAlignments.Centered;
        xfTitle.TextWrapRight = true;
        xfTitle.UseBorder = true;
        xfTitle.TopLineStyle = 1;
        xfTitle.TopLineColor = Colors.Black;
        xfTitle.BottomLineStyle = 1;
        xfTitle.BottomLineColor = Colors.Black;
        xfTitle.LeftLineStyle = 1;
        xfTitle.LeftLineColor = Colors.Black;
        xfTitle.RightLineStyle = 1;
        xfTitle.RightLineColor = Colors.Black;
        xfTitle.Font.Bold = true;
        xfTitle.Font.Height = 16 * 20;
        //设置单位或日期样式
        XF xfSec = xls.NewXF();
        xfSec.HorizontalAlignment = HorizontalAlignments.Left;
        xfSec.VerticalAlignment = VerticalAlignments.Centered;
        xfSec.TextWrapRight = true;
        xfSec.UseBorder = true;
        xfSec.TopLineStyle = 1;
        xfSec.TopLineColor = Colors.Black;
        xfSec.BottomLineStyle = 1;
        xfSec.BottomLineColor = Colors.Black;
        xfSec.LeftLineStyle = 1;
        xfSec.LeftLineColor = Colors.Black;
        xfSec.RightLineStyle = 1;
        xfSec.RightLineColor = Colors.Black;
        xfSec.Font.Bold = false;
        //设置内容
        XF xfCon = xls.NewXF();
        xfCon.HorizontalAlignment = HorizontalAlignments.Centered;
        xfCon.VerticalAlignment = VerticalAlignments.Centered;
        xfCon.TextWrapRight = true;
        xfCon.UseBorder = true;
        xfCon.TopLineStyle = 1;
        xfCon.TopLineColor = Colors.Black;
        xfCon.BottomLineStyle = 1;
        xfCon.BottomLineColor = Colors.Black;
        xfCon.LeftLineStyle = 1;
        xfCon.LeftLineColor = Colors.Black;
        xfCon.RightLineStyle = 1;
        xfCon.RightLineColor = Colors.Black;
        xfCon.Font.Bold = false;
        //
        MergeRegion(ref sheet, xfTitle, xlsName.Substring(0, xlsName.Length - 4), 1, 1, 1, 8);
        MergeRegion(ref sheet, xfSec, secLineStr, 2, 2, 1, 8);
        MergeRegion(ref sheet, xfCon, "收入", 3, 3, 2, 4);
        MergeRegion(ref sheet, xfCon, "支出", 3, 3, 5, 7);
        MergeRegion(ref sheet, xfCon, "余额", 3, 4, 8, 8);
        //填充标题
        foreach (DataColumn col in dt.Columns)
        {
            colIndex++;
            Cell cell = cells.Add(4, colIndex, col.ColumnName, xfCon);
        }
        //填充数据
        foreach (DataRow row in dt.Rows)
        {
            rowIndex++;
            colIndex = 0;
            foreach (DataColumn col in dt.Columns)
            {
                colIndex++;
                Cell cell = cells.Add(rowIndex, colIndex, row[col.ColumnName].ToString(), xfCon);//转换为数字型
                                                                                                 //如果你数据库里的数据都是数字的话 最好转换一下，不然导入到Excel里是以字符串形式显示。
                cell.Font.FontFamily = FontFamilies.Roman; //字体
            }

        }
        MergeRegion(ref sheet, xfCon, dt.Columns[0].ColumnName, 3, 4, 1, 1);
        //设置行高
        sheet.Rows[1].RowHeight = 24 * 20;
        xls.Send();
        Response.Flush();
        Response.End();
    }
    /// <summary>
    /// 合并单元格，参数列表：开始行，结束行，开始列，结束列
    /// </summary>
    /// <param name="ws">sheet</param>
    /// <param name="xf">样式</param>
    /// <param name="title">新内容</param>
    /// <param name="startRow">开始行</param>
    /// <param name="startCol">开始列</param>
    /// <param name="endRow">结束行</param>
    /// <param name="endCol">结束列</param>
    private void MergeRegion(ref Worksheet ws, XF xf, string title, int startRow, int endRow, int startCol, int endCol)
    {
        for (int i = startCol; i <= endCol; i++)
        {
            for (int j = startRow; j <= endRow; j++)
            {
                ws.Cells.Add(j, i, title, xf);
            }
        }
        ws.Cells.Merge(startRow, endRow, startCol, endCol);
    }
    #endregion
    #region 额度修正
    /// <summary>
    /// 设置公用额度修正查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForFixedOutlay()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["deptid"]))
            list.Add(" deptid ='" + Request.Form["deptid"] + "'");
        //按状态
        if (!string.IsNullOrEmpty(Request.Form["status"]))
        {
            if (Request.Form["status"].ToString() == "1")//待修正额度
                list.Add(" balance <> uno_pb ");
            else //全部额度，不显示额度为0
            {
                list.Add("  uno_pb<>0 ");
            }
        }
        else
            list.Add(" balance <> uno_pb ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取修正额度公用经费明细
    /// </summary>
    public void GetFixedPublicOutlyDetail()
    {
        int total = 0;
        string where = SetQueryConditionForFixedOutlay();
        StringBuilder tableName = new StringBuilder();
        tableName.Append(" (SELECT a.deptid,deptname,ISNULL(pbo, 0)  AS pbo,ISNULL(aao_pb, 0) AS aao_pb, ISNULL(spo_pb, 0) AS spo_pb,ISNULL(smp_sp, 0) AS smp_sp,ISNULL(ddo, 0)  AS ddo,ISNULL(cash_pb, 0) AS cash_pb, ISNULL(account_pb, 0) AS account_pb, ISNULL(card_pb, 0) AS card_pb,(ISNULL(pbo,0)+ISNULL(aao_pb,0)+ISNULL(spo_pb,0)+ISNULL(smp_sp,0)-ISNULL(ddo,0)-ISNULL(cash_pb,0)-ISNULL(account_pb,0)-ISNULL(card_pb,0)) AS balance ,ISNULL(uno_pb,0) as uno_pb ");
        tableName.Append(" FROM (SELECT deptname,deptid FROM  department )AS a LEFT JOIN ");
        //定额公用
        tableName.Append("(SELECT deptid,SUM(monthoutlay) AS pbo FROM  PublicOutlayDetail GROUP BY deptid) AS pod ON  a.deptid = pod.deptid LEFT JOIN ");
        tableName.Append("(SELECT deptid,SUM(ApplyOutlay) AS aao_pb FROM   AuditApplyOutlayDetail WHERE  STATUS = 2 AND dbo.F_GetRootIdByCid(outlaycategory) = 1  GROUP BY  deptid ) AS aaod_pb  ON  a.deptid = aaod_pb.deptid LEFT JOIN ");
        //申请追加公用经费
        tableName.Append("( SELECT deptid,SUM(ApplyOutlay) AS spo_pb FROM   SpecialOutlayApplyDetail WHERE  STATUS = 4 AND dbo.F_GetRootIdByCid(outlaycategory) = 1 GROUP BY deptid )AS soad_pb ON  a.deptid = soad_pb.deptid LEFT JOIN ");
        //专项额度合并到公用,只计算已合并的额度
        tableName.Append("(SELECT deptid,SUM(SpecialOutlay) AS smp_sp FROM   SpecialOutlayMergePublic Where [Status]=0 GROUP BY deptid )AS smgp_sp ON  a.deptid = smgp_sp.deptid LEFT JOIN ");
        //公用额度扣减经费
        tableName.Append(" (SELECT deptid,SUM(deductoutlay) AS ddo FROM   DeductOutlayDetail WHERE  STATUS = 2 AND OutlayCategory=1 GROUP BY deptid) AS dod ON  a.deptid = dod.deptid LEFT JOIN ");
        //--公用经费现金支出（未恢复状态-2以上单笔现金总和）
        tableName.Append("(SELECT deptid,SUM(SingleOutlay) AS cash_pb FROM ( SELECT rcp.*,rcpd.SingleOutlay FROM   Reimburse_CashPayDetail AS rcpd JOIN Reimburse_CashPay AS rcp ON  rcp.ReimburseNo = rcpd.ReimburseNo WHERE  rcpd.STATUS > -2 AND   [type] = 1 ) AS backcashlist_sp GROUP BY  deptid) AS r_backcash_pb ON  a.deptid = r_backcash_pb.deptid  LEFT JOIN ");
        //公用经费转账支出（未退回状态-1以上）
        tableName.Append("(SELECT deptid, SUM(ReimburseOutlay) AS account_pb FROM   Reimburse_AccountPay WHERE  [status]>-1 AND [type] = 1 GROUP BY deptid ) AS r_account_pb ON  a.deptid = r_account_pb.deptid LEFT JOIN ");
        //公用经费公务卡支出（未退回状态-1以上）
        tableName.Append("(SELECT deptid,SUM(ReimburseOutlay) AS card_pb FROM   Reimburse_CardPay WHERE  [status]>-1 AND [type] = 1 GROUP BY deptid ) AS r_card_pb ON  a.deptid = r_card_pb.deptid LEFT JOIN ");
        //公用经费当前可用额度
        tableName.Append("(SELECT deptid, UnusedOutlay AS uno_pb FROM   PublicOutlay )AS current_pb ON  a.deptid = current_pb.deptid) AS summary  ");
        string fieldStr = "*";
        DataSet ds = SqlHelper.GetPagination(tableName.ToString(), fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 设置专项额度修正查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForFixedSpecialOutlay()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["sp_deptid"]))
            list.Add(" deptid ='" + Request.Form["sp_deptid"] + "'");
        //按状态
        if (!string.IsNullOrEmpty(Request.Form["sp_status"]))
        {
            if (Request.Form["sp_status"].ToString() == "1")//待修正额度
                list.Add(" balance <> UnusedOutlay ");
            else //全部额度，不显示额度为0
            {
                list.Add("  UnusedOutlay<>0 ");
            }
        }
        else
            list.Add(" balance <> UnusedOutlay ");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取修正额度专项经费明细
    /// </summary>
    public void GetFixedSpecialOutlyDetail()
    {
        int total = 0;
        string where = SetQueryConditionForFixedSpecialOutlay();
        StringBuilder tableName = new StringBuilder();
        tableName.Append(" (SELECT a.deptid,deptname,a.outlayid,a.AllOutlay,ISNULL(ddo, 0)  AS ddo,ISNULL(cash_sp, 0) AS cash_sp ,ISNULL(account_sp, 0) AS account_sp,ISNULL(card_sp, 0) AS card_sp,ISNULL(smp_sp, 0) AS smp_sp,(AllOutlay-ISNULL(ddo,0)-ISNULL(cash_sp,0)-ISNULL(account_sp,0)-ISNULL(card_sp,0)-ISNULL(smp_sp,0)) AS balance,UnusedOutlay ");
        tableName.Append(" FROM (SELECT deptname,deptid,outlayid,UnusedOutlay,AllOutlay FROM  SpecialOutlay ) AS a LEFT JOIN  ");
        //专项经费扣减额度
        tableName.Append(" (SELECT deptid,SpecialOutlayID,SUM(DeductOutlay) AS ddo FROM   DeductOutlayDetail  WHERE  STATUS = 2 AND OutlayCategory=2 GROUP BY deptid,SpecialOutlayID) AS dod ON  a.deptid = dod.deptid AND a.outlayid=dod.SpecialOutlayID  LEFT JOIN ");
        //专项经费现金支出（未恢复状态-2以上单笔现金总和）
        tableName.Append(" (SELECT deptid,OutlayID,SUM(SingleOutlay) AS cash_sp FROM   (SELECT rcp.*,rcpd.SingleOutlay FROM   Reimburse_CashPayDetail AS rcpd JOIN Reimburse_CashPay AS rcp ON  rcp.ReimburseNo = rcpd.ReimburseNo WHERE  rcpd.STATUS > -2 AND  [type] = 2 ) AS backcashlist_sp GROUP BY deptid, OutlayID ) AS r_backcash_sp ON  a.deptid = r_backcash_sp.deptid AND a.outlayid=r_backcash_sp.outlayid LEFT JOIN ");
        //专项经费转账支出（未退回状态-1以上）
        tableName.Append(" ( SELECT deptid,OutlayID,SUM(ReimburseOutlay) AS account_sp FROM   Reimburse_AccountPay WHERE  [status]>-1 AND [type] = 2 GROUP BY deptid,OutlayID ) AS r_account_sp ON  a.deptid = r_account_sp.deptid AND r_account_sp.outlayid = a.outlayid LEFT JOIN ");
        //专项经费公务卡支出 （未退回状态-1以上）
        tableName.Append("  ( SELECT deptid,OutlayID,SUM(ReimburseOutlay) AS card_sp FROM Reimburse_CardPay WHERE  [status]>-1 AND [type] = 2 GROUP BY deptid,OutlayID ) AS r_card_sp ON  a.deptid = r_card_sp.deptid AND r_card_sp.outlayid = a.outlayid LEFT JOIN  ");
        //专项额度合并到公用，只计算已合并状态的额度
        tableName.Append(" ( SELECT deptid,OutlayID,SpecialOutlay AS smp_sp FROM   SpecialOutlayMergePublic Where [Status]=0) AS smgp_sp ON  a.deptid = smgp_sp.deptid AND smgp_sp.outlayid = a.outlayid ) AS summary ");
        string fieldStr = "*";
        DataSet ds = SqlHelper.GetPagination(tableName.ToString(), fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 修正公用经费额度
    /// </summary>
    public void FixedPublicOutlay()
    {
        int deptid = 0;
        decimal balance = 0;
        int.TryParse(Request.Form["deptid"], out deptid);
        decimal.TryParse(Request.Form["balance"], out balance);
        string sql = "UPDATE PublicOutlay set UnusedOutlay =@balance where deptid=@deptid";
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@deptid",deptid),
            new SqlParameter("balance",balance)
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"额度修正成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    /// <summary>
    /// 修正专项经费额度
    /// </summary>
    public void FixedSpecialOutlay()
    {
        int deptid = 0;
        int outlayid = 0;
        decimal balance = 0;
        int.TryParse(Request.Form["deptid"], out deptid);
        int.TryParse(Request.Form["outlayid"], out outlayid);
        decimal.TryParse(Request.Form["balance"], out balance);
        string sql = "UPDATE SpecialOutlay set UnusedOutlay =@balance where deptid=@deptid and outlayid=@outlayid";
        SqlParameter[] paras = new SqlParameter[]{
            new SqlParameter("@deptid",deptid),
            new SqlParameter("@outlayid",outlayid),
            new SqlParameter("balance",balance)
        };
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql, paras);
        if (result == 1)
            Response.Write("{\"success\":true,\"msg\":\"额度修正成功\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"执行出错\"}");
    }
    #endregion 额度修正
    #region 显示待取回现金支出明细
    /// <summary>
    /// 设置待取回现金支出明细查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForUnRetrieveOutlay()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();
        //按单位查询
        if (!string.IsNullOrEmpty(Request.Form["deptId"]))
            list.Add(" aa.deptid ='" + Request.Form["deptId"] + "'");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }

    public void GetUnRetrieveSingleOutlay()
    {
        int total = 0;
        string where = SetQueryConditionForUnRetrieveOutlay();
        string tableName = "Department AS d JOIN (SELECT deptid,outlayid,SingleOutlay,CASE WHEN outlayid=0 THEN '公用经费' when outlayid<>0 then '专项经费'  end as outlaytype,reimburseno FROM (SELECT  deptid,rcp.ReimburseNo,rcp.OutlayID,rcpd.SingleOutlay  FROM Reimburse_CashPayDetail  AS rcpd JOIN Reimburse_CashPay AS rcp ON rcp.ReimburseNo = rcpd.ReimburseNo WHERE  rcpd.STATUS=-1 )AS back) as aa ON d.DeptID=aa.deptid";
        string fieldStr = "aa.*,d.DeptName";
        DataSet ds = SqlHelper.GetPagination(tableName.ToString(), fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    #endregion
    #region 年度经费结余页面
    /// <summary>
    /// 设置年度经费结余页面查询条件
    /// </summary>
    /// <returns></returns>
    public string SetQueryConditionForAnnualBalance()
    {
        string queryStr = "";
        //设置查询条件
        List<string> list = new List<string>();

        //按单位查询
        if (roleid == "1")
            list.Add(" a.deptid ='" + deptid + "'");
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptId"]))
                list.Add(" a.deptid ='" + Request.Form["deptId"] + "'");
        }
        //按结余年度
        if (!string.IsNullOrEmpty(Request.Form["outlayyear"]))
            list.Add(" b.outlayyear ='" + Request.Form["outlayyear"] + "'");
        if (list.Count > 0)
            queryStr = string.Join(" and ", list.ToArray());
        return queryStr;
    }
    /// <summary>
    /// 获取年度结余额度明细
    /// </summary>
    public void GetAnnualBalanceDetail()
    {
        int total = 0;
        string where = SetQueryConditionForAnnualBalance();
        string tableName = " Department AS a  JOIN (SELECT * FROM AnnualBalanceDetail) AS b ON a.DeptID=b.DeptID";
        string fieldStr = "a.DeptName,b.*";
        DataSet ds = SqlHelper.GetPagination(tableName.ToString(), fieldStr, Request.Form["sort"].ToString(), Request.Form["order"].ToString(), where, Convert.ToInt32(Request.Form["rows"]), Convert.ToInt32(Request.Form["page"]), out total);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds, total));
    }
    /// <summary>
    /// 提取上面结余经费
    /// </summary>
    public void FetchAnnualBalance()
    {
        //设置额度年份
        string outlayyear = DateTime.Now.AddYears(-1).Year.ToString();
        ////设置操作日期限制，每年的元月1日-3日可进行操作
        //if (Convert.ToDateTime(DateTime.Now.ToString("yyyy-MM-dd")).CompareTo(Convert.ToDateTime(outlayyear + "-01-01")) < 0 || Convert.ToDateTime(DateTime.Now.ToString("yyyy-MM-dd")).CompareTo(Convert.ToDateTime(outlayyear + "-01-03")) > 0)
        //{
        //    Response.Write("{\"success\":false,\"msg\":\"请在每年元月1日至3日进行此项操作！\"}");
        //    return;
        //}

        StringBuilder sql = new StringBuilder();
        sql.Append(" IF NOT Exists(SELECT * FROM AnnualBalanceDetail where OutlayYear=@outlayyear) ");
        sql.Append(" BEGIN ");
        sql.Append(" INSERT  INTO dbo.AnnualBalanceDetail ( DeptID, OutlayID, memo, UnusedOutlay,OutlayYear )       SELECT  DeptId, 0, '公用经费', UnusedOutlay,@outlayyear FROM PublicOutlay; ");
        sql.Append(" INSERT  INTO dbo.AnnualBalanceDetail( DeptID, OutlayID, memo, UnusedOutlay,OutlayYear ) SELECT  DeptId, OutlayId, UseFor, UnusedOutlay, @outlayyear FROM SpecialOutlay WHERE   UnusedOutlay <> 0; ");
        sql.Append(" END ");
        int result = SqlHelper.ExecuteNonQuery(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), new SqlParameter("@outlayyear", outlayyear));
        if (result >= 1)
            Response.Write("{\"success\":true,\"msg\":\"执行出错\"}");
        else
            Response.Write("{\"success\":false,\"msg\":\"" + outlayyear + "年的结余经费数据已提取！\"}");
    }
    #endregion
    #region 单位对账单
    /// <summary>
    /// 获取单位对账单信息
    /// </summary>
    public void GetAccountStatementInfo()
    {
        //设置额度年份,默认当年
        string outlayyear = DateTime.Now.Year.ToString();
        //单位编号
        string did = "";
        //按单位查询
        if (roleid == "1")
            did = deptid;
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptId"]))
                did = Request.Form["deptId"];
        }
        //按年度
        if (!string.IsNullOrEmpty(Request.Form["outlayyear"]))
            outlayyear = Request.Form["outlayyear"];
        SqlParameter[] paras = new SqlParameter[]
        {
            new SqlParameter("@outlaybalanceyear", int.Parse(outlayyear)-1),
            new SqlParameter("@outlayyear", outlayyear),
            new SqlParameter("@deptid", did)
        };
        StringBuilder sql = new StringBuilder();
        //全部合计
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn,'合计' AS memo,CONVERT(VARCHAR(50),SUM(income)) AS income, CONVERT(VARCHAR(50),SUM(payout)) AS payout FROM (");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn,'上年结余（小计）' AS memo,SUM(UnusedOutlay) AS income,'0' AS payout FROM dbo.AnnualBalanceDetail WHERE  OutlayYear=@outlaybalanceyear AND DeptID=@deptid ");
        sql.Append(" UNION  all");
        //公用经费小计
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'公用经费（小计）'AS memo, SUM(income) AS income ,'0'AS payout FROM ( ");
        sql.Append("  SELECT  MonthOutlay AS income  FROM dbo.PublicOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" UNION all  SELECT  ApplyOutlay  AS income  FROM dbo.AuditApplyOutlayDetail  WHERE status=2 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear ");
        sql.Append(" UNION all   SELECT  ApplyOutlay  AS income  FROM dbo.SpecialOutlayApplyDetail  WHERE status=6 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" ) as publicAllOutlay");

        sql.Append(" UNION all ");
        //专项经费
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'专项经费（小计）'AS memo,SUM(AllOutlay)AS income ,'0'AS payout FROM dbo.SpecialOutlay  WHERE DeptID=@deptid AND DATEPART(YEAR,OUtlaytime)=@outlayyear ");
        sql.Append(" UNION all ");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'扣减经费（小计）'AS memo,'-'+ CAST(SUM(DeductOutlay) AS nvarchar(50))AS income ,'0'AS payout FROM dbo.DeductOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear  ");
        sql.Append(" UNION all ");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'现金支出（小计）'AS memo,'0' AS income ,SUM(AuditCashOutlay) AS payout FROM dbo.Reimburse_CashPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION  SELECT ''AS m,'' AS d,'' AS cn ,'转账支出（小计）'AS memo,'0' AS income ,SUM(ReimburseOutlay) AS payout FROM dbo.Reimburse_AccountPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION SELECT ''AS m,'' AS d,'' AS cn ,'公务卡支出（小计）'AS memo,'0' AS income ,SUM(ReimburseOutlay) AS payout FROM dbo.Reimburse_CardPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear ) AS AllInandOut");
        sql.Append(" UNION ALL ");
        //上年结余小计 ,上年结余
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn,'上年结余（小计）' AS memo,CONVERT(VARCHAR(50),SUM(UnusedOutlay)) AS income,'' AS payout FROM dbo.AnnualBalanceDetail WHERE  OutlayYear=@outlaybalanceyear AND DeptID=@deptid   UNION ALL  SELECT ''AS m,'' AS d,CONVERT(NVARCHAR(50),outlayid) AS cn,memo,CONVERT(VARCHAR(50),UnusedOutlay) AS income,'' AS payout FROM dbo.AnnualBalanceDetail WHERE  OutlayYear=@outlaybalanceyear AND DeptID=@deptid ");
        sql.Append(" UNION ALL ");
        //公用经费小计 
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'公用经费（小计）'AS memo,CONVERT(VARCHAR(50),SUM(income))AS income ,''AS payout FROM ( ");
        sql.Append("  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'定额公用'AS cn ,OutlayMonth AS memo,MonthOutlay AS income,'' AS payout FROM dbo.PublicOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" UNION   SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,ApproveTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,ApproveTime)) AS d,'下发公用'AS cn ,OutlayMonth AS memo,ApplyOutlay  AS income,'' AS payout FROM dbo.AuditApplyOutlayDetail  WHERE status=2 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear ");
        sql.Append(" UNION   SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'申请公用'AS cn ,OutlayMonth AS memo,ApplyOutlay  AS income,'' AS payout FROM dbo.SpecialOutlayApplyDetail  WHERE status=6 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" ) as publicAllOutlay");
        //定额公用经费
        sql.Append(" UNION ALL  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'定额公用'AS cn ,OutlayMonth AS memo,CONVERT(VARCHAR(50),MonthOutlay) AS income,'' AS payout FROM dbo.PublicOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        //稽核下发公用
        sql.Append(" UNION ALL  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,ApproveTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,ApproveTime)) AS d,'下发公用'AS cn ,OutlayMonth AS memo,CONVERT(VARCHAR(50),ApplyOutlay) AS income,'' AS payout FROM dbo.AuditApplyOutlayDetail  WHERE status=2 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear ");
        //单位申请公用
        sql.Append(" UNION ALL  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'申请公用'AS cn ,OutlayMonth AS memo,CONVERT(VARCHAR(50),ApplyOutlay) AS income,'' AS payout FROM dbo.SpecialOutlayApplyDetail  WHERE status=6 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //专项经费小计,专项经费
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'专项经费（小计）'AS memo,CONVERT(VARCHAR(50),SUM(AllOutlay))AS income ,''AS payout FROM dbo.SpecialOutlay  WHERE DeptID=@deptid AND DATEPART(YEAR,OUtlaytime)=@outlayyear UNION all SELECT CONVERT(VARCHAR(50),DATEPART(MONTH,OutlayTime)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,OutlayTime)) AS d,CONVERT(NVARCHAR(50),a.OutlayId) AS cn,cname AS memo,CONVERT(VARCHAR(50),a.AllOutlay) AS income,'' AS payout FROM dbo.SpecialOutlay a LEFT JOIN dbo.Category b ON a.OutlayCategory=b.CID  WHERE DeptID=@deptid AND  DATEPART(YEAR,Outlaytime)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //扣减经费小计,扣减经费
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'扣减经费（小计）'AS memo,'-'+ CAST(SUM(DeductOutlay) AS nvarchar(50))AS income ,''AS payout FROM dbo.DeductOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear UNION all SELECT CONVERT(VARCHAR(50),DATEPART(MONTH,ApproveTime)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,ApproveTime)) AS d,CONVERT(VARCHAR(50),DeductNo) AS cn ,DeductReason AS memo,'-'+CAST(DeductOutlay AS nvarchar(50)) AS income,'' AS payout FROM dbo.DeductOutlayDetail WHERE status=2 AND DeptID=@deptid AND  DATEPART(YEAR,ApproveTime)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //现金支出小计,现金支出
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'现金支出（小计）'AS memo,'' AS income ,CONVERT(VARCHAR(50),SUM(AuditCashOutlay)) AS payout FROM dbo.Reimburse_CashPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION all SELECT CONVERT(VARCHAR(50),DATEPART(MONTH,AuditDate)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,AuditDate)) AS d,CONVERT(VARCHAR(50),ReimburseNo) AS cn ,ExpenseSubject AS memo,'' AS income,CONVERT(VARCHAR(50),AuditCashOutlay) AS payout FROM dbo.Reimburse_CashPay WHERE  status>2 AND DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //转账支出小计,转账支出
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'转账支出（小计）'AS memo,'' AS income ,CONVERT(VARCHAR(50),SUM(ReimburseOutlay)) AS payout FROM dbo.Reimburse_AccountPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION  all SELECT  CONVERT(VARCHAR(50),DATEPART(MONTH,AuditDate)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,AuditDate)) AS d,CONVERT(VARCHAR(50),ReimburseNo) AS cn ,ExpenseSubject AS memo,'' AS income,CONVERT(VARCHAR(50),ReimburseOutlay) AS payout FROM dbo.Reimburse_AccountPay WHERE  status>2 AND DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear  ");
        sql.Append(" UNION ALL ");
        //公务卡支出小计,公务卡支出
        sql.Append("  SELECT  ''AS m,'' AS d,'' AS cn ,'公务卡支出（小计）'AS memo,'' AS income ,CONVERT(VARCHAR(50),SUM(ReimburseOutlay)) AS payout FROM dbo.Reimburse_CardPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear  UNION all  SELECT  CONVERT(VARCHAR(50),DATEPART(MONTH,AuditDate)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,AuditDate)) AS d,CONVERT(VARCHAR(50),ReimburseNo) AS cn ,ExpenseSubject AS memo,'' AS income,CONVERT(VARCHAR(50),ReimburseOutlay) AS payout FROM dbo.Reimburse_CardPay WHERE  status>2 AND DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear ");


        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        Response.Write(JsonConvert.GetJsonFromDataTable(ds));
    }
    /// <summary>
    /// 生成单位对账单excel
    /// </summary>
    /// <param name="dt">获取DataSet数据集</param>
    /// <param name="xlsName">报表表名</param>
    /// <param name="secLineStr">第二行显示内容</param>
    private void CreateAccountStatementXls(DataTable dt, string xlsName, string secLineStr, string outlayyear)
    {
        XlsDocument xls = new XlsDocument();
        xls.FileName = Server.UrlEncode(xlsName);
        int rowIndex = 4;
        int colIndex = 0;
        Worksheet sheet = xls.Workbook.Worksheets.Add("sheet");//状态栏标题名称
        Cells cells = sheet.Cells;
        //设置列格式
        ColumnInfo colInfo = new ColumnInfo(xls, sheet);
        colInfo.ColumnIndexStart = 0;
        colInfo.ColumnIndexEnd = 5;
        colInfo.Width = 18 * 256;
        sheet.AddColumnInfo(colInfo);
        //设置标题样式
        XF xfTitle = xls.NewXF();
        xfTitle.HorizontalAlignment = HorizontalAlignments.Centered;
        xfTitle.VerticalAlignment = VerticalAlignments.Centered;
        xfTitle.TextWrapRight = true;
        xfTitle.UseBorder = true;
        xfTitle.TopLineStyle = 1;
        xfTitle.TopLineColor = Colors.Black;
        xfTitle.BottomLineStyle = 1;
        xfTitle.BottomLineColor = Colors.Black;
        xfTitle.LeftLineStyle = 1;
        xfTitle.LeftLineColor = Colors.Black;
        xfTitle.RightLineStyle = 1;
        xfTitle.RightLineColor = Colors.Black;
        xfTitle.Font.Bold = true;
        xfTitle.Font.Height = 16 * 20;
        //设置单位或日期样式
        XF xfSec = xls.NewXF();
        xfSec.HorizontalAlignment = HorizontalAlignments.Left;
        xfSec.VerticalAlignment = VerticalAlignments.Centered;
        xfSec.TextWrapRight = true;
        xfSec.UseBorder = true;
        xfSec.TopLineStyle = 1;
        xfSec.TopLineColor = Colors.Black;
        xfSec.BottomLineStyle = 1;
        xfSec.BottomLineColor = Colors.Black;
        xfSec.LeftLineStyle = 1;
        xfSec.LeftLineColor = Colors.Black;
        xfSec.RightLineStyle = 1;
        xfSec.RightLineColor = Colors.Black;
        xfSec.Font.Bold = false;
        //设置内容
        XF xfCon = xls.NewXF();
        xfCon.HorizontalAlignment = HorizontalAlignments.Centered;
        xfCon.VerticalAlignment = VerticalAlignments.Centered;
        xfCon.TextWrapRight = true;
        xfCon.UseBorder = true;
        xfCon.TopLineStyle = 1;
        xfCon.TopLineColor = Colors.Black;
        xfCon.BottomLineStyle = 1;
        xfCon.BottomLineColor = Colors.Black;
        xfCon.LeftLineStyle = 1;
        xfCon.LeftLineColor = Colors.Black;
        xfCon.RightLineStyle = 1;
        xfCon.RightLineColor = Colors.Black;
        xfCon.Font.Bold = false;
        //设置合计行样式
        XF xfsumrow = xls.NewXF();
        xfsumrow.Pattern = 1; // 单元格填充风格。如果设定为0，则是纯色填充(无色)，1代表没有间隙的实色 
        xfsumrow.PatternColor = Colors.Default2F; // 填充背景色
                                                  //
        MergeRegion(ref sheet, xfTitle, xlsName.Substring(0, xlsName.Length - 4), 1, 1, 1, 6);
        MergeRegion(ref sheet, xfSec, secLineStr, 2, 2, 1, 4);
        MergeRegion(ref sheet, xfSec, "金额单位：元", 2, 2, 5, 6);
        MergeRegion(ref sheet, xfCon, outlayyear + "年", 3, 3, 1, 2);
        MergeRegion(ref sheet, xfCon, "月", 4, 4, 1, 1);
        MergeRegion(ref sheet, xfCon, "日", 4, 4, 2, 2);
        MergeRegion(ref sheet, xfCon, "凭证编号", 3, 4, 3, 3);
        MergeRegion(ref sheet, xfCon, "摘要", 3, 4, 4, 4);
        MergeRegion(ref sheet, xfCon, "收入", 3, 4, 5, 5);
        MergeRegion(ref sheet, xfCon, "支出", 3, 4, 6, 6);
        //填充数据
        foreach (DataRow row in dt.Rows)
        {
            rowIndex++;
            colIndex = 0;
            foreach (DataColumn col in dt.Columns)
            {
                colIndex++;
                Cell cell;
                if (row[col.ColumnName].ToString().IndexOf("小计") > 0)
                    cell = cells.Add(rowIndex, colIndex, row[col.ColumnName].ToString(), xfsumrow);//转换为数字型

                else
                    cell = cells.Add(rowIndex, colIndex, row[col.ColumnName].ToString(), xfCon);//转换为数字型
                                                                                                //如果你数据库里的数据都是数字的话 最好转换一下，不然导入到Excel里是以字符串形式显示。
                cell.Font.FontFamily = FontFamilies.Roman; //字体
            }

        }
        //MergeRegion(ref sheet, xfCon, dt.Columns[0].ColumnName, 3, 4, 1, 1);
        //设置行高
        sheet.Rows[1].RowHeight = 24 * 20;
        xls.Send();
        Response.Flush();
        Response.End();
    }
    //导出对账单到Excel
    public void ExportAccountStatement()
    {
        //设置额度年份,默认当年
        string outlayyear = DateTime.Now.Year.ToString();
        //单位编号
        string did = "";
        //单位名称
        string dname = "";
        //按单位查询
        if (roleid == "1")
        {
            did = deptid;
            dname = deptName;
        }
        else
        {
            if (!string.IsNullOrEmpty(Request.Form["deptId"]))
                did = Request.Form["deptId"];
            if (!string.IsNullOrEmpty(Request.Form["deptname"]))
                dname = Request.Form["deptname"];
        }
        //按年度
        if (!string.IsNullOrEmpty(Request.Form["outlayyear"]))
            outlayyear = Request.Form["outlayyear"];
        SqlParameter[] paras = new SqlParameter[]
        {
            new SqlParameter("@outlaybalanceyear", int.Parse(outlayyear)-1),
            new SqlParameter("@outlayyear", outlayyear),
            new SqlParameter("@deptid", did)
        };
        StringBuilder sql = new StringBuilder();
        //全部合计
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn,'合计' AS memo,CONVERT(VARCHAR(50),SUM(income)) AS income, CONVERT(VARCHAR(50),SUM(payout)) AS payout FROM (");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn,'上年结余（小计）' AS memo,SUM(UnusedOutlay) AS income,'0' AS payout FROM dbo.AnnualBalanceDetail WHERE  OutlayYear=@outlaybalanceyear AND DeptID=@deptid ");
        sql.Append(" UNION All ");
       //公用经费小计
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'公用经费（小计）'AS memo, SUM(income) AS income ,'0'AS payout FROM ( ");
        sql.Append("  SELECT  MonthOutlay AS income  FROM dbo.PublicOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" UNION all  SELECT  ApplyOutlay  AS income  FROM dbo.AuditApplyOutlayDetail  WHERE status=2 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear ");
        sql.Append(" UNION all   SELECT  ApplyOutlay  AS income  FROM dbo.SpecialOutlayApplyDetail  WHERE status=6 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" ) as publicAllOutlay");
        sql.Append(" UNION all ");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'专项经费（小计）'AS memo,SUM(AllOutlay)AS income ,'0'AS payout FROM dbo.SpecialOutlay  WHERE DeptID=@deptid AND DATEPART(YEAR,OUtlaytime)=@outlayyear ");
        sql.Append(" UNION All ");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'扣减经费（小计）'AS memo,'-'+ CAST(SUM(DeductOutlay) AS nvarchar(50))AS income ,'0'AS payout FROM dbo.DeductOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear  ");
        sql.Append(" UNION All ");
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'现金支出（小计）'AS memo,'0' AS income ,SUM(AuditCashOutlay) AS payout FROM dbo.Reimburse_CashPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION  SELECT ''AS m,'' AS d,'' AS cn ,'转账支出（小计）'AS memo,'0' AS income ,SUM(ReimburseOutlay) AS payout FROM dbo.Reimburse_AccountPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION SELECT ''AS m,'' AS d,'' AS cn ,'公务卡支出（小计）'AS memo,'0' AS income ,SUM(ReimburseOutlay) AS payout FROM dbo.Reimburse_CardPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear ) AS AllInandOut");
        sql.Append(" UNION ALL ");
        //上年结余小计 ,上年结余
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn,'上年结余（小计）' AS memo,CONVERT(VARCHAR(50),SUM(UnusedOutlay)) AS income,'' AS payout FROM dbo.AnnualBalanceDetail WHERE  OutlayYear=@outlaybalanceyear AND DeptID=@deptid   UNION ALL  SELECT ''AS m,'' AS d,CONVERT(NVARCHAR(50),outlayid) AS cn,memo,CONVERT(VARCHAR(50),UnusedOutlay) AS income,'' AS payout FROM dbo.AnnualBalanceDetail WHERE  OutlayYear=@outlaybalanceyear AND DeptID=@deptid ");
        sql.Append(" UNION ALL ");
        //公用经费小计 
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'公用经费（小计）'AS memo,CONVERT(VARCHAR(50),SUM(income))AS income ,''AS payout FROM ( ");
        sql.Append("  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'定额公用'AS cn ,OutlayMonth AS memo,MonthOutlay AS income,'' AS payout FROM dbo.PublicOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" UNION   SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,ApproveTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,ApproveTime)) AS d,'下发公用'AS cn ,OutlayMonth AS memo,ApplyOutlay  AS income,'' AS payout FROM dbo.AuditApplyOutlayDetail  WHERE status=2 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear ");
        sql.Append(" UNION   SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'申请公用'AS cn ,OutlayMonth AS memo,ApplyOutlay  AS income,'' AS payout FROM dbo.SpecialOutlayApplyDetail  WHERE status=6 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" ) as publicAllOutlay");
        //定额公用经费
        sql.Append(" UNION ALL  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'定额公用'AS cn ,OutlayMonth AS memo,CONVERT(VARCHAR(50),MonthOutlay) AS income,'' AS payout FROM dbo.PublicOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        //稽核下发公用
        sql.Append(" UNION ALL  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,ApproveTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,ApproveTime)) AS d,'下发公用'AS cn ,OutlayMonth AS memo,CONVERT(VARCHAR(50),ApplyOutlay) AS income,'' AS payout FROM dbo.AuditApplyOutlayDetail  WHERE status=2 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear ");
        //单位申请公用
        sql.Append(" UNION ALL  SELECT CONVERT(NVARCHAR(50),DATEPART(MONTH,AuditTime)) AS m,CONVERT(NVARCHAR(50),DATEPART(DAY,AuditTime)) AS d,'申请公用'AS cn ,OutlayMonth AS memo,CONVERT(VARCHAR(50),ApplyOutlay) AS income,'' AS payout FROM dbo.SpecialOutlayApplyDetail  WHERE status=6 and dbo.F_GetRootIdByCid(OutlayCategory)=1 AND  DeptID=@deptid AND DATEPART(YEAR,AuditTime)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //专项经费小计,专项经费
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'专项经费（小计）'AS memo,CONVERT(VARCHAR(50),SUM(AllOutlay))AS income ,''AS payout FROM dbo.SpecialOutlay  WHERE DeptID=@deptid AND DATEPART(YEAR,OUtlaytime)=@outlayyear UNION all SELECT CONVERT(VARCHAR(50),DATEPART(MONTH,OutlayTime)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,OutlayTime)) AS d,CONVERT(NVARCHAR(50),a.OutlayId) AS cn,cname AS memo,CONVERT(VARCHAR(50),a.AllOutlay) AS income,'' AS payout FROM dbo.SpecialOutlay a LEFT JOIN dbo.Category b ON a.OutlayCategory=b.CID  WHERE DeptID=@deptid AND  DATEPART(YEAR,Outlaytime)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //扣减经费小计,扣减经费
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'扣减经费（小计）'AS memo,'-'+ CAST(SUM(DeductOutlay) AS nvarchar(50))AS income ,''AS payout FROM dbo.DeductOutlayDetail  WHERE status=2 AND  DeptID=@deptid AND DATEPART(YEAR,ApproveTime)=@outlayyear UNION all SELECT CONVERT(VARCHAR(50),DATEPART(MONTH,ApproveTime)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,ApproveTime)) AS d,CONVERT(VARCHAR(50),DeductNo) AS cn ,DeductReason AS memo,'-'+CAST(DeductOutlay AS nvarchar(50)) AS income,'' AS payout FROM dbo.DeductOutlayDetail WHERE status=2 AND DeptID=@deptid AND  DATEPART(YEAR,ApproveTime)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //现金支出小计,现金支出
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'现金支出（小计）'AS memo,'' AS income ,CONVERT(VARCHAR(50),SUM(AuditCashOutlay)) AS payout FROM dbo.Reimburse_CashPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION all SELECT CONVERT(VARCHAR(50),DATEPART(MONTH,AuditDate)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,AuditDate)) AS d,CONVERT(VARCHAR(50),ReimburseNo) AS cn ,ExpenseSubject AS memo,'' AS income,CONVERT(VARCHAR(50),AuditCashOutlay) AS payout FROM dbo.Reimburse_CashPay WHERE  status>2 AND DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear ");
        sql.Append(" UNION ALL ");
        //转账支出小计,转账支出
        sql.Append(" SELECT ''AS m,'' AS d,'' AS cn ,'转账支出（小计）'AS memo,'' AS income ,CONVERT(VARCHAR(50),SUM(ReimburseOutlay)) AS payout FROM dbo.Reimburse_AccountPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear UNION  all SELECT  CONVERT(VARCHAR(50),DATEPART(MONTH,AuditDate)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,AuditDate)) AS d,CONVERT(VARCHAR(50),ReimburseNo) AS cn ,ExpenseSubject AS memo,'' AS income,CONVERT(VARCHAR(50),ReimburseOutlay) AS payout FROM dbo.Reimburse_AccountPay WHERE  status>2 AND DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear  ");
        sql.Append(" UNION ALL ");
        //公务卡支出小计,公务卡支出
        sql.Append("  SELECT ''AS m,'' AS d,'' AS cn ,'公务卡支出（小计）'AS memo,'' AS income ,CONVERT(VARCHAR(50),SUM(ReimburseOutlay)) AS payout FROM dbo.Reimburse_CardPay  WHERE status>2 AND  DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear  UNION all SELECT  CONVERT(VARCHAR(50),DATEPART(MONTH,AuditDate)) AS m,CONVERT(VARCHAR(50),DATEPART(DAY,AuditDate)) AS d,CONVERT(VARCHAR(50),ReimburseNo) AS cn ,ExpenseSubject AS memo,'' AS income,CONVERT(VARCHAR(50),ReimburseOutlay) AS payout FROM dbo.Reimburse_CardPay WHERE  status>2 AND DeptID=@deptid AND DATEPART(YEAR,AuditDate)=@outlayyear ");


        DataSet ds = SqlHelper.ExecuteDataset(SqlHelper.GetConnection(), CommandType.Text, sql.ToString(), paras);
        DataTable dt = ds.Tables[0];
        string deptStr = "单位名称：" + dname;
        CreateAccountStatementXls(dt, "单位对账单.xls", deptStr, outlayyear);
        Response.Flush();
        Response.End();
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