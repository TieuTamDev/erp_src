/** PHAN DEPARTMENT */
var arrUsser = [];
let mediaFormLeader = null;
// Get the current date and time
var currentDate = new Date();
// Add 15 days to the current date
currentDate.setDate(currentDate.getDate() + 15);
// Format the date as needed
var year = currentDate.getFullYear();
var month = (currentDate.getMonth() + 1).toString().padStart(2, '0'); // Months are zero-based
var day = currentDate.getDate().toString().padStart(2, '0');
var staffDeadLine = day + '/' + month + '/' + year;

if(document.querySelector("#media-form-leader") != null){
  mediaFormLeader = new FormMedia("media-form-leader");
  mediaFormLeader.setIconPath(root_path_mandoc+'assets/image/');
  mediaFormLeader.showDeleteButton(false);
  mediaFormLeader.showLabelAdd(false);
  mediaFormLeader.init();
  mediaFormLeader.setTranslate(media_trans);
}
$(document).ready(function() {
  if(current_tab_in == "tab_2"){
    document.getElementById("man_in_tab_1").classList.remove("show");
    document.getElementById("man_in_tab_1").classList.remove("active");
    document.getElementById("page_documents_processed").classList.remove("active");
    document.getElementById("page_process_2").classList.add("active");
    document.getElementById("page_process_2").classList.add("show");
    document.getElementById("man_in_tab_2").classList.add("active");
    $("#li_in_tab_2").click();
  }else if(current_tab_in == "tab_3") {
    document.getElementById("man_in_tab_1").classList.remove("show");
    document.getElementById("man_in_tab_1").classList.remove("active");
    document.getElementById("page_documents_processed").classList.remove("active");
    document.getElementById("page_pending_in").classList.add("active");
    document.getElementById("page_pending_in").classList.add("show");
    document.getElementById("man_in_tab_3").classList.add("active");
  }
  $('[data-toggle="tooltip"]').tooltip({
    delay: { "show": 100, "hide": 100 }
  });
  $('#table_show_user_chosse').find('tr').length == 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $("#form_add_document_infor #sno").change(function() {
    var err_add= $('#err_add');
    var sno= $('#sno').val();
    if (sno == "") {
      $('#sno').css("border", "1px solid red");
      err_add.css("display", "block ");
      err_add.html(blank_sno);
    }else{
      $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
      err_add.css("display", "none ");
    }
  });
  $("#form_add_document_infor #contents").change(function() {
    var err_add= $('#err_add');
    var contents= $('#contents').val();
    if (contents === "") {
      $('#contents').css("border", "1px solid red");
      err_add.css("display", "block");
      err_add.html(blank_contents_vaild);
    }else{
      $('#contents').css("border", "1px solid var(--falcon-input-border-color)");
      err_add.css("display", "none");

    }
  });
});
$( ".datepicker" ).datepicker({
  showButtonPanel: true,
  dateFormat: "dd/mm/yy",
  changeMonth: true,
  changeYear: true,
  yearRange: "c-100:c+10",
  dayNamesMin : [ "S", "M", "T", "W", "T", "F", "S" ],
  // defaultDate: +1,
  buttonImageOnly: true,
  buttonImage: datepicker_buttonImage,
  showOn: "button",
  buttonText: Choose_date,
  closeText: closeText,
  prevText: prevText,
  nextText: nextText,
  currentText: currentText,
  monthNamesShort: [Jan, Feb, Mar, Apr,
  May, Jun, Jul, Aug,
  Sep, Oct, Nov, Dec],
  dayNamesMin: [Mon, Tue, Wed, Thu,
  Fri, Sat, Sun],
  firstDay: 1,
  isRTL: false,
  showMonthAfterYear: false,
  yearSuffix: "",
  startDate: new Date(),
  endDate:""
});

let datePick_arr = [];



function initDatePicker(){
  document.querySelectorAll("#form_assign_user [data-user-dealine]").forEach(item=>{
    var picker = flatpickr(item,{
      minDate:new Date(),
      dateFormat: "d/m/Y"
    });
    picker.setDate(new Date());
    datePick_arr.push(picker);
  
  })
}

function initDatePickerUserHandle(){
  document.querySelectorAll("#form_assign_user table tbody input.openemr-datepicker").forEach(item=>{
    var picker = flatpickr(item,{
      minDate:new Date(),
      dateFormat: "d/m/Y",
    });
    picker.setDate(staffDeadLine);
    datePick_arr.push(picker);
  
  })
}

function initDatePickerChosses(){
  document.querySelectorAll("#modal_chosses_staff input#dt_issued_date_dealine").forEach(item=>{
    var picker = flatpickr(item,{
      minDate:new Date(),
      dateFormat: "d/m/Y"
    });
    picker.setDate(new Date());
  })
}
var userOptions = utils.getData(document.querySelector("#department_help_ids"), 'options');
let choices_department = new window.Choices(document.querySelector("#department_help_ids"), _objectSpread({
itemSelectText: ''
}, userOptions));

reloadChoices();
initDatePicker();
initDatePickerChosses();

// on change select department
$("#department_id").on('change',(e)=>{
    reloadChoices();
})

$("#btn_add_staff").on("click",function(){
  $('#modal_chosses_staff').modal('show');   
  var arrUserId = [];
  $("#table_show_user_chosse").find("tr").each(function() {
    var trId = $(this).attr("id");
     arrUserId.push(trId);
  }); 
  var newArray = $.map(arrUserId, function(item) {
  // Use a regular expression to extract the number from each string
  var matches = item.match(/\d+/);  
  // Check if there is a match (number) in the string
    if (matches) {
      return parseInt(matches[0]); // Convert the matched number to an integer and return it
    } else {
      return null; // Return null if no number is found in the string
    }
  });
  $('#select_chosses_staff option').each(function() {
    var optionValue = parseInt($(this).val());
    if (newArray.includes(optionValue)) {
      $(this).prop('disabled', true);
    } else {
      $(this).prop('disabled', false);
    }
  });
  var firstEnabledOption = $("#select_chosses_staff option:not(:disabled):first");  
  if (firstEnabledOption.length > 0) {
    firstEnabledOption.prop("selected", true);    
  }
  $("#select_chosses_staff").trigger("change");

  $("#dt_issued_date_dealine").val(staffDeadLine);
  flatpickr("#dt_issued_date_dealine", {
		dateFormat: "d/m/Y",		
	}).setDate(staffDeadLine);


  var allOptionsDisabled = $("#select_chosses_staff option:not(:disabled)").length === 0;  
  if (allOptionsDisabled) {
    $("#btn_save_staff_chosses").prop('disabled', true);
    $("#select_chosses_staff").val("").trigger("change");
  } else {
    $("#btn_save_staff_chosses").prop('disabled', false);
  }
});

