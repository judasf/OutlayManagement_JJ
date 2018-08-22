<%@ Page Language="C#" %>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>安阳市公安局交通管理支队</title>
    <link href="favicon.ico" rel="shortcut icon" />
    <script src="js/easyui/jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="js/easyui/jquery.easyui.min.js" type="text/javascript"></script>
    <link href="js/easyui/themes/default/easyui.css" rel="stylesheet" type="text/css" />
    <link href="js/easyui/themes/icon.css" rel="stylesheet" type="text/css" />
    <script src="js/easyui/locale/easyui-lang-zh_CN.js" type="text/javascript"></script>
    <link href="css/login.css" rel="stylesheet" type="text/css" />
    <script src="js/extJquery.js" type="text/javascript"></script>
    <script type="text/javascript" src="js/login.js"></script>
    <script type="text/javascript">
        var loginFun = function () {
            var $form = $('#form-body');
            if ($form.form('validate')) {
                login_loading($("#loginBtn")[0]);
                $.post('service/commondb.ashx/login', $.serializeObject($form), function (result) {
                    if (result.success) {
                        location.replace('index.aspx')
                    }
                    else {
                        $.messager.alert('提示', result.msg, 'error');
                        login_loaded();
                    }
                }, 'json')
            }
        }
        $(function () {
            $('#form-body').keydown(function (event) {
                if (event.which == 13) {
                    loginFun();
                }
            });
            //var imgSrc = 'css/images/login/denglu.jpg';
            //var imgHoverSrc = 'css/images/login/denglu1.jpg';
            //$('#loginBtn').hover(function () {
            //    $(this).attr({ src: imgHoverSrc });
            //}, function () {
            //    $(this).attr({ src: imgSrc });
            //});
        });
    </script>
    <style type="text/css">
        body {
            text-align: center;
        }

        div#pagebg {
            margin: auto;
            position: absolute;
            top: 0;
            left: 0;
            bottom: 0;
            right: 0;
            width: 657px;
            height: 371px;
            background: url(css/images/login/loginbg.jpg) no-repeat;
            padding-top: 70px;
        }

        div#loginbg {
            width: 300px;
            float: right;
            margin-right: 106px;
            margin-top: 50px;
        }

            div#loginbg ul li {
                list-style: none;
                line-height: 60px;
                text-align: center;
            }
    </style>
</head>
<body>
    <div id="pagebg">
        <div id="loginbg">
            <form id="form-body">
                <ul>
                    <li>账 号：
                        <input class="easyui-validatebox account form-textbox validatebox-text" type="text"
                            name="usernum" value="" required="required"></li>
                    <li>密 码： 
                        <input class="easyui-validatebox  password form-textbox validatebox-text" type="password"
                            name="userpwd" value="" required="required"></li>
                    <li>
                        <img id="loginBtn" src="css/images/login/denglu.jpg" onclick="loginFun();" alt="" /></li>
                </ul>
            </form>
        </div>
         <p style="text-align: center; float:right;width:600px;margin-top:-3px; color:#fff; font-size: 14px;">安阳市公安局</p>
        <div class="clearfix"></div>
       
    </div>
</body>
</html>
