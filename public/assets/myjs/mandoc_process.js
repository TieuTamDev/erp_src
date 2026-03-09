
function initTinymce(){
var tinymceOptions = {
    content_style: "p {margin: 0}",
    elementpath: false,
    paste_as_text: false,
    visual: true,
    table_default_attributes: {
        border: '0'
    },
    plugins: [
        'advlist', 'lists', 'preview', 'table', 'token', 'print'
    ],
    content_css: 'writer',
    toolbar1:'fontselect fontsizeselect| lineheight | bullist numlist | table | preview | print',
    toolbar2:'undo redo | bold italic underline strikethrough | forecolor backcolor removeformat| alignleft  aligncenter  alignright  alignjustify indent outdent',
    height : "500"
}

tinymce.init({
    ...{selector: '#mandoc_content_department'},
    ...tinymceOptions
});
tinymce.init({
    ...{selector: '#show_mandoc_content_department'},
    ...tinymceOptions
});

}

/**
 * 
 * @param {HTMLElement} element 
 */
 function clickCollapse(element){
    $(element).find('#collapse-icon').css("rotate",element.className.includes('collapsed') ? "unset" : "-90deg");
    // document.getElementById('collapse-icon').style.rotate = 
  }

// leader habndle media
const formMediaLeaderView = new FormMedia("leader-view-media");
formMediaLeaderView.setIconPath(root_path_mandoc+'assets/image/');
formMediaLeaderView.showDeleteButton(false);
formMediaLeaderView.showLabelAdd(false);
formMediaLeaderView.showHightlightLastUpload(true);
formMediaLeaderView.init();
formMediaLeaderView.setTranslate(media_trans);

// leader habndle media
const formMediaVBTView = new FormMedia("media-assign-department-vbt");
formMediaVBTView.setIconPath(root_path_mandoc+'assets/image/');
formMediaVBTView.showDeleteButton(false);
formMediaVBTView.showLabelAdd(false);
formMediaVBTView.showHightlightLastUpload(true);
formMediaVBTView.init();
formMediaVBTView.setTranslate(media_trans);

// preview mandoc
const formMediaPreview = new FormMedia("preview-files");
formMediaPreview.setIconPath(root_path_mandoc+'assets/image/');
formMediaPreview.showDeleteButton(false);
formMediaPreview.showLabelAdd(false);
formMediaPreview.showHightlightLastUpload(true);
formMediaPreview.init();
formMediaPreview.setTranslate(media_trans);

// preview mandoc
const foemMediaDepartment = new FormMedia("media-assign-department");
foemMediaDepartment.setIconPath(root_path_mandoc+'assets/image/');
foemMediaDepartment.showDeleteButton(false);
foemMediaDepartment.showLabelAdd(false);
foemMediaDepartment.showHightlightLastUpload(true);
foemMediaDepartment.init();
foemMediaDepartment.setTranslate(media_trans);

//
const formMediaProcess = new FormMedia("media-handle-process");
formMediaProcess.setIconPath(root_path_mandoc+'assets/image/');
formMediaProcess.showDeleteButton(false);
formMediaProcess.showLabelAdd(false);
formMediaProcess.showHightlightLastUpload(true);
formMediaProcess.init();
formMediaProcess.setTranslate(media_trans);

var userOptionsVBD = utils.getData(document.querySelector("#department_help_ids_vbt"), 'options');
let choices_department_vbt = new window.Choices(document.querySelector("#department_help_ids_vbt"), _objectSpread({
itemSelectText: ''
}, userOptionsVBD));

var userOptionsVBT = utils.getData(document.querySelector("#department_help_ids_vbd"), 'options');
let choices_department_vbd = new window.Choices(document.querySelector("#department_help_ids_vbd"), _objectSpread({
itemSelectText: ''
}, userOptionsVBT));

reloadChoicesVBT();
reloadChoicesVBD();

// on change select department
$("#form_add_mandoc_dhandle #department_id").on('change',(e)=>{
    reloadChoicesVBT();
})
$("#form_asign_mandoc_department_vbd #department_id").on('change',(e)=>{
    reloadChoicesVBD();
})

let selectId = 0;
let formScodeist = ['FORM-ASSIGN-VT','FORM-ASSIGN-PB']; // sau nay se lay danh sach tu logic ben backend
$('.open_form_assign_process').on('click', function(e) {
  selectId = $(e.currentTarget).data("mandoc-id");
});

formScodeist.forEach(scode=>{
  $(`button#${scode}`).on('click', function() {
    $('#formchonxuly').modal("hide");
    $(`[data-form-code="${scode}"][data-mandoc-id="${selectId}"]`).click();
  });
});