$("#btn_save_staff_chosses").on("click",function(){
  var full_name_select = $( "#select_chosses_staff option:selected" ).text();
  var id_select = $('#select_chosses_staff').val();
  var srole_select = $('input[name="srole_chosses"]:checked').val();
  var dt_issued_date_dealine = $('#dt_issued_date_dealine').val();
  var content_process_chosses = $('#content_process_chosses').val();
  if (!arrUsser.includes(Number(id_select))) {
    arrUsser.push(Number(id_select));
    $('#form_assign_user table tbody').append(`
    <tr id="tr_id_${id_select}">
        <td class="align-middle" >${full_name_select}</td>
        <td class="align-middle">
          <div class="d-flex">
              <div class="">
                <input class="submit-get form-check-input-to-know" id="To_know_${id_select}" type="checkbox" data-id="${id_select}" name="srole[${id_select}]" onclick="checkClearRadioSrole('${id_select}')" value="DEBIET" ${srole_select.includes('DEBIET') ? 'checked' : '' } />
                <label class="form-check-label m-0" for="To_know_${id_select}">${DEBIET}</label>
              </div>
              <div class=" ms-3">
                <input class="submit-get radio-receive form-check-input" id="Receive_${id_select}" type="radio" data-id="${id_select}" onclick="checkDupliceSrole('${id_select}','#Receive_${id_select}')" name="srole[${id_select}]" value="XULY" ${srole_select.includes('XULY') ? 'checked' : '' } />
                <label class="form-check-label m-0" for="Receive_${id_select}">${XULY}</label>
              </div>
              <div class=" ms-3">
                <input class="submit-get form-check-input" id="PHOIHOPXL_${id_select}" type="radio" data-id="${id_select}" name="srole[${id_select}]" onclick="checkClearCheckboxSrole('${id_select}')" value="PHOIHOPXL" ${srole_select.includes('PHOIHOPXL') ? 'checked' : '' }/>
                <label class="form-check-label m-0" for="PHOIHOPXL_${id_select}">${PHOIHOPXL}</label>
              </div>
          </div>
        </td>
        <td class="align-middle">
          <div class="form-group">
              <div id="datepicker-container_${id_select}" class="datepicker-container" > 
                  <span style="position: relative;" class="outline-element-container"> 
                  <input id="dt_issued_date_dealine_${id_select}" type="text" name="deadline[${id_select}]" data-user-dealine="${id_select}" value="${dt_issued_date_dealine}" class="form-control openemr-datepicker input-textbox outline-element incorrect" objtype="7" maxlength="10" name="action_element" aria-label="Select Date"> 
                  <span class="correct-incorrect-icon"> </span>
                  </span>
                  <div id="datepicker" ></div>
                </div>
              </div>
        </td>
        <td class="p-0 align-middle">
          <textarea id="content_process" class="form-control" name="content[${id_select}]">${content_process_chosses}</textarea>
        </td>
        <td class="p-0 align-middle" style="text-align: center;">
          <span class="fas fa-trash text-danger" style="cursor: pointer;" onclick="removeUserChosses(${id_select})"></span>
        </td>
    </tr>
    `);
  }
  
  $('#modal_chosses_staff').modal('hide');
  $('#modal_chosses_staff').find('form').trigger('reset');
  $('#table_show_user_chosse').find('tr').length == 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);

  // checkDupliceSrole(id_select);
  $('#form_assign_user table tbody .radio-receive:checked').click();

  var deadLineId = "#dt_issued_date_dealine_" + id_select;
  var dtDeadLine = $(deadLineId).val();  
  flatpickr(deadLineId, {
		dateFormat: "d/m/Y",		
	}).setDate(dtDeadLine);

});


$("#btn_add_all_staff").on('click', function(){
  if (dataUsers.length > 0) {
    dataUsers.forEach(item=>{
      if (!arrUsser.includes(item.users.id)) {
        arrUsser.push(item.users.id);
        $('#form_assign_user table tbody').append(`
        <tr id="tr_id_${item.users.id}">
            <td class="align-middle" >${item.users.last_name + " " + item.users.first_name} (${item.positionjob})</td>
            <td class="align-middle">
              <div class="d-flex">
                  <div class="">
                    <input class="submit-get form-check-input-to-know" id="To_know_${item.users.id}" type="checkbox" data-id="${item.users.id}" name="srole[${item.users.id}]" onclick="checkClearRadioSrole('${item.users.id}')" value="DEBIET" checked />
                    <label class="form-check-label m-0" for="To_know_${item.users.id}">${DEBIET}</label>
                  </div>
                  <div class=" ms-3">
                    <input class="submit-get radio-receive form-check-input" id="Receive_${item.users.id}" type="radio" data-id="${item.users.id}" onclick="checkDupliceSrole('${item.users.id}','#Receive_${item.users.id}')" name="srole[${item.users.id}]" value="XULY"  />
                    <label class="form-check-label m-0" for="Receive_${item.users.id}">${XULY}</label>
                  </div>
                  <div class=" ms-3">
                    <input class="submit-get form-check-input" id="PHOIHOPXL_${item.users.id}" type="radio" data-id="${item.users.id}" name="srole[${item.users.id}]" onclick="checkClearCheckboxSrole('${item.users.id}')" value="PHOIHOPXL" />
                    <label class="form-check-label m-0" for="PHOIHOPXL_${item.users.id}">${PHOIHOPXL}</label>
                  </div>
              </div>
            </td>
            <td class="align-middle">
              <div class="form-group">
                  <div id="datepicker-container_${item.users.id}" class="datepicker-container" > 
                      <span style="position: relative;" class="outline-element-container"> 
                      <input id="dt_issued_date_dealine_${item.users.id}" type="text" name="deadline[${item.users.id}]" data-user-dealine="${item.users.id}" value="${staffDeadLine}" class="form-control openemr-datepicker input-textbox outline-element incorrect" objtype="7" maxlength="10" name="action_element" aria-label="Select Date"> 
                      <span class="correct-incorrect-icon"> </span>
                      </span>
                      <div id="datepicker" ></div>
                    </div>
                  </div>
            </td>
            <td class="p-0 align-middle">
              <textarea id="content_process" class="form-control" name="content[${item.users.id}]"></textarea>
            </td>
            <td class="p-0 align-middle" style="text-align: center;">
              <span class="fas fa-trash text-danger" style="cursor: pointer;" onclick="removeUserChosses(${item.users.id})"></span>
            </td>
        </tr>
        `);
      }
    })
  }
  $('#table_show_user_chosse').find('tr').length == 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  initDatePickerUserHandle();

});

