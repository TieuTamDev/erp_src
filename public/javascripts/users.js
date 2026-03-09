$(document).ready(function () {
    var table_users = $('#table_users').DataTable({
        "fnDrawCallback": function () {
            // $('#example_filter').css("text-align", "right").focus();
            // $("input[type='search']").attr("id", "searchBox");
            $(".page-link").attr("id", "page-link");
            // $('#searchBox').css("margin-bottom", "4px").focus();

  
        },
        lengthChange: false,
        order: [[0, 'desc']],
        buttons: [{
            extend: 'print',
            text: 'Print'
        }, {
            extend: 'excel',
            text: 'Export Excel'
        }, {
            extend: 'pdf',
            text: 'Export PDF'
        }]
    });
    $('#table_users #users_tbody').off('click');

 

    table_users.buttons().container()
    .appendTo('#table_users_wrapper .col-md-6:eq(0)');
});