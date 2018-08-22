using System;
using System.Collections.Generic;
using System.Web;
using Aspose.Words;
using Aspose.Words.Saving;
using System.IO;

/// <summary>
/// 通过aspose.word组件生产Word文档
/// </summary>
public class WordHelper
{
    public WordHelper()
    {
        //
        // TODO: 在此处添加构造函数逻辑
        //
    }
    /// <summary>
    /// 导出Word
    /// </summary>
    private Document WordDoc;
    private bool isOpened = false;//判断word模版是否被占用
    public void SaveAs(string strFileName, bool isReplace)
    {
        if (isReplace && File.Exists(strFileName))
        {
            File.Delete(strFileName);
        }
        WordDoc.Save(strFileName);
    }

    //基于模版新建Word文件
    public void OpenTempelte(string strTemppath)
    {
        WordDoc = new Document(strTemppath);

    }
    public static Document  CreateDocument(string strTemppath)
    {
        return  new Document(strTemppath);

    }
    public void FillLable(string LabelId, string Content)
    {

        //打开Word模版
        if (WordDoc.Range.Bookmarks[LabelId] != null)
        {
            WordDoc.Range.Bookmarks[LabelId].Text = Content;
        }
    }
    public void ResponseOut(string filename)
    {
        WordDoc.Save(System.Web.HttpContext.Current.Response, filename, ContentDisposition.Attachment, SaveOptions.CreateSaveOptions(SaveFormat.Doc));
    }

    public void OpenWebInline(string filename)
    {

        WordDoc.Save(System.Web.HttpContext.Current.Response, filename, ContentDisposition.Inline, SaveOptions.CreateSaveOptions(SaveFormat.Doc));
    }

    /// <summary>
    /// 设置打开密码
    /// </summary>
    /// <param name="pwd"></param>
    public void SetPassword(string pwd)
    {
        WordDoc.Protect(ProtectionType.ReadOnly, pwd);
    }

    /// <summary>
    /// 不可编辑受保护，需输入密码
    /// </summary>
    /// <param name="Password"></param>
    public void NoEdit(string Password)
    {
        WordDoc.Protect(ProtectionType.ReadOnly, Password);
    }

    public void ExportWord(string fileName, string wordname)
    {
        //输出word
        System.IO.FileInfo file = new System.IO.FileInfo(fileName);
        System.Web.HttpContext.Current.Response.Clear();
        System.Web.HttpContext.Current.Response.Charset = "GB2312";
        System.Web.HttpContext.Current.Response.ContentEncoding = System.Text.Encoding.UTF8;
        // 添加头信息，为"文件下载/另存为"对话框指定默认文件名 
        System.Web.HttpContext.Current.Response.AddHeader("Content-Disposition", "attachment; filename=" + HttpUtility.UrlEncode(wordname, System.Text.Encoding.UTF8));
        // 添加头信息，指定文件大小，让浏览器能够显示下载进度 
        System.Web.HttpContext.Current.Response.AddHeader("Content-Length", file.Length.ToString());
        // 指定返回的是一个不能被客户端读取的流，必须被下载 
        System.Web.HttpContext.Current.Response.ContentType = "application/ms-word";
        // 把文件流发送到客户端 
        System.Web.HttpContext.Current.Response.WriteFile(file.FullName);
        // 停止页面的执行 
        System.Web.HttpContext.Current.ApplicationInstance.CompleteRequest();

    }

    public void ChangWordStyle(string markName, string content)
    {
        DocumentBuilder builder = new DocumentBuilder(this.WordDoc);
        builder.MoveToBookmark(markName);
        char[] chs = content.ToCharArray();
        int index = 0;
        while (true)
        {
            if (index >= content.Length)
            {
                break;
            }
            if (chs[index] == '<')
            {
                if (content.Length > index + 3 && content.Substring(index + 1, 2).ToUpper() == "/P")
                {
                    builder.Writeln();
                }
                else if (content.Length > index + 7 && content.Substring(index + 1, 6).ToUpper() == "STRONG")
                {
                    builder.Font.Bold = true;
                }
                else if (content.Length > index + 8 && content.Substring(index + 1, 7).ToUpper() == "/STRONG")
                {
                    builder.Font.Bold = false;
                }
                else if (content.Length > index + 5 && content.Substring(index + 1, 4).ToUpper() == "BR /")
                {
                    builder.Writeln();
                }
                else if (content.Length > index + 3 && content.Substring(index + 1, 2).ToUpper() == "BR")
                {
                    builder.Writeln();
                }
                index = content.IndexOf(">", index) + 1;

            }
            else
            {
                if (content.IndexOf("<", index) == -1)
                {
                    string text = content.Substring(index);
                    builder.Write(HttpUtility.HtmlDecode(text));
                    index += text.Length;
                }
                else
                {
                    string text = content.Substring(index, content.IndexOf("<", index) - index);
                    builder.Write(HttpUtility.HtmlDecode(text));
                    index += text.Length;
                }
            }
        }

    }

}