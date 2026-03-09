var optionTableNoFile = {
    "info": false,
    "autoWidth": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "search": "_INPUT_",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "order": [],
    lengthMenu: [
        [5, 10, 25, 50, 100],
        ["5", "10", "25", "50", "100"],
    ],
    pageLength: 25,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-center align-items-center"pl>',
    stateSave: true,
}
var optionTableNoFileWidth = {
    "info": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "search": "_INPUT_",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "order": [],
    lengthMenu: [
        [5, 10, 25, 50, 100],
        ["5", "10", "25", "50", "100"],
    ],
    pageLength: 5,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-center align-items-center"pl>',
    stateSave: true,
}
var optionTableNoFileBorder = {
    "info": false,
    "autoWidth": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "search": "_INPUT_",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "order": [],
    lengthMenu: [
        [5, 10, 25, 50, 100],
        ["5", "10", "25", "50", "100"],
    ],
    pageLength: 25,
    "dom": '<"top"Bf>r<"table-responsive scrollbar border-start"t><"mt-3 d-flex justify-content-center align-items-center"pl>',
    stateSave: true,
}
var optionTableFile = {
    "autoWidth": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "search": "_INPUT_",
        "info": "",
        "infoEmpty": "",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "fnInfoCallback": function(oSettings, iStart, iEnd, iMax, iTotal, sPre) {
        var page = Math.floor(iEnd / 2);
        var total = Math.floor(iTotal / 2);
        return "Hiển thị " + page + " trên " + total + " bản ghi ";
    },
    "order": [],
    lengthMenu: [
        [20, 50, 100],
        ["10", "25", "50"],
    ],
    pageLength: 20,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-between align-items-center"i<"d-flex align-items-center"pl><"me-4">>',
    stateSave: true,
}
var optionTableFileBorder = {
    "autoWidth": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "search": "_INPUT_",
        "info": "",
        "infoEmpty": "",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "fnInfoCallback": function(oSettings, iStart, iEnd, iMax, iTotal, sPre) {
        var page = Math.floor(iEnd / 2);
        var total = Math.floor(iTotal / 2);
        return "Hiển thị " + page + " trên " + total + " bản ghi ";
    },
    "order": [],
    lengthMenu: [
        [20, 50, 100],
        ["10", "25", "50"],
    ],
    pageLength: 20,
    "dom": '<"top"Bf>r<"table-responsive scrollbar border-start"t><"mt-3 d-flex justify-content-between align-items-center"i<"d-flex align-items-center"pl><"me-4">>',
    stateSave: true,
}



