<%@ Page Language="C#" %>

<%--稽核待办事项——报表统计--%>
<script type="text/javascript">
    $(function () {
        $.post('../service/Portal.ashx/Auditor_GetReportAndNotice',
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