// click preview mandoc
$(".preview-mandoc").on('click',(e)=>{
  let id = $(e.currentTarget).attr("data-id");
  viewMandoc(id);
})

function viewMandoc(id, fullname){
  callGetMandocRemote(id,"loadPreview", fullname);
  showLoadding(true);
}

/**
 * Show mandoc preview form controller
 * @param {} mandoc 
 * @returns 
 */
function loadPreview(mandoc,files = []){
  showLoadding(false);
  formMediaPreview.removeTableItemAll();
  mediaFormLeader.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  if(!mandoc){
    return;
  }
  $("#preview-contents").html(mandoc.contents);
  $("#preview-title").html(mandoc.contents);
  formMediaPreview.tableAddItems(files);
  $("#preview-modal").modal('show');
}

//preview media
const formMediaPreview = new FormMedia("preview-files");
formMediaPreview.setIconPath(root_path_mandoc+'assets/image/');
formMediaPreview.showDeleteButton(false);
formMediaPreview.showLabelAdd(false);
formMediaPreview.init();
formMediaPreview.setTranslate(media_trans);


function removeUserChosses(id) {
  if (confirm("Bạn có chắc chắn muốn xóa?")) {
    arrUsser = $.grep(arrUsser, function(value) {
      return value !== id;
    });
    $(`#tr_id_${id}`).remove();
  } 
  $('#table_show_user_chosse').find('tr').length == 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false); 
}

$('#xu_ly_process_DV').on('show.bs.modal', function (e) {
  arrUsser = [];
  $('#table_show_user_chosse').find('tr').remove();
  var mandoc_id = $(e.relatedTarget).attr('data-id');
  $(this).find('.mandoc_id_assign').val(mandoc_id);

  var mandoc_deadline = $(e.relatedTarget).attr('data-deadline');
  $(this).find('.mandoc_deadline').val(mandoc_deadline);

  var data_content = $(e.relatedTarget).attr('data-content'); 
  dcontents = decodeURIComponent(data_content).replace(/\+/g, ' ');
  $(this).find('#content_bgd').val(dcontents);
  $("textarea#content_bgd").prop("readonly", true);

  var id_dhandle = $(e.relatedTarget).attr('data-id-dhandle'); 
  $(this).find('#id_dhandle_dv').val(id_dhandle);


  datePick_arr.forEach(picker=>{
    picker.set("maxDate",mandoc_deadline);
  })
});
$('#xu_ly_user_assign').on('show.bs.modal', function (e) {
  var id_uhandle_user = $(e.relatedTarget).attr('data-uhandle-id'); 
  $(this).find('#id_uhandle_user').val(id_uhandle_user); 
  var content_uhandle_user = $(e.relatedTarget).attr('data-uhandle-contents'); 
  content_uhandle= decodeURIComponent(content_uhandle_user).replace(/\+/g, ' ');

  $(this).find('#content_department').val(content_uhandle); 
  $("textarea#content_department").prop("readonly", true);

});
$('#xu_ly_process_DV').on('hidden.bs.modal', function (e) {
  arrUsser = [];
  $('#table_show_user_chosse').find('tr').remove();
});
 
function close_modal_add(){
    $('#sno').val('');
    $('#ssymbol').val('');
    $('#signed_by').val('');
    $('#created_by').val('');
    $("#type_book").prop('selectedIndex', 0).val();
    $("#stype").prop('selectedIndex', 0).val();
    $("#spriority").prop('selectedIndex', 0).val();
    $("#dt_document_date").val(time_now);
    $('#slink').val('');
    $('#contents').val('');
    $('#notes').val('');
    $('#number_pages').val('');
    $('#err_add').css('display', 'none');
    document.getElementById("sno").setAttribute("data-sno-value", "");
    document.getElementById("stype").setAttribute("data-stype-value", "");
    formMediaMandocfile.removeTableItemAll();
    mediaFormLeader.removeTableItemAll();
    formMediaPreview.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    $('#signed_by').css("border", "1px solid var(--falcon-input-border-color)");
    $('#created_by').css("border", "1px solid var(--falcon-input-border-color)");
    $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
    $('#ssymbol').css("border", "1px solid var(--falcon-input-border-color)");
}
$("#add_doc").click( function(){
  var ds_ids_media = $('#form_add_document_infor input[name="media_ids[]"]').val();
  if (ds_ids_media == undefined) {
    if (confirm("Chưa có tập tin đính kèm, xác nhận thêm văn bản")) {
      add_docs();
    } else {
      return
    }
  } else {
    if (confirm("Bạn có chắc chắn muốn thêm văn bản ?")) {
      add_docs();
    }
  }
});
function add_docs(){
  formMediaPreview.removeTableItemAll();
  mediaFormLeader.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();

  var sno= $('#sno').val();
  var ssymbol=$('#ssymbol').val();
  var content = $('#contents').val();
  var signed_by=$('#signed_by').val();
  var created_by= $('#created_by').val();
  var err_add= $('#err_add');
  if (sno == "") {
    $('#sno').css('border','1px solid red');
    err_add.html(blank_sno);
    err_add.css("display" , "block");
  } else if(content == ""){
    $('#contents').css('border','1px solid red');
    err_add.html(blank_contents_vaild);
    err_add.css("display" , "block");
  }
  else {
    $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
    $('#contents').css("border", "1px solid var(--falcon-input-border-color)");
    var input_radio = $('input[data-radio="radio_option"]:checked');
    $("#form_add_document_infor input[name='media_ids[]']").remove();
    $("#form_add_document_infor input[name='option_media[]']").remove();
    for (let i = 0; i < input_radio.length; i++) {
      var parts = input_radio[i].value.split('-');
      var value = parts[1];
      $("#form_add_document_infor").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
      $("#form_add_document_infor").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
    }
    $("#form_add_document_infor").submit();
    $("#add_doc").css("display","none")
    $("#loading_button_add_doc").css("display","block")
  }
}

