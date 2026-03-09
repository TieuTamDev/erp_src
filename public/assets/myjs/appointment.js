var optionMexam = {
    "autoWidth": false,
    "language": {
        "info": "Hiển thị _START_ đến _END_ trên tổng số _TOTAL_ tác vụ",
        "infoEmpty": "Không có mục nào để hiển thị",
        "infoFiltered": "(được lọc từ _MAX_ mục)",
        "lengthMenu": "_MENU_",
        "decimal": "",
        "emptyTable": "Không có dữ liệu", 
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

function hexToRgba(hex, alpha = 1) {
    let r = parseInt(hex.slice(1, 3), 16);
    let g = parseInt(hex.slice(3, 5), 16);
    let b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function createTableMexam() {
    var appointment_table = $('#appointment_table').DataTable({...optionMexam,...{
        "ajax": {
            "url": gon.appointments_path,
            "type": "GET",
            "data": function (d) {
                d.page = d.start / d.length + 1;
                d.per_page = d.length;
                
                if (d.order.length > 0) {
                    d.order_column = d.columns[d.order[0].column].data
                    d.order_dir = d.order[0].dir;
                }
            }
        }, 
        columns: [
            { data: null, 
                render: function(data, type, tag, index) {
                    return index.row + 1 
                },
                width: '5%'
            },
            {
                data: "title",
                width: '55%',
                render: function (data, type, row) {
                    return `<strong style="text-decoration: underline;">${data}</strong>`;
                }
            },
            { 
                data: null, 
                render: function(data, type, appointment) { 
                    if (appointment.priority) {
                        const backgroundColor = hexToRgba(appointment.color_priority, 0.2);
                        const textColor = appointment.color_priority;
                
                        return `<span class="badges" style="background-color: ${backgroundColor}; color: ${textColor};">${appointment.priority}</span>`;
                    } else {
                        return `<span class="badges badges-pending" >Thấp</span>`;
                    }
                },
                width: '10%'
            },  
            { data: "user_handles", width: '20%'},                 
            { 
                data: null, 
                render: function(data, type, appointment) {  
                        return `<span class="badges ${appointment.result_color}" >${appointment.result}</span>`; 
                },
                width: '10%'
            }              
        ], 
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
					var pageInfo = $('#appointment_table').DataTable().page.info(); 
					return meta.row + 1 + pageInfo.start;
				}
            },
            {
                targets: [1],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Tên tác vụ');
                }
            },
            {
                targets: [2],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Độ khẩn');
                }
            },
            {
                targets: [3],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Đang xử lý');
                }
            },
            {
                targets: [4],
                createdCell: function (td, cellData, rowData, row, col) {
                    $(td).attr('data-label', 'Tình trạng');
                }
            }
            
        ],
        "drawCallback": function (settings) {
			var api = this.api();
			var pageInfo = api.page.info();
			api.column(0, { page: 'current' }).nodes().each(function (cell, i) {
				cell.innerHTML = i + 1 + pageInfo.start;
			});
		}
    }});  
    // Sự kiện click trên hàng của bảng để chuyển trang
    $('#appointment_table tbody').on('click', 'tr', function() {
        var data = appointment_table.row(this).data();
        var appointmentId = data.id; // Giả định trường ID là "id"
        if (appointmentId) {
            window.location.href = `${ERP_PATH}appointments/${appointmentId}`;
        } else {
            console.error('Không tìm thấy ID trong dữ liệu hàng:', data);
        }
    });

// Sự kiện search với độ trễ
    var searchDelay;
    $('#appointment_table_search').on('keyup', function() {
        clearTimeout(searchDelay);
        var searchValue = this.value;
        searchDelay = setTimeout(function() {
            appointment_table.search(searchValue).draw();
        }, 1000); // Độ trễ 1 giây
    });
}

createTableMexam()