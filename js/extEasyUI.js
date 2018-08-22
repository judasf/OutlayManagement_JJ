/**
* 使panel和datagrid在加载时提示
* 
* @author 孙宇
* 
* @requires jQuery,EasyUI
* 
*/
$.fn.panel.defaults.loadingMessage = '加载中....';
$.fn.datagrid.defaults.loadMsg = '加载中....';

/**
* @author 孙宇
* 
* @requires jQuery,EasyUI
* 
* panel关闭时回收内存，主要用于layout使用iframe嵌入网页时的内存泄漏问题
*/
$.extend($.fn.panel.defaults, {
    onBeforeDestroy: function () {
        var frame = $('iframe', this);
        try {
            if (frame.length > 0) {
                for (var i = 0; i < frame.length; i++) {
                    frame[i].src = '';
                    frame[i].contentWindow.document.write('');
                    frame[i].contentWindow.close();
                }
                frame.remove();
                if (navigator.userAgent.indexOf("MSIE") > 0) {// IE特有回收内存方法
                    try {
                        CollectGarbage();
                    } catch (e) {
                    }
                }
            }
        } catch (e) {
        }
    }
});

/**
* @author 孙宇
* 
* @requires jQuery,EasyUI
* 
* 防止panel/window/dialog组件超出浏览器边界
* @param left
* @param top
*/
var easyuiPanelOnMove = function (left, top) {
    var l = left;
    var t = top;
    if (l < 1) {
        l = 1;
    }
    if (t < 1) {
        t = 1;
    }
    var width = parseInt($(this).parent().css('width')) + 14;
    var height = parseInt($(this).parent().css('height')) + 14;
    var right = l + width;
    var buttom = t + height;
    var browserWidth = $(window).width();
    var browserHeight = $(window).height();
    if (right > browserWidth) {
        l = browserWidth - width;
    }
    if (buttom > browserHeight) {
        t = browserHeight - height;
    }
    $(this).parent().css({/* 修正面板位置 */
        left: l,
        top: t
    });
};
$.fn.dialog.defaults.onMove = easyuiPanelOnMove;
$.fn.window.defaults.onMove = easyuiPanelOnMove;
$.fn.panel.defaults.onMove = easyuiPanelOnMove;

/**
* 
* 通用错误提示
* 
* 用于datagrid/treegrid/tree/combogrid/combobox/form加载数据出错时的操作
* 
* @author 孙宇
* 
* @requires jQuery,EasyUI
*/
var myOnLoadError = {
    onLoadError: function (XMLHttpRequest) {
        if (parent.$ && parent.$.messager) {
            parent.$.messager.progress('close');
            parent.$.messager.alert('错误', XMLHttpRequest.responseText);
        } else {
            $.messager.progress('close');
            $.messager.alert('错误', XMLHttpRequest.responseText);
        }
    }
};
$.extend($.fn.datagrid.defaults, myOnLoadError);
$.extend($.fn.treegrid.defaults, myOnLoadError);
$.extend($.fn.tree.defaults, myOnLoadError);
$.extend($.fn.combogrid.defaults, myOnLoadError);
$.extend($.fn.combobox.defaults, myOnLoadError);
$.extend($.fn.form.defaults, myOnLoadError);