function reloadChoicesVBT(){
    let selected_Id =  $("#form_add_mandoc_dhandle #department_id").val();
    let newSelectItems = [];
    $("#form_add_mandoc_dhandle #department_id option").each(function(){
        let value = $(this).val();
        let label = $(this).html();

        newSelectItems.push({
            value: value,
            label: label,
            disabled: value == selected_Id
        })
    });
    choices_department_vbt.removeActiveItemsByValue(selected_Id);
    choices_department_vbt.removeActiveItems();
    choices_department_vbt.clearChoices();
    choices_department_vbt.setChoices(newSelectItems);


}
function reloadChoicesVBD(){
    let selected_Id =  $("#form_asign_mandoc_department_vbd #department_id").val();
    let newSelectItems = [];
    $("#form_asign_mandoc_department_vbd #department_id option").each(function(){
        let value = $(this).val();
        let label = $(this).html();

        newSelectItems.push({
            value: value,
            label: label,
            disabled: value == selected_Id
        })
    });
    choices_department_vbd.removeActiveItemsByValue(selected_Id);
    choices_department_vbd.removeActiveItems();
    choices_department_vbd.clearChoices();
    choices_department_vbd.setChoices(newSelectItems);

}

// datepicker
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
  });
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
  
function open_form_assign_departments(mandocid, content ,sfrom, received_at,effective_date, iduhandle, mdepartment) {
    // load mandoc data
    showLoadding(true);
    callGetMandocRemote(mandocid,"loadLeaderViewData");
    formMediaLeaderView.removeTableItemAll();

    // choices_department.removeActiveItems();
    $("#contents").val("");
    $("#iduhandle").val(iduhandle);
    $("#mandoc_id_dhandle").val(mandocid);

    content = decodeURIComponent(content).replace(/\+/g, ' ');
    $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC").val(content);
    $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC").prop("readonly", true);

    if (effective_date == ""){
        $("#deadline\\ dis_enter_out").val(received_at);
    }else {
        $("#deadline\\ dis_enter_out").val(effective_date);
    }
}

function open_form_assign_departments_vt(mandocid, content,sfrom, received_at,effective_date, iduhandle, mdepartment) {
    // load mandoc data
    showLoadding(true);
    callGetMandocRemote(mandocid,"loadPBViewData");
    foemMediaDepartment.removeTableItemAll();

    // choices_department.removeActiveItems();

    dcontent = decodeURIComponent(content).replace(/\+/g, ' ');
    $("textarea#contents").val(dcontent);
    // $("textarea#contents").prop("readonly", true);

    $('#form_asign_mandoc_department_vbd #department_id').val(mdepartment).trigger('change.select2'); 
    $.ajax({
        url: mandocs_get_department_path,
        method: 'get',
        data: { department_id: mdepartment },
        success: function(data) {
          var usersArr = [];
        
          $.each(data, function(index, user) {
            if (user.positionjob_name.includes("Trưởng")) {
                usersArr.push('<option value="'+user.id+'" selected>'  + user.last_name +' '+ user.first_name +' (' + user.positionjob_name +')'+'</option>');
                
            } else {
                usersArr.push('<option value="'+user.id+'">'  + user.last_name +' '+ user.first_name +' (' + user.positionjob_name +')'+'</option>');
                
            }
          });
          $('#form_asign_mandoc_department_vbd #department_user').html(usersArr.join(''));
        }
    });
    $('#form_asign_mandoc_department_vbd #department_id').on('change', function() {
      var departmentId = $(this).val();
      $.ajax({
        url: mandocs_get_department_path,
        method: 'get',
        data: { department_id: departmentId },
        success: function(data) {
          var usersArr = [];
          $.each(data, function(index, user) {
            if (user.positionjob_name.includes("Trưởng")) {
              usersArr.push('<option value="' + user.id + '" selected>' + user.last_name + ' ' + user.first_name + ' (' + user.positionjob_name + ')' + '</option>');
            } else {
              usersArr.push('<option value="' + user.id + '">' + user.last_name + ' ' + user.first_name + ' (' + user.positionjob_name + ')' + '</option>');
            }
          });
          $('#form_asign_mandoc_department_vbd #department_user').html(usersArr.join(''));
        }
      });
    }).trigger('change');
    reloadChoicesVBD();
    $("#form_asign_mandoc_department_vbd #iduhandle_pb_handle_user").val(iduhandle);
    $("#form_asign_mandoc_department_vbd #mandoc_id_handle_user").val(mandocid); 
    if (effective_date == ""){
        $("#form_asign_mandoc_department_vbd #deadline").val(received_at);
    }else {
        $("#form_asign_mandoc_department_vbd #deadline").val(effective_date);
    }
}


