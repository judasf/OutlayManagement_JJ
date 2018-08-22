/**
* Create a cookie with the given key and value and other optional parameters.
* 
* @example $.cookie('the_cookie', 'the_value');
* @desc Set the value of a cookie.
* @example $.cookie('the_cookie', 'the_value', { expires: 7, path: '/', domain: 'jquery.com', secure: true });
* @desc Create a cookie with all available options.
* @example $.cookie('the_cookie', 'the_value');
* @desc Create a session cookie.
* @example $.cookie('the_cookie', null);
* @desc Delete a cookie by passing null as value. Keep in mind that you have to use the same path and domain used when the cookie was set.
* 
* @param String
*            key The key of the cookie.
* @param String
*            value The value of the cookie.
* @param Object
*            options An object literal containing key/value pairs to provide optional cookie attributes.
* @option Number|Date expires Either an integer specifying the expiration date from now on in days or a Date object. If a negative value is specified (e.g. a date in the past), the cookie will be deleted. If set to null or omitted, the cookie will be a session cookie and will not be retained when the the browser exits.
* @option String path The value of the path atribute of the cookie (default: path of page that created the cookie).
* @option String domain The value of the domain attribute of the cookie (default: domain of page that created the cookie).
* @option Boolean secure If true, the secure attribute of the cookie will be set and the cookie transmission will require a secure protocol (like HTTPS).
* @type undefined
* 
* @name $.cookie
* @cat Plugins/Cookie
* @author Klaus Hartl/klaus.hartl@stilbuero.de
* 
* Get the value of a cookie with the given key.
* 
* @example $.cookie('the_cookie');
* @desc Get the value of a cookie.
* 
* @param String
*            key The key of the cookie.
* @return The value of the cookie.
* @type String
* 
* @name $.cookie
* @cat Plugins/Cookie
* @author Klaus Hartl/klaus.hartl@stilbuero.de
*/
$.cookie = function (key, value, options) {
    if (arguments.length > 1 && (value === null || typeof value !== "object")) {
        options = $.extend({}, options);
        if (value === null) {
            options.expires = -1;
        }
        if (typeof options.expires === 'number') {
            var days = options.expires, t = options.expires = new Date();
            t.setDate(t.getDate() + days);
        }
        return (document.cookie = [encodeURIComponent(key), '=', options.raw ? String(value) : encodeURIComponent(String(value)), options.expires ? '; expires=' + options.expires.toUTCString() : '', options.path ? '; path=' + options.path : '', options.domain ? '; domain=' + options.domain : '', options.secure ? '; secure' : ''].join(''));
    }
    options = value || {};
    var result, decode = options.raw ? function (s) {
        return s;
    } : decodeURIComponent;
    return (result = new RegExp('(?:^|; )' + encodeURIComponent(key) + '=([^;]*)').exec(document.cookie)) ? decode(result[1]) : null;
};

/**
* @author 孙宇
* 
* @requires jQuery
* 
* 将form表单元素的值序列化成对象
* 
* @returns object
*/
$.serializeObject = function (form) {
    var o = {};
    $.each(form.serializeArray(), function (index) {
        if (this['value'] != undefined && this['value'].length > 0) {// 如果表单项的值非空，才进行序列化操作
            if (o[this['name']]) {
                o[this['name']] = o[this['name']] + "," + this['value'];
            } else {
                o[this['name']] = this['value'];
            }
        }
    });
    return o;
};

/**
* @author 孙宇
* 
* 增加formatString功能
* 
* 使用方法：$.formatString('字符串{0}字符串{1}字符串','第一个变量','第二个变量');
* 
* @returns 格式化后的字符串
*/
$.formatString = function (str) {
    for (var i = 0; i < arguments.length - 1; i++) {
        str = str.replace("{" + i + "}", arguments[i + 1]);
    }
    return str;
};