/** 
*@author 孙宇
* 
* @requires jQuery,EasyUI
* 
* 为datagrid、treegrid增加表头菜单，用于显示或隐藏列，注意：冻结列不在此菜单中
*/
var createGridHeaderContextMenu = function (e, field) {
    e.preventDefault();
    var grid = $(this); /* grid本身 */
    var headerContextMenu = this.headerContextMenu; /* grid上的列头菜单对象 */
    if (!headerContextMenu) {
        var tmenu = $('<div style="width:100px;"></div>').appendTo('body');
        var fields = grid.datagrid('getColumnFields');
        for (var i = 0; i < fields.length; i++) {
            var fildOption = grid.datagrid('getColumnOption', fields[i]);
            if (!fildOption.hidden) {
                $('<div iconCls="ext-icon-tick" field="' + fields[i] + '"/>').html(fildOption.title).appendTo(tmenu);
            } else {
                $('<div iconCls="ext-icon-bullet_blue" field="' + fields[i] + '"/>').html(fildOption.title).appendTo(tmenu);
            }
        }
        headerContextMenu = this.headerContextMenu = tmenu.menu({
            onClick: function (item) {
                var field = $(item.target).attr('field');
                if (item.iconCls == 'ext-icon-tick') {
                    grid.datagrid('hideColumn', field);
                    $(this).menu('setIcon', {
                        target: item.target,
                        iconCls: 'ext-icon-bullet_blue'
                    });
                } else {
                    grid.datagrid('showColumn', field);
                    $(this).menu('setIcon', {
                        target: item.target,
                        iconCls: 'ext-icon-tick'
                    });
                }
            }
        });
    }
    headerContextMenu.menu('show', {
        left: e.pageX,
        top: e.pageY
    });
};
$.fn.datagrid.defaults.onHeaderContextMenu = createGridHeaderContextMenu;
$.fn.treegrid.defaults.onHeaderContextMenu = createGridHeaderContextMenu;

/**
* grid tooltip参数
* 
* @author 孙宇
*/
var gridTooltipOptions = {
    tooltip: function (jq, fields) {
        return jq.each(function () {
            var panel = $(this).datagrid('getPanel');
            if (fields && typeof fields == 'object' && fields.sort) {
                $.each(fields, function () {
                    var field = this;
                    bindEvent($('.datagrid-body td[field=' + field + '] .datagrid-cell', panel));
                });
            } else {
                bindEvent($(".datagrid-body .datagrid-cell", panel));
            }
        });

        function bindEvent(jqs) {
            jqs.mouseover(function () {
                var content = $(this).text();
                if (content.replace(/(^\s*)|(\s*$)/g, '').length > 5) {
                    $(this).tooltip({
                        content: content,
                        trackMouse: true,
                        position: 'bottom',
                        onHide: function () {
                            $(this).tooltip('destroy');
                        },
                        onUpdate: function (p) {
                            var tip = $(this).tooltip('tip');
                            if (parseInt(tip.css('width')) > 500) {
                                tip.css('width', 500);
                            }
                        }
                    }).tooltip('show');
                }
            });
        }
    }
};
/**
* Datagrid扩展方法tooltip 基于Easyui 1.3.3，可用于Easyui1.3.3+
* 
* 简单实现，如需高级功能，可以自由修改
* 
* 使用说明:
* 
* 在easyui.min.js之后导入本js
* 
* 代码案例:
* 
* $("#dg").datagrid('tooltip'); 所有列
* 
* $("#dg").datagrid('tooltip',['productid','listprice']); 指定列
* 
* @author 夏悸
*/
$.extend($.fn.datagrid.methods, gridTooltipOptions);

/**
* Treegrid扩展方法tooltip 基于Easyui 1.3.3，可用于Easyui1.3.3+
* 
* 简单实现，如需高级功能，可以自由修改
* 
* 使用说明:
* 
* 在easyui.min.js之后导入本js
* 
* 代码案例:
* 
* $("#dg").treegrid('tooltip'); 所有列
* 
* $("#dg").treegrid('tooltip',['productid','listprice']); 指定列
* 
* @author 夏悸
*/
$.extend($.fn.treegrid.methods, gridTooltipOptions);