function open_form_assign_departments_in(mandocid, content, sfrom, received_at,effective_date, iduhandle, mdepartment) {
    // choices_department.removeActiveItems();
    $("#contents_in").val("");
    $("#iduhandle_in").val(iduhandle);
    $("#mandoc_id_dhandle_in").val(mandocid);
    dcontent = decodeURIComponent(content).replace(/\+/g, ' ');
    $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC_in").val(dcontent);
    $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC_in").prop("readonly", true);
    if (effective_date == ""){
        $("#deadline").val(received_at);
    }else {
        $("#deadline").val(effective_date);
    }
    
}

// function reloadChoices(){
//     let selected_Id =  $("#department_id").val();
//     let newSelectItems = [];
//     $("#department_id option").each(function(){
//         let value = $(this).val();
//         let label = $(this).html();

//         newSelectItems.push({
//             value: value,
//             label: label,
//             disabled: value == selected_Id
//         })
//     });
//     choices_department.removeActiveItemsByValue(selected_Id);
//     // choices_department.removeActiveItems();
//     choices_department.clearChoices();
//     choices_department.setChoices(newSelectItems);
// }
function openFormChon(button){
  $(button).tooltip('hide');
  $("#formchonxuly").modal("show");
}
function open_form_assign_departments_in_user(button,mandocid, iduhandle){
    $(button).tooltip('hide');
    $("#form_xu_ly_phan_PB_VBT").modal("show");
    // load mandoc data
    showLoadding(true);
    callGetMandocRemote(mandocid,"loadLeaderViewDataVBT");
    formMediaVBTView.removeTableItemAll();
    $("#form_add_mandoc_dhandle #iduhandle_pb_handle_user").val(iduhandle);
    $("#form_add_mandoc_dhandle #mandoc_id_handle_user").val(mandocid);
}

function openCheckMandocHandle(button,mandoc_id, dcontents, contents,uhandle_id, id_dhandle) {
    $(button).tooltip('hide');
    $("#check_mandocs_inactive").modal("show");
    showLoadding(true);
    callGetMandocRemote(mandoc_id,"loadProcessData");
    formMediaProcess.removeTableItemAll();
    document.getElementById("mandoc_id_handle_user_process").value = mandoc_id;
    dcontents = decodeURIComponent(dcontents).replace(/\+/g, ' ');
    $("textarea#content_department_process").val(dcontents);
    $("textarea#content_department_process").prop("readonly", true);
    document.getElementById("mandoc_content_user_process").value  = contents;
    document.getElementById("iduhandle_pb_handle_user_process").value = uhandle_id;
    document.getElementById("id_department_user_process").value = id_dhandle;
}
$(document).on("click", ".click-back", function () {
    showLoadding(true);
    
    var mandocIdHandleUserProcess = document.getElementById("mandoc_id_handle_user_process").value;
    var iduhandlePbHandleUserProcess = document.getElementById("iduhandle_pb_handle_user_process").value;
    var mandocContentUserProcess = document.getElementById("mandoc_content_user_process").value;
    var iddhandlePbHandleUserProcess = document.getElementById("id_department_user_process").value;
    callGetMandocRemote(mandocIdHandleUserProcess,"loadLeaderViewDataVBT");
    formMediaVBTView.removeTableItemAll();
    mandocContentUserProcess = decodeURIComponent(mandocContentUserProcess).replace(/\+/g, ' ');
    $("textarea#leader-view-content-vbt").val(mandocContentUserProcess);

    $("#form_add_mandoc_dhandle #mandoc_id_handle_user").val(mandocIdHandleUserProcess);
    $("#form_add_mandoc_dhandle #iduhandle_pb_handle_user").val(iduhandlePbHandleUserProcess);
    $("#form_add_mandoc_dhandle #leader-view-content-vbt").val(mandocContentUserProcess);
    $("#form_add_mandoc_dhandle #department_id").val(iddhandlePbHandleUserProcess);
    $("#form_add_mandoc_dhandle #department_id").trigger("change");
    }
)
function loadPreview(mandoc,files = []){
    showLoadding(false);
    formMediaPreview.removeTableItemAll();
    if(!mandoc){
      return;
    }
    $("#preview-contents").html(mandoc.contents);
    $("#preview-title").html(mandoc.notes != null && mandoc.notes != "" ? mandoc.notes : mandoc.contents);
    formMediaPreview.tableAddItems(files);
    $("#preview-modal").modal('show');
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
}
/**
 * 
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadProcessData(mandoc,files){;
    formMediaProcess.tableAddItems(files);
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
    showLoadding(false);
    $("#check_mandocs_inactive").modal('show');
}
/**
 * 
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadLeaderViewData(mandoc,files){

    // $("#leader-view-content-pb").html(mandoc.contents);
    // $("#form_add_mandoc_dhandle #leader-view-content").html(mandoc.contents);
    tinymce.get("show_mandoc_content_department").setContent(mandoc.contents);
    formMediaLeaderView.tableAddItems(files);
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
    showLoadding(false);
    $("#xu_ly_process_BGD").modal('show');
}
/**
 * 
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadLeaderViewDataVBT(mandoc,files){
    $("#form_add_mandoc_dhandle #leader-view-content-vbt").html(mandoc.contents);
    formMediaVBTView.tableAddItems(files);
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
    showLoadding(false);
}
/**
 * 
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadPBViewData(mandoc,files){
    // $("#leader-view-content-pb").html(mandoc.contents);
    // $("#form_add_mandoc_dhandle #leader-view-content").html(mandoc.contents);
    tinymce.get("mandoc_content_department").setContent(mandoc.contents);
    foemMediaDepartment.tableAddItems(files);
    $('tbody.list tr').each(function() {
      $(this).find('input[type="radio"]').prop('disabled', true);
    });
    showLoadding(false);
}

// click preview mandoc
$(".preview-mandoc").on('click',(e)=>{
    let mandocId = $(e.currentTarget).attr("data-id");
    viewMandoc(mandocId);
   
})

function viewMandoc(id){
    callGetMandocRemote(id,"loadPreview");
    showLoadding(true);
    
  }

function clickExport(mandoc_id){
    $('#export-pdf-form [name="mandoc_id"]').val(mandoc_id);
    $("#export-pdf-form").submit();
}

/**
 * submit remote form with data
 * @param {string} mandoc_id 
 * @param {string} func_name name of func callback from controller
 */