$("#user_handle").click(function(){ 
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#pending_document_user_process input[name='media_ids[]']").remove();
  $("#pending_document_user_process input[name='option_media[]']").remove();
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];

    $("#pending_document_user_process").append(`<input name="media_ids[]" value="${value}" style="display: none">`);

    $("#pending_document_user_process").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }
  $("#pending_document_user_process").submit();

})
function clickDeleteMandocfile(id,name){
    href_mandocfile_delete += `?id=${id}`;

    let html = `${mess_del}  <span style="font-weight: bold; color: red">${name}</span>?`
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href_mandocfile_delete,'get')
      }
    });
  
}

function deleteMandocfile(id){
    action += `?aid=${id}`;
    let link = document.createElement('a');
    link.setAttribute('data-action',"delete");
    link.setAttribute('href',action);
    link.click();
}

const formMediaMandocfile = new FormMedia("upload_file_mandocfile");
formMediaMandocfile.setIconPath(root_path_mandoc+'assets/image/');
formMediaMandocfile.setAction(mandocfile_upload_mediafile);
formMediaMandocfile.setTranslate(media_trans);
formMediaMandocfile.showDeleteButton(false);

formMediaMandocfile.init();

formMediaMandocfile.addEventListener("confirmdel",(data)=>{
  
});
formMediaMandocfile.addEventListener("upload_success",(data)=>{
  // đưa id media vào input media_ids của form mandocfile
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  $("#form_add_document_infor").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});
const formMediaMandocfileUser = new FormMedia("upload_file_mandocfile_user");
  formMediaMandocfileUser.setIconPath(root_path_mandoc+'assets/image/');
  formMediaMandocfileUser.setAction(mandocfile_upload_mediafile);
  formMediaMandocfileUser.setTranslate(media_trans);
  formMediaMandocfileUser.setEditStatus(true);

  formMediaMandocfileUser.showDeleteButton(false);

  formMediaMandocfileUser.init();
  formMediaMandocfileUser.addEventListener("upload_success",(data)=>{
  // đưa id media vào input media_ids của form mandocfile
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();

  $("#upload_file_mandocfile_user").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
  $("#form_gui_BLD_duyet").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)

    
//   for (let i = 0; i < input_radio.length; i++) {
//   $("#xu_ly_user_assign").append(`<input name="option_media[]" value = "${input_radio[i].value}" style="display: none"></input> `)
// }
});

function open_form_assign_leader_incoming(mandocid, received_at,effective_date,iddhandle) {
  $("#mandoc_id_leader_incoming").val(mandocid);
  $("#iddhandle").val(iddhandle);
  if (effective_date == ""){
      $("#deadline_mandocs_leader_incoming").val(received_at);
  }else {
      $("#deadline_mandocs_leader_incoming").val(effective_date);
  }
}