/**
* @author 夏悸
* 
* @requires jQuery,EasyUI
* 
* 扩展tree，使其可以获取实心节点
*
$.extend($.fn.tree.methods, {
getCheckedExt: function (jq) {// 获取checked节点(包括实心)
var checked = $(jq).tree("getChecked");
var checkbox2 = $(jq).find("span.tree-checkbox2").parent();
$.each(checkbox2, function () {
var node = $.extend({}, $.data(this, "tree-node"), {
target: this
});
checked.push(node);
});
return checked;
},
getSolidExt: function (jq) {// 获取实心节点
var checked = [];
var checkbox2 = $(jq).find("span.tree-checkbox2").parent();
$.each(checkbox2, function () {
var node = $.extend({}, $.data(this, "tree-node"), {
target: this
});
checked.push(node);
});
return checked;
}
});
*/
/**
* @author 夏悸
* 
* @requires jQuery,EasyUI
* 
* 扩展tree，使其支持平滑数据格式

$.fn.tree.defaults.loadFilter = function (data, parent) {
var opt = $(this).data().tree.options;
var idFiled, textFiled, parentField;
if (opt.parentField) {
idFiled = opt.idFiled || 'id';
textFiled = opt.textFiled || 'text';
parentField = opt.parentField;
var i, l, treeData = [], tmpMap = [];
for (i = 0, l = data.length; i < l; i++) {
tmpMap[data[i][idFiled]] = data[i];
}
for (i = 0, l = data.length; i < l; i++) {
if (tmpMap[data[i][parentField]] && data[i][idFiled] != data[i][parentField]) {
if (!tmpMap[data[i][parentField]]['children'])
tmpMap[data[i][parentField]]['children'] = [];
data[i]['text'] = data[i][textFiled];
tmpMap[data[i][parentField]]['children'].push(data[i]);
} else {
data[i]['text'] = data[i][textFiled];
treeData.push(data[i]);
}
}
return treeData;
}
return data;
};
*/
/**
* @author 孙宇
* 
* @requires jQuery,EasyUI
* 
* 扩展treegrid，使其支持平滑数据格式
*/
$.extend($.fn.treegrid.defaults, {
    loadFilter: function (data, parentId) {
        var opt = $(this).data().treegrid.options;
        var idField, treeField, parentField;
        if (opt.parentField) {
            idField = opt.idField || 'id';
            treeField = opt.textField || 'text';
            parentField = opt.parentField || 'pid';
            var i, l, treeData = [], tmpMap = [];
            for (i = 0, l = data.length; i < l; i++) {
                tmpMap[data[i][idField]] = data[i];
            }
            for (i = 0, l = data.length; i < l; i++) {
                if (tmpMap[data[i][parentField]] && data[i][idField] != data[i][parentField]) {
                    if (!tmpMap[data[i][parentField]]['children'])
                        tmpMap[data[i][parentField]]['children'] = [];
                    data[i]['text'] = data[i][treeField];
                    tmpMap[data[i][parentField]]['children'].push(data[i]);
                } else {
                    data[i]['text'] = data[i][treeField];
                    treeData.push(data[i]);
                }
            }
            return treeData;
        }
        return data;
    }
});
/**
* @author 孙宇
* 
* @requires jQuery,EasyUI
* 
* 扩展combotree，使其支持平滑数据格式
*
$.fn.combotree.defaults.loadFilter = $.fn.tree.defaults.loadFilter;
*/
/**
* @author 孙宇
* 
* @requires jQuery,EasyUI
* 
* 创建一个模式化的dialog
* 
* @returns $.modalDialog.handler 这个handler代表弹出的dialog句柄
* 
* @returns $.modalDialog.xxx 这个xxx是可以自己定义名称，主要用在弹窗关闭时，刷新某些对象的操作，可以将xxx这个对象预定义好
*/
$.modalDialog = function (options) {
    if ($.modalDialog.handler == undefined) {// 避免重复弹出
        var opts = $.extend({
            title: '',
            width: 640,
            height: 480,
            modal: true,
            onClose: function () {
                $.modalDialog.handler = undefined;
                $(this).dialog('destroy');
            }
        }, options);
        opts.modal = true; // 强制此dialog为模式化，无视传递过来的modal参数
        return $.modalDialog.handler = $('<div/>').dialog(opts);
    }
};

