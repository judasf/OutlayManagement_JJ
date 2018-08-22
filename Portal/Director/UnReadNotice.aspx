<%@ Page Language="C#" %>

<%--处长待办事项——意见信箱--%>
<script type="text/javascript">
    $(function () {
        $.post('../service/Portal.ashx/Director_GetUnReadNotice',
            function (result) {
                if (result.rows && result.total > 0) {
                    var str = '';
                    $(result.rows).each(function (index) {
                        var val = result.rows[index];
                        str = $($.formatString('<li><a class="easyui-tooltip" title="{0}">{1}</a></li>', val.title, val.title)).appendTo($('#p2').find('ul'));
                        //解析组件
                        $.parser.parse(str);
                    });
                }
                else
                    $('#p2').find('ul').html('无待办事项');
            }, 'json');
    });
</script>
<ul>
</ul>