/**
* @author 孙宇
* 
* 接收一个以逗号分割的字符串，返回List，list里每一项都是一个字符串
* 
* @returns list
*/
$.stringToList = function (value) {
    if (value != undefined && value != '') {
        var values = [];
        var t = value.split(',');
        for (var i = 0; i < t.length; i++) {
            values.push('' + t[i]); /* 避免他将ID当成数字 */
        }
        return values;
    } else {
        return [];
    }
};
/**
* JSON对象转换成String
* 
* @param o
* @returns
*/
$.jsonToString = function (o) {
    var r = [];
    if (typeof o == "string")
        return "\"" + o.replace(/([\'\"\\])/g, "\\$1").replace(/(\n)/g, "\\n").replace(/(\r)/g, "\\r").replace(/(\t)/g, "\\t") + "\"";
    if (typeof o == "object") {
        if (!o.sort) {
            for (var i in o)
                r.push(i + ":" + sy.jsonToString(o[i]));
            if (!!document.all && !/^\n?function\s*toString\(\)\s*\{\n?\s*\[native code\]\n?\s*\}\n?\s*$/.test(o.toString)) {
                r.push("toString:" + o.toString.toString());
            }
            r = "{" + r.join() + "}";
        } else {
            for (var i = 0; i < o.length; i++)
                r.push(sy.jsonToString(o[i]));
            r = "[" + r.join() + "]";
        }
        return r;
    }
    return o.toString();
};


/**
* @author 孙宇
* 
* @requires jQuery
* 
* 改变jQuery的AJAX默认属性和方法
*/
$.ajaxSetup({
    type: 'POST',
    error: function (XMLHttpRequest, textStatus, errorThrown) {
        try {
            parent.$.messager.progress('close');
            parent.$.messager.alert('错误', XMLHttpRequest.responseText);
        } catch (e) {
            alert(XMLHttpRequest.responseText);
        }
    }
});

/**
* @author 孙宇
* 
* 去字符串空格
* 
* @returns
*/
String.prototype.trim = function () {
    return this.replace(/(^\s*)|(\s*$)/g, '');
};
String.prototype.ltrim = function () {
    return this.replace(/(^\s*)/g, '');
};
String.prototype.rtrim = function () {
    return this.replace(/(\s*$)/g, '');
};
/*
* @author judasfan
* 使用js以post方式提交表单1
*/
var jsPostForm = function (url, params) {
    /// <summary>使用js以post方式提交表单</summary>
    /// <param name="url" type="string">表单提交地址</param>
    /// <param name="params" type="object">提交的参数{name:value}</param>   
    var tempForm = document.createElement('form');
    tempForm.action = url;
    tempForm.method = 'post';
    tempForm.style.display = 'none';
    for (var x in params) {
        var opt = document.createElement('input');
        opt.name = x;
        opt.value = params[x];
        tempForm.appendChild(opt);
    }
    document.body.appendChild(tempForm);
    tempForm.submit();
    return tempForm;
};

/** 数字金额大写转换(可以处理整数,小数,负数) */
var digitUppercase = function (n) {
    var fraction = ['角', '分'];
    var digit = [
        '零', '壹', '贰', '叁', '肆',
        '伍', '陆', '柒', '捌', '玖'
    ];
    var unit = [
        ['元', '万', '亿'],
        ['', '拾', '佰', '仟']
    ];
    var head = n < 0 ? '欠' : '';
    n = Math.abs(n);
    var s = '';
    for (var i = 0; i < fraction.length; i++) {
        s += (digit[Math.floor(n * 10 * Math.pow(10, i)) % 10] + fraction[i]).replace(/零./, '');
    }
    s = s || '整';
    n = Math.floor(n);
    for (var i = 0; i < unit[0].length && n > 0; i++) {
        var p = '';
        for (var j = 0; j < unit[1].length && n > 0; j++) {
            p = digit[n % 10] + unit[1][j] + p;
            n = Math.floor(n / 10);
        }
        s = p.replace(/(零.)*零$/, '').replace(/^$/, '零') + unit[0][i] + s;
    }
    return head + s.replace(/(零.)*零元/, '元')
        .replace(/(零.)+/g, '零')
        .replace(/^整$/, '零元整');
};