/**
* 等同于原form的load方法，但是这个方法支持{data:{name:''}}形式的对象赋值
*/
$.extend($.fn.form.methods, {
    loadData: function (jq, data) {
        return jq.each(function () {
            load(this, data);
        });

        function load(target, data) {
            if (!$.data(target, 'form')) {
                $.data(target, 'form', {
                    options: $.extend({}, $.fn.form.defaults)
                });
            }
            var opts = $.data(target, 'form').options;

            if (typeof data == 'string') {
                var param = {};
                if (opts.onBeforeLoad.call(target, param) == false)
                    return;

                $.ajax({
                    url: data,
                    data: param,
                    dataType: 'json',
                    success: function (data) {
                        _load(data);
                    },
                    error: function () {
                        opts.onLoadError.apply(target, arguments);
                    }
                });
            } else {
                _load(data);
            }
            function _load(data) {
                var form = $(target);
                var formFields = form.find("input[name],select[name],textarea[name]");
                formFields.each(function () {
                    var name = this.name;
                    var value = jQuery.proxy(function () {
                        try {
                            return eval('this.' + name);
                        } catch (e) {
                            return "";
                        }
                    }, data)();
                    var rr = _checkField(name, value);
                    if (!rr.length) {
                        var f = form.find("input[numberboxName=\"" + name + "\"]");
                        if (f.length) {
                            f.numberbox("setValue", value);
                        } else {
                            $("input[name=\"" + name + "\"]", form).val(value);
                            $("textarea[name=\"" + name + "\"]", form).val(value);
                            $("select[name=\"" + name + "\"]", form).val(value);
                        }
                    }
                    _loadCombo(name, value);
                });
                opts.onLoadSuccess.call(target, data);
                $(target).form("validate");
            }

            function _checkField(name, val) {
                var rr = $(target).find('input[name="' + name + '"][type=radio], input[name="' + name + '"][type=checkbox]');
                rr._propAttr('checked', false);
                rr.each(function () {
                    var f = $(this);
                    if (f.val() == String(val) || $.inArray(f.val(), val) >= 0) {
                        f._propAttr('checked', true);
                    }
                });
                return rr;
            }

            function _loadCombo(name, val) {
                var form = $(target);
                var cc = ['combobox', 'combotree', 'combogrid', 'datetimebox', 'datebox', 'combo'];
                var c = form.find('[comboName="' + name + '"]');
                if (c.length) {
                    for (var i = 0; i < cc.length; i++) {
                        var type = cc[i];
                        if (c.hasClass(type + '-f')) {
                            if (c[type]('options').multiple) {
                                c[type]('setValues', val);
                            } else {
                                c[type]('setValue', val);
                            }
                            return;
                        }
                    }
                }
            }
        }
    }
});
/**
* 扩展combobox在自动补全模式时，检查用户输入的字符是否存在于下拉框中，如果不存在则清空用户输入
* 
* @author 孙宇
* 
* @requires jQuery,EasyUI
*/
$.extend($.fn.combobox.defaults, {
    onShowPanel: function () {
        var _options = $(this).combobox('options');
        if (_options.mode == 'remote') {/* 如果是自动补全模式 */
            var _value = $(this).combobox('textbox').val();
            var _combobox = $(this);
            if (_value.length > 0) {
                $.post(_options.url, {
                    q: _value
                }, function (result) {
                    if (result && result.length > 0) {
                        _combobox.combobox('loadData', result);
                    }
                }, 'json');
            }
        }
    },
    onHidePanel: function () {
        var _options = $(this).combobox('options');
        if (_options.mode == 'remote') {/* 如果是自动补全模式 */
            var _data = $(this).combobox('getData'); /* 下拉框所有选项 */
            var _value = $(this).combobox('getValue'); /* 用户输入的值 */
            var _b = false; /* 标识是否在下拉列表中找到了用户输入的字符 */
            for (var i = 0; i < _data.length; i++) {
                if (_data[i][_options.valueField] == _value) {
                    _b = true;
                }
            }
            if (!_b) {/* 如果在下拉列表中没找到用户输入的字符 */
                $(this).combobox('setValue', '');
                $(this).combobox('reload', '');
            }
        }
    }
});
/**
* 扩展combogrid在自动补全模式时，检查用户输入的字符是否存在于下拉框中，如果不存在则清空用户输入
* 
* @author 孙宇
* 
* @requires jQuery,EasyUI
*/

