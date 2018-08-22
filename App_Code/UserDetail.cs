using System;
using System.Collections.Generic;
using System.Web;
/// <summary>
///UserPage获取登录用户信息的基类，需要用到用户信息的页面直接继承这个类
/// </summary>
public class UserDetail
{
    public UserInfo LoginUser
    {
        get
        {
            /*将Context.User.Identity强制转换为FormsIdentity类的对象，
             * 通过访问Ticket属性的UserData属性，获得被序列化后的对象的字符串，
             * 最后用方法Newtonsoft.Json.JsonConvert.DeserializeObject<UserInfo>(userStr)
             * 将字符串反序列化成对象后再返回UserInfo类型的对象。
             * 我们只需要将DDefault页面的后台代码改为public partial class _Default : UserPage，就可以通过this.LoginUser来访问用户登录信息了。
             */
            string userStr = ((System.Web.Security.FormsIdentity)HttpContext.Current.User.Identity).Ticket.UserData;
            UserInfo user = Newtonsoft.Json.JsonConvert.DeserializeObject<UserInfo>(userStr);
            return user;
            /*这个是将票据生成的过程逆序
             */
            //string str= Request.Cookies[System.Web.Security.FormsAuthentication.FormsCookieName].Value;
            //System.Web.Security.FormsAuthenticationTicket ticket = System.Web.Security.FormsAuthentication.Decrypt(str);
            //string user = ticket.UserData;
            //Response.Write(user);
        }
    }
    public UserDetail()
    {
        
    }
}