// datepicker
$(function () {
      $(".datepicker").on('keydown', function (e) {
          IsNumeric(this, e.keyCode);
      });
      var isShift = false;
      var seperator = "/";
      function IsNumeric(input, keyCode) {
          if (keyCode == 16) {
              isShift = true;
          }
          //Allow only Numeric Keys.
          if (((keyCode >= 48 && keyCode <= 57) || keyCode == 8 || keyCode <= 37 || keyCode <= 39 || (keyCode >= 96 && keyCode <= 105)) && isShift == false) {
              if ((input.value.length == 2 || input.value.length == 5) && keyCode != 8) {
                  input.value += seperator;
              }
              return true;
          }
          else {
              return false;
          }
      };
      $(".datepicker").keyup(function(e) {
        var datecheck = /^(?:(?:31(\/|-|\.)(?:0?[13578]|1[02]|(?:Jan|Mar|May|Jul|Aug|Oct|Dec)))\1|(?:(?:29|30)(\/|-|\.)(?:0?[1,3-9]|1[0-2]|(?:Jan|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.)(?:0?2|(?:Feb))\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.)(?:(?:0?[1-9]|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep))|(?:1[0-2]|(?:Oct|Nov|Dec)))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$/g;
        var textcheck = /[A-Za-z]/g;
        var special = /[!"`'#%&.,:;<>=@{}~\$\(\)\*\+\-\\\?\[\]\^\|]+/;
        var unikey = /^[a-zA-Z_ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵỷỹ]+$/;
           if (!datecheck.test(this.value))
            {
              this.value = this.value.replace(textcheck, '');
              this.value = this.value.replace(special, '');
              this.value = this.value.replace(unikey, '');
            }

            else {

            }

      });

});
// function openCheckMandoc(mandoc_id, uhandle_id) {
//   document.getElementById("mandoc_id_handle_user").value = mandoc_id;
//   document.getElementById("iduhandle_pb_handle_user").value = uhandle_id;
// }
function openFormUpdateMandocInCommingPending(button,id,type_book,sno,ssymbol,stype,contents,notes,slink,created_by,received_at,spriority,number_pages,sfrom) {
  $(button).tooltip('hide');
  $("#staticBackdrop").modal("show")
  document.getElementById("mandoc_id").value = id;
  document.getElementById("type_book").value = type_book;
  document.getElementById("sno").value = sno;
  document.getElementById("ssymbol").value = ssymbol;
  document.getElementById("stype").value = stype;
  document.getElementById("contents").value = contents;
  document.getElementById("notes").value = notes;
  document.getElementById("slink").value = slink;
  document.getElementById("created_by").value = created_by;
  document.getElementById("dt_document_date").value = received_at;
  document.getElementById("spriority").value = spriority;
  document.getElementById("number_pages").value = number_pages;
  document.getElementById("mdepartment").value = sfrom;

  document.getElementById("btn_add_doc_pending_in").style.display = "none";


    // start show filemedia list
    $.ajax({
      type: "GET",
      url: mandocs_process_user_process_path,
      data: { id_mandoc: id },
      dataType: "JSON",
      success: function (response) {
        console.log(response);
        mediaFormLeader.removeTableItemAll();
        formMediaPreview.removeTableItemAll();
        formMediaManfileFormDeXuatBLD.removeTableItemAll();
        formMediaManfile.removeTableItemAll();
        formMediaMandocfileUser.removeTableItemAll();
        formMediaMandocfile.removeTableItemAll();
        formMediaMandocfile.tableAddItems(response.docs);
      }
  });
//end

}
// check textarea 
function open_form_FormDeXuatBLD (mandoc_id, id_dhandler,VT_contents) {
  formMediaManfileFormDeXuatBLD.removeTableItemAll();
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  callGetMandocRemote(mandoc_id,"loadMediasFormDeXuatBLD");
  $("#mandoc_id_leader_incoming").val(mandoc_id);
  $("#iddhandle").val(id_dhandler);
  VT_contents = decodeURIComponent(VT_contents).replace(/\+/g, ' ');
  $("textarea#Propose_of_VT").val(VT_contents);
  $("textarea#Propose_of_VT").prop("readonly", true);
}

function openFormUpdateMandoc(id,type_book,sno,ssymbol,stype,slink,created_by,effective_date,received_at,spriority,sfrom,number_pages,contents,notes) {
  formMediaMandocfile.removeTableItemAll();
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  callGetMandocRemote(id,"loadMedias");
  $("#staticBackdropLabel_add").html("Sửa văn bản đến");
  document.getElementById("mandoc_id").value = id;
  document.getElementById("type_book").value = type_book;
  document.getElementById("sno").setAttribute("data-sno-value", sno);
  document.getElementById("sno").value = sno;
  document.getElementById("ssymbol").value = ssymbol;
  document.getElementById("stype").value = stype;
  document.getElementById("stype").setAttribute("data-stype-value", stype);

  document.getElementById("slink").value = slink;
  document.getElementById("created_by").value = created_by;
  document.getElementById("dt_document_date").value = effective_date;
  document.getElementById("dt_document").value = received_at;
  document.getElementById("spriority").value = spriority;
  document.getElementById("sfrom").value = sfrom;
  document.getElementById("number_pages").value = number_pages;
  document.getElementById("contents").value = contents;
  document.getElementById("notes").value = notes;
  // document.getElementById("btn_add_doc_pending_in").style.display = "none";
  $("#type_book").trigger("change");
  $("#stype").trigger("change");
  $("#spriority").trigger("change");
  $("#sfrom").trigger("change");
}
function open_form_assign_departments(mandocid, content,sfrom, received_at,effective_date, iduhandle, mdepartment, deadline) {
  // choices_department.removeActiveItems();
  $("#contents").val("");
  $("#iduhandle").val(iduhandle);
  $("#mandoc_id_dhandle").val(mandocid);
  $("#mandoc_dhandle_Proposal_of_the_TC-HC").html(content);
  $("#mandoc_dhandle_Proposal_of_the_TC-HC_in").val(content);
  if (deadline == ""){
      $("#deadline").val(received_at);
  }else {
      $("#deadline").val(deadline);
      $("#deadlines").val(deadline);
  }
  if (mdepartment != ""){
  $("#department_id").val(mdepartment);
  reloadChoices();
  }
}
function reloadChoices(){
    let selected_Id =  $("#department_id").val();
    let newSelectItems = [];
    $("#department_id option").each(function(){
        let value = $(this).val();
        let label = $(this).html();

        newSelectItems.push({
            value: value,
            label: label,
            disabled: value == selected_Id
        })
    });
    choices_department.removeActiveItemsByValue(selected_Id);
    choices_department.removeActiveItems();
    choices_department.clearChoices();
    choices_department.setChoices(newSelectItems);
}
/**
 * Submit remote form
 * @param {string} formId 
 * @param {Element} button 
 */
function clickRefreshOption(button,formId){
  let icon = $(button);
  icon.toggleClass("fa-spin",true);
  icon.css("pointer-events","none");
  icon.css("animation-duration","0.9s");
  icon.css("opacity",0.7);

  $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr('content'));
  $("#"+formId).submit();
}

/**
 * Get data from remote form submit
 * @param {Array} datas 
 */
function reloadMandocBook(datas){
  let button = $("#mandocbook-reload-btn");
  button.toggleClass("fa-spin",false);
  button.css({"pointer-events":"","opacity":'',"animation-duration":"0.9s"});
  if (datas.length > 0){
    let option = $("#type_book");
    option.find("option").remove();
    datas.forEach(item=>{
      option.append(`<option value="${item.name}">${item.name}</option>`);
    })
  }
}

/**
 * Get data from remote form submit
 * @param {Array} datas 
 */
function reloadMandocType(datas){
  let button = $("#mandoctype-reload-btn");
  button.toggleClass("fa-spin",false);
  button.css({"pointer-events":"","opacity":''});
  if (datas.length > 0){
    let option = $("#stype");
    option.find("option").remove();
    datas.forEach(item=>{
      option.append(`<option value="${item.name}">${item.name}</option>`);
    })
  }
}

/**
 * Get data from remote form submit
 * @param {Array} datas 
 */
function reloadMandocPriority(datas){
  let button = $("#mandocpriority-reload-btn");
  button.toggleClass("fa-spin",false);
  button.css({"pointer-events":"","opacity":''});
  if (datas.length > 0){
    let option = $("#spriority");
    option.find("option").remove();
    datas.forEach(item=>{
      option.append(`<option value="${item.name}">${item.name}</option>`);
    })
  }
}

/**
 * Get data from remote form submit
 * @param {Array} datas 
 */
function reloadMandocFrom(datas){
  let button = $("#mandocfrom-reload-btn");
  button.toggleClass("fa-spin",false);
  button.css({"pointer-events":"","opacity":''});
  if (datas.length > 0){
    let option = $("#sfrom");
    option.find("option").remove();
    datas.forEach(item=>{
      option.append(`<option value="${item.name}">${item.name}</option>`);
    })
  }
}




function reloadChoices(){
    let selected_Id =  $("#department_id").val();
    let newSelectItems = [];
    $("#department_id option").each(function(){
        let value = $(this).val();
        let label = $(this).html();

        newSelectItems.push({
            value: value,
            label: label,
            disabled: value == selected_Id
        })
    });
    choices_department.removeActiveItemsByValue(selected_Id);
    choices_department.removeActiveItems();
    choices_department.clearChoices();
    choices_department.setChoices(newSelectItems);

}

function get_form_by_scode(scode) {  
  document.getElementById("btn_next").click();
  $('#tab_1 , #tab_2').removeAttr('data-bs-target');
  $('#tab_1 , #tab_2').removeAttr('data-bs-toggle');
  if(scode == "FORM-ASSIGN-BLD"){
    document.getElementById("form_xu_ly_BGD").style.display = "block";
    document.getElementById("form_xu_ly_VT").style.display = "none";
    document.getElementById("form_xu_ly_phan_PB").style.display = "none";
    document.getElementById("open_form_assign_TCHC").style.display = "none";
    $('#card-footer').removeClass('d-none');
  }else if (scode == "FORM-ASSIGN-VT") {
    document.getElementById("form_xu_ly_BGD").style.display = "none";
    document.getElementById("form_xu_ly_phan_PB").style.display = "none";
    document.getElementById("form_xu_ly_VT").style.display = "block";
    document.getElementById("open_form_assign_TCHC").style.display = "none";
    $('#card-footer').removeClass('d-none');
  }
  else if (scode== "FORM-ASSIGN-TC-HC"){
    document.getElementById("form_xu_ly_BGD").style.display = "none";
    document.getElementById("form_xu_ly_phan_PB").style.display = "none";
    document.getElementById("form_xu_ly_VT").style.display = "none";
    document.getElementById("open_form_assign_TCHC").style.display = "block";
    $('#card-footer').removeClass('d-none');
  }  
  else{
    document.getElementById("form_xu_ly_BGD").style.display = "none";
    document.getElementById("form_xu_ly_phan_PB").style.display = "none";
    document.getElementById("form_xu_ly_VT").style.display = "none";
    document.getElementById("open_form_assign_TCHC").style.display = "none";
    $('#card-footer').removeClass('d-none');
  }
}

function reset_modal(){
  document.getElementById("btn_prev").click();
  document.getElementById("bootstrap-wizard-tab1").classList.add("active");
  document.getElementById("bootstrap-wizard-tab1").classList.add("show");
  document.getElementById("bootstrap-wizard-tab2").classList.remove("active");
  document.getElementById("bootstrap-wizard-tab2").classList.remove("show");
}

$("#btn_add_doc_pending_in").on("click",function(){
    $('#status_doc').val("PENDING");
    $("#pending_document_user_process").submit();
});


$("#btn_add_doc_pending_in_close").on("click",function(){

  $('#sno').val('');
  $('#ssymbol').val('');
  $('#created_by').val('');
  $("#type_book").prop('selectedIndex', 0).val();
  $("#stype").prop('selectedIndex', 0).val();
  $("#spriority").prop('selectedIndex', 0).val();
  $("#dt_document_date").val(time_now);
  $('#slink').val('');
  $('#contents').val('');
  $('#notes').val('');
  $('#number_pages').val('');

  $('#signed_by').css("border", "1px solid var(--falcon-input-border-color)");
  $('#created_by').css("border", "1px solid var(--falcon-input-border-color)");
  $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
  $('#ssymbol').css("border", "1px solid var(--falcon-input-border-color)");

});

$("#btn_add_doc_pending_in_exit").on("click",function(){

  $('#contents').css("border", "1px solid var(--falcon-input-border-color)");
  $('#status_doc').val("PENDING");
  $("#form_add_document_infor").submit();
  
});

function save_current_tab(current_tab_in){
  window.localStorage.setItem('current_tab_in', current_tab_in);
} 
var current_tab_in = window.localStorage.getItem('current_tab_in');


function get_mandoc_infor(button,mandoc_id, content, received_at,effective_date, uhandle_id, mdepartment, deadline,dhandle_id){
  $(button).tooltip('hide');
  $("#formchonxuly").modal("show");
  $("#contents").val("");
  $("#contents_TCHC").val("");
  $("#mandoc_id_dhandle").val(mandoc_id);
  $("#mandoc_id_leader_department").val(mandoc_id);
  $("#mandoc_dhandle_Proposal_of_the_TC-HC").html(content);
  $("#mandoc_dhandle_Proposal_of_the_TC-HC_in").val(content);
  if (deadline == ""){
      $("#deadline").val(received_at);
  }else {
      $("#deadline").val(deadline);
      $("#deadlines").val(deadline);
  }
  if (mdepartment != ""){
  $("#department_id").val(mdepartment);
  $("#department_id_TCHC").val(mdepartment);
    reloadChoices();
  }

  $("#mandoc_id_leader_incoming").val(mandoc_id);
  $("#iddhandle").val(dhandle_id);
  $("#iddhandle_department").val(dhandle_id);
  if (effective_date == ""){
      $("#deadline_mandocs_leader_incoming").val(received_at);
      $("#deadline_mandocs_department").val(received_at);
  }else {
      $("#deadline_mandocs_leader_incoming").val(effective_date);
      $("#deadline_mandocs_department").val(effective_date);
  }

  $("#iduhandle_pb").val(uhandle_id);
  $("#iduhandle_vt").val(uhandle_id);
  $("#iduhandle_tchc").val(uhandle_id);

  $("#mandoc_id_handle_department_incoming").val(mandoc_id);
  $("#deadline_mandocs_leader_incoming_2").val(deadline);

}
function openLeaderHandle(mandoc_id, content, received_at,effective_date, uhandle_id, mdepartment, deadline,dhandle_id,uhandle_last_contents,dhandle_last_id,dhandle_last_contents,dhandle_last_deadline,userIdNearEnd,showUnapproval){

  callGetMandocRemote(mandoc_id,"loadLeaderMedias");
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  showLoadding(true);
  $("#contents").val("");
  $("#mandoc_id_dhandle").val(mandoc_id);

  content = decodeURIComponent(content).replace(/\+/g, ' ');
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC").val(content);
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC").prop("readonly", true);
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC_in").val(content);
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC_in").prop("readonly", true);
  if (deadline == ""){
      $("#deadline").val(received_at);
  }else {
      $("#deadline").val(deadline);
      $("#deadlines").val(deadline);
  }
  if (mdepartment != ""){
  $("#department_id").val(mdepartment);
    reloadChoices();
  }

  $("#mandoc_id_leader_incoming").val(mandoc_id);
  $("#iddhandle").val(dhandle_id);
  if (effective_date == ""){
      $("#deadline_mandocs_leader_incoming").val(received_at);
  }else {
      $("#deadline_mandocs_leader_incoming").val(effective_date);
  }

  $("#iduhandle_pb").val(uhandle_id);
  $("#iduhandle_vt").val(uhandle_id);

  $("#mandoc_id_handle_department_incoming").val(mandoc_id);
  $("#deadline_mandocs_leader_incoming_2").val(deadline);

  // form data
  uhandle_last_contents = decodeURIComponent(uhandle_last_contents).replace(/\+/g, ' ');
  $("#modal-leader-handle textarea#contents_handle_user").val(uhandle_last_contents);
  $("#modal-leader-handle textarea#contents_handle_user").prop("readonly", true);
  let btnUnapproval = $("#modal-leader-handle .btn-unapproval");
  if(showUnapproval){
    btnUnapproval.show();
    btnUnapproval.attr("data-id",mandoc_id);
    btnUnapproval.attr("data-content",dhandle_last_contents);
    btnUnapproval.attr("data-id-dhandle",dhandle_last_id);
    btnUnapproval.attr("data-deadline",dhandle_last_deadline);
  }else{
    btnUnapproval.hide();
    btnUnapproval.attr("data-id",'');
    btnUnapproval.attr("data-content",'');
    btnUnapproval.attr("data-id-dhandle",'');
    btnUnapproval.attr("data-deadline",'');
  }

  $("#mandoc_id_duyet").val(mandoc_id);
  $("#id_uhandle_duyet").val(uhandle_id);
  $("#chosses_leader_department_select").val(userIdNearEnd);

 
}
const formMediaManfileFormDeXuatBLD = new FormMedia("upload_file_form_De_Xuat_BLD");
formMediaManfileFormDeXuatBLD.setIconPath(root_path_mandoc+'assets/image/');
formMediaManfileFormDeXuatBLD.setAction(mandocfile_upload_mediafile);
formMediaManfileFormDeXuatBLD.setTranslate(media_trans);
formMediaManfileFormDeXuatBLD.showDeleteButton(false);
formMediaManfileFormDeXuatBLD.showLabelAdd(false);
formMediaManfileFormDeXuatBLD.init();



const formMediaManfile = new FormMedia("upload_mandoc_file");
formMediaManfile.setIconPath(root_path_mandoc+'assets/image/');
formMediaManfile.setAction(mandocfile_upload_mediafile);
formMediaManfile.setTranslate(media_trans);
formMediaManfile.showDeleteButton(false);
formMediaManfile.showLabelAdd(false);


formMediaManfile.init();

function clickEditMandocMedias(mandoc_id){
  showLoadding(true);
  callGetMandocRemote(mandoc_id,"loadMandocFile");
  formMediaManfile.removeTableItemAll();
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
}
/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadLeaderMedias(mandoc,files){
  showLoadding(false);
  if(mandoc){
    mediaFormLeader.removeTableItemAll();
    formMediaPreview.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    $('#modal-leader-handle').modal("show");
    mediaFormLeader.tableAddItems(files);
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
  }else{
    // TODO: show error
  }
}
/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMedias(mandoc,files){
  showLoadding(false);
  if(mandoc){
    mediaFormLeader.removeTableItemAll();
    formMediaPreview.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaMandocfile.tableAddItems(files);
  }else{
    // TODO: show error
  }
}
/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMediasFormDeXuatBLD(mandoc,files){
  showLoadding(false);
  if(mandoc){
    mediaFormLeader.removeTableItemAll();
    formMediaPreview.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.tableAddItems(files);
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
  }else{
    // TODO: show error
  }
}
/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMediasLeader(mandoc,files){
  showLoadding(false);
  if(mandoc){
    mediaFormLeader.removeTableItemAll();
    formMediaPreview.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    formMediaMandocfileUser.tableAddItems(files);
  }else{
    // TODO: show error
  }
  $('#table_file_upload_file_mandocfile_user tbody.list tr').each(function() {
    $(this).find('input[type="radio"]').prop('disabled', true);
  });
}
/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMandocFile(mandoc,files){
  showLoadding(false);
  if(mandoc){
    mediaFormLeader.removeTableItemAll();
    formMediaPreview.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaManfileFormDeXuatBLD.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    formMediaManfile.tableAddItems(files);
    $("#upload_mandoc_file_update").modal("show");
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
  }else{
    // TODO: show error
  }
}
function openFormAssign(id) {
  let button_id = "open_form_assign_" + id;
  let close_id = "btn_close_release_docs_" + id;

  document.getElementById(close_id).click();  
  document.getElementById(button_id).click();  
}

function releaseDocs() {
  $("#form_release_docs").submit();
}

function checkAllUserToKnow(isChecked) {
  if(isChecked) {
      $('#form_assign_user input[type="checkbox"]').each(function() { 
          this.checked = true; 
      });
      $('#form_assign_user input[type="radio"]').each(function() { 
        this.checked = false; 
      }); 
  } else {
      $('#form_assign_user input[type="checkbox"]').each(function() {
          this.checked = false;
      });
  }
}

/**
 * submit remote form with data
 * @param {string} mandoc_id 
 * @param {string} func_name name of func callback from controller
 */
function callGetMandocRemote(mandoc_id,func_name, fullname){
  $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr('content'));
  $('#get_mandoc_form [name="mandoc_id"]').val(mandoc_id);
  $('#get_mandoc_form [name="func_name"]').val(func_name);
  $('#get_mandoc_form [name="fullname"]').val(fullname);
  $("#get_mandoc_form").submit();
}