var optionTable = {
    "info": false,
    "autoWidth": false,
    paging: false,
    "searching": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "order": [],
    lengthMenu: [
        [5, 10, 25, 50, 100],
        ["5", "10", "25", "50", "100"],
    ],
    pageLength: 25,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-center align-items-center"pl>',
    stateSave: true,
}
var optionTableBorder = {
    "info": false,
    "autoWidth": false,
    paging: false,
    "searching": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "order": [],
    lengthMenu: [
        [5, 10, 25, 50, 100],
        ["5", "10", "25", "50", "100"],
    ],
    pageLength: 25,
    "dom": '<"top"Bf>r<"table-responsive scrollbar border-start"t><"mt-3 d-flex justify-content-center align-items-center"pl>',
    stateSave: true,
}
var optionTableStyle = {
    "autoWidth": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "infoFiltered": "",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": noDataTable,
        "loadingRecords": loadingTable,
        "processing": "",
        "search": "_INPUT_",
        "info": "",
        "infoEmpty": "",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        }
    },
    "order": [],
    lengthMenu: [
        [10, 25, 50],
        ["10", "25", "50"],
    ],
    pageLength: 10,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-between align-items-center"i<"d-flex align-items-center"pl><"me-4">>',
    stateSave: true,
}
$(document).ready(function() {
    $('#table_religions').DataTable(optionTable);
    $('#table_function').DataTable(optionTable);
    $('#table_notifies').DataTable(optionTable);
    $('#table_discipline').DataTable(optionTable);
    $('#table_acamedicrank').DataTable(optionTable);
    $('#table_review').DataTable(optionTableFileBorder);
    $('#table_holiday').DataTable(optionTableFileBorder);
    $('#archive_table').DataTable(optionTableFile);
    $('#table_addre').DataTable(optionTableFile);
    $('#table_task').DataTable(optionTableStyle);
    $('#table_identity').DataTable(optionTableFile);
    $('#table_contract').DataTable(optionTableFileBorder);
    $('#table_benefit').DataTable(optionTableFile);
    $('#positonjob_table').DataTable(optionTable);
    $('#table_appoint').DataTable(optionTable);
    $('#table_contracttime').DataTable(optionTableBorder);
    $('#table_ContractType').DataTable(optionTableStyle);
    $('#table_ContractTypes').DataTable(optionTable);
    $('#table_list_user_of_department').DataTable(optionTableStyle);
    $('#table_mediafile_department').DataTable(optionTableStyle);
    $('#table_department').DataTable(optionTable);
    $('#table_departmenttype').DataTable(optionTable);
    $('#table_education').DataTable(optionTableBorder);
    $('#table_ethnic').DataTable(optionTableBorder);
    $('#table_nationality').DataTable(optionTableBorder);
    $('#table_organization').DataTable(optionTableBorder);
    $('#table_permission').DataTable(optionTable);
    $('#positonjob').DataTable(optionTableStyle);
    $('#table_tbarchivetype').DataTable(optionTable);
    $('#table_tbarchivelevel').DataTable(optionTable);
    $('#table_tbdepartmenttypes').DataTable(optionTableBorder)
    $('#table_stask').DataTable(optionTable);
    $('#table_resource').DataTable(optionTableBorder);
    $('#table_tbhospitals').DataTable(optionTableBorder);
    $('#table_tbuserstatus').DataTable(optionTableBorder);
    $('#table_tbusertype').DataTable(optionTableBorder);
    $('#table_dashboard_new_staff').DataTable(optionTable);
    $('#table_dashboard_staff_liquidated').DataTable(optionTable);
    $('#table_dashboard_leadership').DataTable(optionTableNoFileWidth);
    $('#table_dashboard_staff_with_birthdays').DataTable(optionTable);
    $('#table_dashboard_interview_schedule').DataTable(optionTableNoFileWidth);
    $('#table_dashboard_staff_leave').DataTable(optionTable);
    $('#table_dashboard_salary_adjustment').DataTable(optionTableNoFileWidth);
    $('#table_tbbenefits').DataTable(optionTableBorder);
    $('#table_sbenefits').DataTable(optionTableStyle);
    $('#stable_permission_resource').DataTable(optionTableStyle);
    $('#table_mhistories').DataTable(optionTable);
    $('#table_benefits').DataTable(optionTableStyle);
    $('#table_benefit_other').DataTable(optionTableStyle);
    $('#documents_processed').DataTable(optionTableBorder);
    $('#documents_incoming').DataTable(optionTableBorder);
    $('#documents_outgoing').DataTable(optionTableBorder);
    $('#table_mandocbook').DataTable(optionTableNoFileBorder);
    $('#table_mandoctype').DataTable(optionTableNoFileBorder);
    $('#table_mandocpriority').DataTable(optionTableNoFileBorder);
    $('#table_mandocfrom').DataTable(optionTableNoFileBorder);
    $('#table_form').DataTable(optionTableBorder);
    $('#documents_released_incoming').DataTable(optionTableBorder);
    $('#documents_released_outgoing').DataTable(optionTableBorder);
    $('#table_work_leader').DataTable(optionTableStyle);
    $('#table_work_user').DataTable(optionTableStyle);
    $('#table_new_user').DataTable(optionTableStyle);
    $('#table_singnature').DataTable(optionTableStyle);
    $('#documents_pending').DataTable(optionTableStyle);

    $('#table_add_staff_stask').DataTable(optionTableStyle);
    $('#table_mandoc_search').DataTable({...optionTable,...{searching: false,paging: false,info:false}});
    $(".dataTables_length label select").removeAttr('class');
    $(".dataTables_length label select").attr('class', '');
    $('.dataTables_length label select').addClass("btn btn-sm btn-outline-primary dropdown-toggle");
    $('.pagination').addClass("pagination-sm");
});