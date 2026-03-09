var optionMexam = {
    "autoWidth": false,
    "language": {
        "info": "Tổng: _TOTAL_ tác vụ",
        "infoEmpty": "Không có mục nào để hiển thị",
        "infoFiltered": "(được lọc từ _MAX_ mục)",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": "Không có yêu cầu", 
        "processing": "",
        "searchPlaceholder": searchTable,
        "zeroRecords": noMatchingTable,
        "paginate": {
            "first": firstTable,
            "last": lastTable,
            "next": nextTable,
            "previous": previousTable
        },
        "search": ""
    },
    "order": [],
    lengthMenu: [
        [10, 25, 50, 100],
        ["10", "25", "50", "100"],
    ],
    pageLength: 10,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-between align-items-center"i<"d-flex align-items-center"pl><"me-4">>',
    searching: true,
    paging: true,
    info: true,
    "processing": true,
    "serverSide": true,
}; 

createTableMexam();
function createTableMexam() {
    let columns = [
        { 
            data: null, 
            render: function(data, type, tag, index) {
                return index.row + 1 
            },
            width: '2%'
        }, 
        { data: "title", width: '20%' },
        { data: "stype", width: '5%' },
        { data: "time_ago", width: '7%' },
    ];
    
    // Thêm cột "dtdeadline" nếu is_handle == true
    if (is_handle) {
        columns.push( 
            { 
                data: null, 
                render: function(data, type, notifie) { 
                    return `<span class="mb-0 ${notifie.deadline_color}"> ${notifie.dtdeadline}</span>`;
                },
                width: '7%'
            }
        );
    }
    
    columns = columns.concat([
        { data: "contents", width: '50%' },
        { 
            data: null, 
            render: function(data, type, notifie) { 
                return is_handle
                    ? `<a href="${ERP_PATH}notifies/render_modal/${notifie.id}?isShow=false" data-remote="true" class="btn btn-sm btn-primary">Xử lý</a>`
                    : `<span class="mb-0 ${notifie.isread_color}"> ${notifie.isread}</span>`;
            },
            width: '7%'
        }
    ]);

    table_notifies = $('#table_notifies').DataTable({...optionMexam,...{
        "ajax": {
            "url": gon.notifies_index_path,
            "type": "GET",
            "data": function (d) { 
                d.page = d.start / d.length + 1;
                d.per_page = d.length;
                if (d.order.length > 0) {
                    d.order_column = d.columns[d.order[0].column].data;
                    d.order_dir = d.order[0].dir;
                } 
                d.stype = $("#select_style").val() 
            }
        },
        columns: columns, 
        columnDefs: [
            { 
                targets: 'no-sort', 
                orderable: false 
            },
            {
                targets: [0],  
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', '#');
                },
                render: function (data, type, row, meta) {
					var pageInfo = $('#table_calendar_exam').DataTable().page.info(); 
					return meta.row + 1 + pageInfo.start;
				}
            },
            {
                targets: [1],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Tiêu đề');
                }
            },
            {
                targets: [2],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Loại');
                }
            },
            {
                targets: [3],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Thời gian');
                }
            },
            {
                targets: [3],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Nội dung');
                }
            }
        ],
        "drawCallback": function (settings) {
			var api = this.api();
			var pageInfo = api.page.info();
			api.column(0, { page: 'current' }).nodes().each(function (cell, i) {
				cell.innerHTML = i + 1 + pageInfo.start;
			});  
		},
        rowCallback: function(row, data, index) { 
            if (data.deadline_color) {
                $(row).addClass(data.deadline_color);
            }
        },
    }});
    if (is_handle) {
        table_notifies.columns << [{ 
            data: "dtdeadline",  
            width: '7%'
        }]
    }
    $('#table_notifies').on('xhr.dt', function(e, settings, json) {
        if (json && json.recordsTotal !== undefined) {
            totalRecords = json.recordsTotal;
        } else {
            totalRecords = 0; // Gán giá trị mặc định tránh lỗi
        }
    });
    $('#table_notifies_search').unbind().on('keyup', function() {
        clearTimeout(searchDelay);
        var searchValue = this.value;
        searchDelay = setTimeout(function() {
            table_notifies.search(searchValue).draw();
        }, 1000); // Độ trễ 1 giây
    });
    $('#select_style').on('change', function() { 
        table_notifies.ajax.reload();
    });
}