$("#li_in_tab_2").click(function() {
  var type = $("#submit_form_mandocs_status").attr("type");
  if (type=="submit"){
  $("#get_mandocs_status_in").submit();
  $("#loading_screen").css("display", "flex");  
  $("#submit_form_mandocs_status").attr("type", "button");
  } 
});

function choose_user(){
  $("#staticBackdropLabel_add").html("Thêm văn bản đến");
  $("#created_by").val(User_full_name);
  var type_book = "VAN-BAN-DEN";
  document.getElementById("type_book").value = type_book;
  $('#sno').val(value_sno)
  document.getElementById("mandoc_id").value = "";
  // var url = $('#stype').data('url');
  // var selectedStype = $('#stype').val();

  // $('#stype').change(function() {
  //   var selectedStype = $(this).val();
  //   var stypeInput = $('#stype');
  //   var initialStypeValue = stypeInput.attr("data-stype-value");
  //   var stypeVal = $('#stype').val()
  //   var snoInput = $('#sno');
  //   var initialSnoValue = snoInput.attr("data-sno-value");
  //   // Make an AJAX request to retrieve the count
  //   if (initialStypeValue == stypeVal) {
  //     $('#sno').val(initialSnoValue)
  //   } else {
  //     $.ajax({
  //       url: url,
  //       method: 'GET',
  //       data: { stype: selectedStype },
  //       success: function(response) {
  //         $('#sno').val(response.count); // Update the sno text field with the retrieved count
  //       },
  //       error: function() {
  //         console.log('Error occurred while fetching the count.');
  //       }
  //     });
  //   }
  // });
  // // Trigger the change event manually to fetch the initial value
  // $('#stype').trigger('change');
}

