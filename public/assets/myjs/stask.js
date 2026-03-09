// Thêm công việc kiêm nhiệm
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
  "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-between align-items-center"i<"d-flex align-items-center"pl><"me-4">>',
  stateSave: true,
});

$('input[name="check_box_user"]').change(function () {
  if ($(this).is(':checked')) {
    checkedValues.push(parseInt($(this).val()));
    $('#submit_asign_stask_user').prop('disabled', false);
  } else {
    var index = checkedValues.indexOf(parseInt($(this).val()));
    if (index > -1) {
      checkedValues.splice(index, 1);
    }
    if (checkedValues.length <= 0) {
      $('#submit_asign_stask_user').prop('disabled', true);
    }
  }
});

$('input[data-bulk-select]').change(function () {
  if ($(this).is(':checked')) {
    checkedValues = arrUsersId;
    $('#submit_asign_stask_user').prop('disabled', false);
  } else {
    checkedValues = [];
    $('#submit_asign_stask_user').prop('disabled', true);
  }
});

$('#submit_asign_stask_user').click(function (e) {
  $('#ids_user_checked').val(checkedValues);
  $('#asign_stask_user').submit();

});

$('#add_staff_stask').on('show.bs.modal', function (e) {
  var id_stask_asign = $(e.relatedTarget).attr('data-stask-id');
  var name_stask_asign = $(e.relatedTarget).attr('data-stask-name');
  var created_by_stask_asign = $(e.relatedTarget).attr('data-stask-created-by');
  $(this).find('.id_stask_asign').val(id_stask_asign);
  $(this).find('.render_name_stask').text(name_stask_asign);
  $(this).find('.render_created_by').text(created_by_stask_asign);
});

$('#list_staff_stask').on('hide.bs.modal', function (e) {
  table_show_list_user.clear().draw();
});

$('.show_user_asign').click(function (e) {
  var id_stask_asign = $(this).attr('data-stask-id');
  $('#form_get_list_user_asign_stask').find('#id_stask_asgin').val(id_stask_asign);
  $('#form_get_list_user_asign_stask').submit();
  $('#loading_handle').css('display', 'flex');
});

function getListUserAsignStask(datas) {
  let tbody = $("#render_list_staff_stask");
  tbody.find("tr").remove();
  if (datas.length > 0) {
    datas.forEach(item => {
      table_show_list_user.row.add([
        item.full_name,
        item.email,
        item.department_name,
        item.job_name,
      ]).draw();
    })
  }
  $('#loading_handle').css('display', 'none');
}
// Thêm công việc kiêm nhiệm

function addPermision(stask_id, resource_id, list_permissions_id) {
  document.getElementById("resource_id").value = resource_id;
  document.getElementById("stask_id").value = stask_id;

  let checkboxs = $("#select_add_permission_bd input")
  for (let i = 0; i < checkboxs.length; i++) {
    const element = checkboxs[i];
    element.checked = list_permissions_id.includes(element.value);
  }


}
function addResource(stask_id, list_resource_name) {
  document.getElementById("stask_id_add").value = stask_id;
  let selectElement = document.getElementById("select_resource");
  let options = selectElement.options;
  for (let i = 0; i < options.length; i++) {
    const option = options[i];
    option.disabled = i > 0 && list_resource_name.includes(option.value);

  }
}
document.getElementById('btn_add_permission').onclick = function () {
  document.getElementById('btn_add_permission').type = "submit";

}
document.getElementById("select_resource").addEventListener("change", function () {
  var error_label = document.getElementById('erro_labble_content_btn_add_resource');
  var error_select_resource = document.getElementById('select_resource');
  error_label.style.display = "none";
  error_select_resource.style.border = "1px solid #ced4da";
});
document.getElementById('select_add_permission_bd').onclick = function () {
  var error_label = document.getElementById('erro_labble_content_btn_add_permission');
  error_label.style.display = "none";
}
document.getElementById('btn_add_resource').onclick = function () {
  var error_label = document.getElementById('erro_labble_content_btn_add_resource');
  var select_resource = document.getElementById('select_resource').value;
  var error_select_resource = document.getElementById('select_resource');
  if (select_resource == "") {
    error_label.innerHTML = PLease_choose_resource;
    error_label.style.display = "block";
    error_select_resource.style.border = "1px solid red";
    return;
  } else {
    document.getElementById('btn_add_resource').type = "submit";
  }
}
const addPermisionModal = document.getElementById('add_permission_modal')
addPermisionModal.addEventListener('hidden.bs.modal', event => {
  // clean multi select value:
  $("#select_add_permission_bd input:checked").prop("checked", false);
});

