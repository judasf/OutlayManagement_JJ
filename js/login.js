/*==================
 * 异步请求时加载效果
====================*/
var login_loading = function (e) {
    var load = document.createElement("div");
    load.id = "loginload";
    var pos = $(e).position();
    load.style.left = pos.left+500 + "px";
    load.style.top = pos.top + "px";
    load.style.width = e.offsetWidth + 35 + "px";
    load.style.height = e.offsetHeight - 5 + "px";
    load.style.lineHeight = e.offsetHeight - 10 + "px";
    document.body.appendChild(load);

    setLoad = function (len) {
        if ($("#loginload").length == 0) return;
        var s = "";
        for (var i = 0; i < len; i++) s += " .";
        $("#loginload").html("登录中" + s);
        if (len == 6) len = 0; len++;
        setTimeout("setLoad(" + len + ")", 400);
    };
    this.setLoad(6);
};
var login_loaded = function () {
    if ($("#loginload").length > 0) {
        document.body.removeChild($("#loginload")[0]);
    }
};