function clickDeleteMandoc(id,name){
  let href = `${action_del}`;
  href += `?id=${id}`;

  let html = `${mess_del_man} <span style="font-weight: bold; color: red">${name}</span>?`
  openConfirmDialog(html,(result )=>{
  if(result){
      doClick(href,'delete')
  }
  });

}

$( "#chosses_leader_department_btn" ).on( "click", function() {
  $('#chosses_leader_department').modal('show');
  $("#chosses_leader_department_select option:first").attr("selected", true);

  var assign_id = $('#chosses_leader_department_select').val();
  $('#assign_to_duyet').val(assign_id);


} );

$("#chosses_leader_department_select").on( "change", function() { 
  $("#chosses_leader_department_select option:first").attr("selected", true);
  var assign_id = $('#chosses_leader_department_select').val();
  $('#assign_to_duyet').val(assign_id);
} );


$( "#confirm_form_chosses_leader_department" ).on( "click", function() {
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#form_gui_BLD_duyet input[name='media_ids[]']").remove();
  $("#form_gui_BLD_duyet input[name='option_media[]']").remove();
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];
    $("#form_gui_BLD_duyet").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#form_gui_BLD_duyet").append(`<input name="option_media[]" value = "${input_radio[i].value}" style="display: none"></input> `)

  }
  $('#form_gui_BLD_duyet').submit();

  showLoadding(true);
} );