function callGetMandocRemote(mandoc_id,func_name){
    $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr('content'));
    $('#get_mandoc_form [name="mandoc_id"]').val(mandoc_id);
    $('#get_mandoc_form [name="func_name"]').val(func_name);
    $("#get_mandoc_form").submit();
}
function save_current_tab(current_tab){
    window.localStorage.setItem('current_tab', current_tab);
  } 
  var current_tab = window.localStorage.getItem('current_tab');
$(document).ready(function() { 
    initTinymce();
  $('[data-toggle="tooltip"]').tooltip({
    delay: { "show": 100, "hide": 100 }
  });
  $('.btn-close-tooltip').click(function() {
    $('[data-toggle="tooltip"]').tooltip('hide');
  });
  // Sự kiện khi modal được đóng
  if(current_tab == "tab_2"){
    document.getElementById("processes_tab_1").classList.remove("show");
    document.getElementById("processes_tab_1").classList.remove("active");
    document.getElementById("page_documents_processed").classList.remove("active");
    document.getElementById("page_process_2").classList.add("active");
    document.getElementById("page_process_2").classList.add("show");
    document.getElementById("processes_tab_2").classList.add("active");
    $("#li_in_tab_2").trigger("click");
  }  
  $("#deadline_bgd_handle\\ dis_enter").keydown(function(event) {
    if (event.key === "Enter") {
      event.preventDefault();
    }
  });
  $("#deadline\\ dis_enter_out").keydown(function(event) {
    if (event.key === "Enter") {
      event.preventDefault();
    }
  });
  $("#deadline_bgd_handle\\ dis_enter_time").keydown(function(event) {
    if (event.key === "Enter") {
      event.preventDefault();
    }
  });
  $('#form_add_mandoc_dhandle #department_id').on('change', function() {
    var departmentId = $(this).val();
    $.ajax({
      url: mandocs_get_department_path,
      method: 'get',
      data: { department_id: departmentId },
      success: function(data) {
        var usersArr = [];
        $.each(data, function(index, user) {
          if (user.positionjob_name.includes("Trưởng")) {
            usersArr.push('<option value="' + user.id + '" selected>' + user.last_name + ' ' + user.first_name + ' (' + user.positionjob_name + ')' + '</option>');
          } else {
            usersArr.push('<option value="' + user.id + '">' + user.last_name + ' ' + user.first_name + ' (' + user.positionjob_name + ')' + '</option>');
          }
        });
        $('#form_add_mandoc_dhandle #department_user').html(usersArr.join(''));
      }
    });
  }).trigger('change');
});
$("#li_in_tab_2").click(function() {
    var type = $("#submit_form_mandocs_status_process").attr("type");
    if (type=="submit"){
    $("#get_mandocs_status_processed").submit();
    $("#loading_screen").css("display", "flex");  
    $("#submit_form_mandocs_status_process").attr("type", "button");
    } 
});
function openCheckMandoc(mandoc_id, uhandle_id,contents) {
    document.getElementById("mandoc_id_handle_user_cancel").value = mandoc_id;
    document.getElementById("iduhandle_pb_handle_user_cancel").value = uhandle_id;
    dcontent = decodeURIComponent(contents).replace(/\+/g, ' ');
    $("textarea#contents_user_cancel").val(dcontent);
    $("textarea#contents_user_cancel").prop("readonly", true);
}  
function openModal(element) {
  var target = $(element).data('target');
  $(target).modal('show');
}