//$.extend($.fn.combogrid.defaults, {
//    onShowPanel: function () {
//        var _options = $(this).combogrid('options');
//        if (_options.mode == 'remote') {/* 如果是自动补全模式 */
//            var _value = $(this).combogrid('textbox').val();
//            if (_value.length > 0) {
//                $(this).combogrid('grid').datagrid("load", {
//                    q: _value
//                });
//            }
//        }
//    },
//    onHidePanel: function () {
//        var _options = $(this).combogrid('options');
//        if (_options.mode == 'remote') {/* 如果是自动补全模式 */
//            var _data = $(this).combogrid('grid').datagrid('getData').rows; /* 下拉框所有选项 */
//            var _value = $(this).combogrid('getValue'); /* 用户输入的值 */
//            var _b = false; /* 标识是否在下拉列表中找到了用户输入的字符 */
//            for (var i = 0; i < _data.length; i++) {
//                if (_data[i][_options.idField] == _value) {
//                    _b = true;
//                }
//            }
//            if (!_b) {/* 如果在下拉列表中没找到用户输入的字符 */
//                $(this).combogrid('setValue', '');
//            }
//        }
//    }
//});
/**
*
* @requires jQuery,EasyUI
* 
* 扩展validatebox，添加验证两次密码功能
*/
$.extend($.fn.validatebox.defaults.rules, {
    CHS: {
        validator: function (value, param) {
            return /^[\u0391-\uFFE5]+$/.test(value);
        },
        message: '请输入汉字'
    },
    ZIP: {
        validator: function (value, param) {
            return /^[1-9]\d{5}$/.test(value);
        },
        message: '邮政编码不存在'
    },
    QQ: {
        validator: function (value, param) {
            return /^[1-9]\d{4,10}$/.test(value);
        },
        message: 'QQ号码不正确'
    },
    mobile: {
        validator: function (value, param) {
            return /^((\(\d{2,3}\))|(\d{3}\-))?13\d{9}$/.test(value);
        },
        message: '手机号码不正确'
    },
    loginName: {
        validator: function (value, param) {
            return /^[\u0391-\uFFE5\w]+$/.test(value);
        },
        message: '登录名称只允许汉字、英文字母、数字及下划线。'
    },
    safepass: {
        validator: function (value, param) {
            return safePassword(value);
        },
        message: '密码由字母和数字组成，至少6位'
    },
    equalTo: {
        validator: function (value, param) {
            return value == $(param[0]).val();
        },
        message: '两次输入的密码不一致'
    },
    number: {
        validator: function (value, param) {
            return /^\d+$/.test(value);
        },
        message: '请输入数字'
    },
    idcard: {
        validator: function (value, param) {
            return idCard(value);
        },
        message: '请输入正确的身份证号码'
    }
});
/* 密码由字母和数字组成，至少6位 */
var safePassword = function (value) {
    return !(/^(([A-Z]*|[a-z]*|\d*|[-_\~!@#\$%\^&\*\.\(\)\[\]\{\}<>\?\\\/\'\"]*)|.{0,5})$|\s/.test(value));
}
/*验证身份证号*/
var idCard = function (value) {
    if (value.length == 18 && 18 != value.length) return false;
    var number = value.toLowerCase();
    var d, sum = 0, v = '10x98765432', w = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2], a = '11,12,13,14,15,21,22,23,31,32,33,34,35,36,37,41,42,43,44,45,46,50,51,52,53,54,61,62,63,64,65,71,81,82,91';
    var re = number.match(/^(\d{2})\d{4}(((\d{2})(\d{2})(\d{2})(\d{3}))|((\d{4})(\d{2})(\d{2})(\d{3}[x\d])))$/);
    if (re == null || a.indexOf(re[1]) < 0) return false;
    if (re[2].length == 9) {
        number = number.substr(0, 6) + '19' + number.substr(6);
        d = ['19' + re[4], re[5], re[6]].join('-');
    } else d = [re[9], re[10], re[11]].join('-');
    if (!isDateTime.call(d, 'yyyy-MM-dd')) return false;
    for (var i = 0; i < 17; i++) sum += number.charAt(i) * w[i];
    return (re[2].length == 9 || number.charAt(17) == v.charAt(sum % 11));
}