function openCheckMandocHandle(mandoc_id, uhandle_id, userIdNearEnd) {
  $("#mandoc_id_user").val(mandoc_id);
  $("#id_uhandle_user").val(uhandle_id);
  $("#id_user").val(userIdNearEnd);
  formMediaMandocfileUser.removeTableItemAll();
  mediaFormLeader.removeTableItemAll();
	formMediaPreview.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaManfileFormDeXuatBLD.removeTableItemAll();
	formMediaManfile.removeTableItemAll();
  callGetMandocRemote(mandoc_id, "loadMediasLeader");
  // lấy status của mediafile
}

$(document).on("click", ".click-back", function () {
  var mandoc_id_user = document.getElementById("mandoc_id_user").value;
  var id_uhandle_user = document.getElementById("id_uhandle_user").value;
  var id_user = document.getElementById("id_user").value;
  // get list media ids

  $("#mandoc_id_duyet").val(mandoc_id_user);
  $("#id_uhandle_duyet").val(id_uhandle_user);
  $("#assign_to_duyet").val(id_user);
  $("#chosses_leader_department_select").val(id_user);
  $("#chosses_leader_department_select").trigger("change");
})
function checkDupliceSrole(id,idRecive) {
  var selectedIds = $('.radio-receive').filter(':checked').map(function() {
      var idview = "#To_know_"+this.dataset.id;
      $(idview).prop('checked', false);
      return {
        id: "#"+this.id,
        data: this.dataset.id
      }
    }).get();
    for (let i = 0; i < selectedIds.length; i++) { 
      if (id != selectedIds[i].data && idRecive != selectedIds[i].id ) {
        var idview = "#To_know_"+selectedIds[i].data;
        $(selectedIds[i].id).prop('checked', false);
        $(idview).prop('checked', true);
      }
    } 
    $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
}

function checkClearRadioSrole(id) {
  $("#Receive_"+id).prop('checked', false);
  $("#PHOIHOPXL_"+id).prop('checked', false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
}
function checkClearCheckboxSrole(id) {
  $("#To_know_"+id).prop('checked', false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
}

$("#btn-submit-assign-user").on("click",function(){
  // var get_id = $('.submit-get').filter(':checked').map(function() {
  //   return this.dataset.id
  // }).get();
  // $('#user_id_assign').val(get_id);
  // $('#form_assign_user').submit();  
  $("#loading_handle").remove();
  var checkReceive =  $('#form_assign_user table tbody .radio-receive:checked').length;
  if (checkReceive > 0) {
    if (confirm("Xác nhận xử lý văn bản ?")) {
      var get_id = $('.submit-get').filter(':checked').map(function() {
        return this.dataset.id
      }).get();
      $('#user_id_assign').val(get_id);
      $('#form_assign_user').submit();
      $("#loading_screen").css("display", "flex");  
    } else {
      return
    }    
  }else {
    alert("Bạn chưa chọn nhân sự phòng xử lý văn bản")
  }

});
function openModal(element) {
  var target = $(element).data('target');
  $(target).modal('show');
}