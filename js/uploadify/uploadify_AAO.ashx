<%@ WebHandler Language="C#" Class="uploadify" %>

using System;
using System.Web;
using System.IO;
using System.Web.SessionState;
using System.Reflection;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections;
using System.Collections.Generic;
/// <summary>
/// uploadify插件处理页面——稽核追加经费申请页面图片上传
/// </summary>
public class uploadify : IHttpHandler, IRequiresSessionState
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
    /// 登陆用户部门名
    /// </summary>
    string deptName;
    public void ProcessRequest(HttpContext context)
    {
        //不让浏览器缓存
        context.Response.Buffer = true;
        context.Response.ExpiresAbsolute = DateTime.Now.AddDays(-1);
        context.Response.AddHeader("pragma", "no-cache");
        context.Response.AddHeader("cache-control", "");
        context.Response.CacheControl = "no-cache";
        context.Response.ContentType = "text/plain";
        context.Response.Charset = "utf-8";

        Request = context.Request;
        Response = context.Response;
        Session = context.Session;
        Server = context.Server;
        //判断登陆状态
        if(!Request.IsAuthenticated)
        {
            Response.Write("{\"success\":false,\"msg\":\"登陆超时，请重新登陆后再进行操作！\"}");
            Response.End();
            return;
        }
        else
        {
            UserDetail ud = new UserDetail();
            roleid = ud.LoginUser.RoleId.ToString();
            deptName = ud.LoginUser.UserDept;
         }
        //上传保存的根目录
        string rootFloder = Request.Form["floderName"];
        //保存文件夹
        string floderName = rootFloder+@"\upfiles\" + DateTime.Now.ToString("yyyyMMdd") + @"\";
        //文件夹路径
        string floderPath = Server.MapPath("~") + rootFloder+@"\upfiles\" + DateTime.Now.ToString("yyyyMMdd") + @"\";
        //上传的文件
        HttpPostedFile file = context.Request.Files["Filedata"];
        //文件扩展名
        string fileExtension = Path.GetExtension(file.FileName);
        //不带后缀的文件名
        string fileNameWithOutExtension = Path.GetFileNameWithoutExtension(file.FileName);
        //新文件名
        Random myrdn = new Random();//产生随机数
        //新文件名
        string newFileName = DateTime.Now.ToString("yyyyMMddhhmmss") + myrdn.Next(1000);
        if(roleid=="1")//基层用户上传时带单位名称
        {
            newFileName = fileNameWithOutExtension +"-"+ deptName;
        }
        //给新文件名加扩展名
        newFileName += fileExtension;
        //上传的文件路径
        string filePath = floderPath + newFileName;
        //文件相对路径
        string retrunFilePath = rootFloder+"/upfiles/" + DateTime.Now.ToString("yyyyMMdd") + "/" + newFileName;
        if(file != null)
        {
            if(!Directory.Exists(floderPath))
            {
                Directory.CreateDirectory(floderPath);
            }
            if(fileExtension != ".jpg" && fileExtension != ".jpeg" && fileExtension != ".bmp" && fileExtension != ".gif")
            {
                Response.Write("{\"success\":false,\"msg\":\"文件格式不正确，请选择正确的图片文件！\"}");
                return;
            }
            if(File.Exists(filePath))
            {
                File.Delete(filePath);
            }
            //保存文件
            file.SaveAs(filePath);
            Response.Write("{\"success\":true,\"msg\":\"上传成功！\",\"filepath\":\"" + retrunFilePath + "\"}");

        }
        else
        {
            Response.Write("{\"success\":false,\"msg\":\"上传失败，上传文件不存在！\"}");
        }
    }
    public bool IsReusable
    {
        get
        {
            return false;
        }
    }

}