function getTextToASCII() {
  var value_resource_url = document.getElementById("stask_name").value;
  var value_resource_scode = document.getElementById("stask_scode");
  if (value_resource_url) {
    var content = removeVietnameseTones(value_resource_url).replace(/ /g, '-');
    content = content.replace('---', '-');
    if (value_resource_scode) {
      value_resource_scode.value = content.toUpperCase()
    }
  }
}
function removeVietnameseTones(str) {
  str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a");
  str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e");
  str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i");
  str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o");
  str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u");
  str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y");
  str = str.replace(/đ/g, "d");
  str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
  str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
  str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
  str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
  str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
  str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
  str = str.replace(/Đ/g, "D");
  // Some system encode vietnamese combining accent as individual utf-8 characters
  // Một vài bộ encode coi các dấu mũ, dấu chữ như một kí tự riêng biệt nên thêm hai dòng này
  str = str.replace(/\u0300|\u0301|\u0303|\u0309|\u0323/g, ""); // ̀ ́ ̃ ̉ ̣  huyền, sắc, ngã, hỏi, nặng
  str = str.replace(/\u02C6|\u0306|\u031B/g, ""); // ˆ ̆ ̛  Â, Ê, Ă, Ơ, Ư
  // Remove extra spaces
  // Bỏ các khoảng trắng liền nhau
  str = str.replace(/ + /g, " ");
  str = str.trim();
  // Remove punctuations
  // Bỏ dấu câu, kí tự đặc biệt
  str = str.replace(/!|@|%|\^|\*|\(|\)|\+|\=|\<|\>|\?|\/|,|\.|\:|\;|\'|\"|\&|\#|\[|\]|~|\$|_|`|-|{|}|\||\\/g, " ");
  return str;
}
var error_label = document.getElementById('erro_labble_content');
function openFormAddStask() {
  // document.getElementById("form-add-stask-container").style.display = "block";
  document.getElementById("cls_bmtu_form_add_title").innerHTML = New_stask;
  document.getElementById("btn_add_new_stask").value = New_stask;
  document.getElementById("stask_id_form").value = "";
  document.getElementById("stask_name").value = "";
  document.getElementById("stask_scode").value = "";
  document.getElementById("stask_desc").value = "";
  document.getElementById("stask_name").addEventListener("keyup", function () { getTextToASCII() });

  // check user create by in department 
  $('#created_by').val(user_email);
  $('#created_by').trigger('change');
}
function closeFormAdd() {
  document.getElementById("form-add-stask-container").style.display = "none";
  document.getElementById("stask_id_form").value = "";
  document.getElementById("stask_name").value = "";
  document.getElementById("stask_scode").value = "";
  document.getElementById("stask_desc").value = "";
  document.getElementById("created_by").value = "";
  document.getElementById("stask_name").addEventListener("keyup", function () { });
}
function openFormUpdateStask(id, name, scode, desc, status, createby) {
  // document.getElementById("form-add-stask-container").style.display = "block";
  document.getElementById("cls_bmtu_form_add_title").innerHTML = Update_task;
  document.getElementById("btn_add_new_stask").value = Update_task;
  document.getElementById("stask_id_form").value = id;
  document.getElementById("stask_name").value = name;
  document.getElementById("stask_name").addEventListener("keyup", function () { });
  document.getElementById("stask_scode").value = scode;
  document.getElementById("stask_desc").value = desc;
  // check user create by in department 
  $('#created_by').val(createby);
  $('#created_by').trigger('change');

  if (status == "ACTIVE") {
    document.getElementById("sel_status_active").checked = true;
  }
  else {
    document.getElementById("sel_status_inactive").checked = true;
  }
}
var btn_add_new_stask = document.getElementById("btn_add_new_stask");
if (btn_add_new_stask) {
  btn_add_new_stask.addEventListener("click", function () {
    document.getElementById("btn_add_new_stask").style.display = "none";
    document.getElementById("loading_button_stasks").style.display = "block";
  });
}

$('#select_resource').select2({
  theme: "bootstrap-5",
  placeholder: 'Vui lòng chọn tài nguyên',
  width : 'resolve'
});
 
function deleteAllSelected(id) {
  var selectedValues = [];
  $(`#select-access-${id}:checked`).each(function() {
    selectedValues.push($(this).data('select-row'));
  });
  console.log(selectedValues);
}

  // Xử lý sự kiện khi checkbox "bulk-select-<%= stask.id %>" thay đổi
  $(document).on("change", "[id^='bulk-select-']", function () {
    let staskId = $(this).attr("id").replace("bulk-select-", ""); // Lấy ID thực tế
    let isChecked = $(this).prop("checked");
    
    // Chọn tất cả checkbox trong tbody tương ứng
    $("#bulk-select-body-" + staskId + " input[type='checkbox']").prop("checked", isChecked);
  });

  // Xử lý sự kiện khi checkbox trong bảng thay đổi
  $(document).on("change", "[id^='select-access-']", function () {
    let staskId = $(this).closest("tbody").attr("id").replace("bulk-select-body-", ""); // Lấy ID của bảng
    let totalCheckboxes = $("#bulk-select-body-" + staskId + " input[type='checkbox']").length;
    let checkedCheckboxes = $("#bulk-select-body-" + staskId + " input[type='checkbox']:checked").length;

    // Nếu tất cả checkbox được chọn, cũng chọn "bulk-select"; ngược lại thì bỏ chọn
    $("#bulk-select-" + staskId).prop("checked", totalCheckboxes === checkedCheckboxes);
  });