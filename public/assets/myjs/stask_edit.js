var arrUsersId = [];
var checkedValues = [];

var table_show_list_user = $('#table_list_staff_stask').DataTable({
  "autoWidth": false,
  columnDefs: [{ targets: 'no-sort', orderable: false }],
  "language": {
      "lengthMenu": "_MENU_",
      "decimal": "",
      "emptyTable": noDataTable,
      "loadingRecords": loadingTable,
      "processing": "",
      "search": "_INPUT_",
      "info": "Hiển thị _END_ trên _TOTAL_ bản ghi",
      "infoEmpty": "Hiển thị _END_ trên _TOTAL_ bản ghi",
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
  paginate: false,
  "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-between align-items-center"i<"d-flex align-items-center"pl><"me-4">>',
  stateSave: true,
});

$('#form_delete').on('show.bs.modal', function (e) {
  var id_stask_asign = $(e.relatedTarget).attr('data-stask-id');
  var name_stask_asign = $(e.relatedTarget).attr('data-stask-name');
  var id_user_asign = $(e.relatedTarget).attr('data-user-id');
  $(this).find('#render_name').text(name_stask_asign);
  $(this).find('#delete_work_delete_form').attr('href', `/mywork/stask/del_work?id_stask=${id_stask_asign}&name_stask=${name_stask_asign}`);
});

$('.show_user_asign').click(function (e) {
  var id_stask_asign = $(this).attr('data-stask-id');
  $('#form_get_list_user_asign_stask').find('#id_stask_asgin').val(id_stask_asign);
  $('#form_get_list_user_asign_stask').submit();
  $('#loading_handle').css('display', 'flex');
});

$('#list_staff_stask').on('show.bs.modal', function (e) {
  var id_stask_asign = $(e.relatedTarget).attr('data-stask-id');
  $(this).find('#id_stask_del').val(id_stask_asign);
});

$('#list_staff_stask').on('hide.bs.modal', function (e) {
  table_show_list_user.clear().draw();
});

$('#submit_del_stask_user').click(function (e) {
  $('#ids_user_checked').val(checkedValues);
  $('#del_user_asign').submit();
});

function getListUserAsignStask(datas) {
  let tbody = $("#bulk-select-body");
  tbody.find("tr").remove();
  if (datas.length > 0) {
    arrUsersId = [];
    checkedValues = [];

    datas.forEach(item => {
      arrUsersId.push(item.id);
      table_show_list_user.row.add([
        `<div class="form-check mb-0">
            <input class="form-check-input checkbox_user_asign" name="check_box_user" type="checkbox" value="${item.id}" id="checkbox-1" data-bulk-select-row="data-bulk-select-row" />
        </div>`,
        item.full_name,
        item.email,
        item.department_name,
        item.job_name,
      ]).draw();
    })

    $('input[name="check_box_user"]').change(function () {
      if ($(this).is(':checked')) {
        checkedValues.push(parseInt($(this).val()));
        $('#submit_del_stask_user').prop('disabled', false);
      } else {
        var index = checkedValues.indexOf(parseInt($(this).val()));
        if (index > -1) {
          checkedValues.splice(index, 1);

        }
        if (checkedValues.length <= 0) {
          $('#submit_del_stask_user').prop('disabled', true);
        }
      }
    });

    $('input[data-bulk-select]').change(function () {
      if ($(this).is(':checked')) {
        checkedValues = arrUsersId;
        $('#submit_del_stask_user').prop('disabled', false);
        $('tbody#bulk-select-body input[name="check_box_user"]').each(function() {
          $(this).prop('checked', true);
        });
      } else {
        checkedValues = [];
        $('#submit_del_stask_user').prop('disabled', true);
        $('tbody#bulk-select-body input[name="check_box_user"]').each(function() {
          $(this).prop('checked', false);
        });
      }
    });
  }
  $('#loading_handle').css('display', 'none');
}