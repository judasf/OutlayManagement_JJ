using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class index : Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        //if(Session["usernum"] != null)
            //Response.Write(Session["username"].ToString());
            //Response.Write("111");
            //ClientScript.RegisterStartupScript(this.GetType(), "error", "$.messager.alert('提示','登陆超时，请重新登陆', 'error', function () {location.replace('/OutlayManagement/');});", true);
            //ClientScript.RegisterStartupScript(this.GetType(), "error", "location.href='http://www.baidu.com'", true);
            //Response.Write("<script>$.messager.alert('提示','登陆超时，请重新登陆', 'error', function () {location.replace('/OutlayManagement/');})</script>");
    }
}