let dataSsymbol = "";
$("#select_release_department").on("change", function() {
  var selectedOption = $(this).val();
  $('#get_list_users_with_depatment input#id_release_department').val(selectedOption);
  // $('#get_list_users_with_depatment').submit();
  if (selectedOption == "") {
    $("#select_release_department option").prop("disabled", false);
  } else if (selectedOption.includes("all")){
    $("#select_release_department option:not([value='all'])").prop("disabled", true);
  } else {
    $("#select_release_department option[value='all']").prop("disabled", true);
  }
  $('#form_release_mandoc .error_release').html("");
});

// Get the current date and time
var currentDate = new Date();
// Add 15 days to the current date
currentDate.setDate(currentDate.getDate() + 15);
// Format the date as needed
var year = currentDate.getFullYear();
var month = (currentDate.getMonth() + 1).toString().padStart(2, '0'); // Months are zero-based
var day = currentDate.getDate().toString().padStart(2, '0');
var staffDeadLine = day + '/' + month + '/' + year;

$("#select_release_staff").on("change", function() {
  var selectedOption = $(this).val();
  if (selectedOption == "") {
    $("#select_release_staff option").prop("disabled", false);
  } else if (selectedOption.includes("all")){
    $("#select_release_staff option:not([value='all'])").prop("disabled", true);
  } else {
    $("#select_release_staff option[value='all']").prop("disabled", true);
  }
  $('#form_release_mandoc .error_release').html("");
});

const image_upload_handler = (blobInfo, progress) => new Promise((resolve, reject) => {
  const xhr = new XMLHttpRequest();
  xhr.withCredentials = false;
  xhr.open('POST', action_upload_file_tinymce);

  xhr.upload.onprogress = (e) => {
    progress(e.loaded / e.total * 100);
  };

  xhr.onload = () => {
    if (xhr.status === 403) {
      reject({ message: 'HTTP Error: ' + xhr.status, remove: true });
      return;
    }

    if (xhr.status < 200 || xhr.status >= 300) {
      reject('HTTP Error: ' + xhr.status);
      return;
    }

    const json = JSON.parse(xhr.responseText);

    if (!json || typeof json.location != 'string') {
      reject('Invalid JSON: ' + xhr.responseText);
      return;
    }

    resolve(json.location);
  };

  xhr.onerror = () => {
    reject('Image upload failed due to a XHR Transport error. Code: ' + xhr.status);
  };

  const formData = new FormData();
  formData.append('file', blobInfo.blob(), blobInfo.filename());
  formData.append("authenticity_token",document.querySelector('meta[name="csrf-token"]').getAttribute('content'));

  xhr.send(formData);
});

function getListUser(datas) {
  var data_select_department = $("#select_release_department").val();
  var name_select_department = $("#select_release_department option:selected");
  $('#select_release_staff').empty().trigger('change');
  if (datas.length > 0) {
    var data = name_select_department.map(function() {
      return $(this).text();
    }).get();
    var list_department_select = data.join(", ");
    var newOption = new Option(`Tất cả nhân sự [${list_department_select}]`, "all", false, false); 
    $('#select_release_staff').append(newOption).trigger('change');
    datas.forEach(function(item, index) {
      var newOption = new Option(`${item.users.last_name} ${item.users.first_name} [${item.positionjob == null ? "" : item.positionjob.name} - ${item.department == null ? "" : item.department.name}]`, item.users.id, false, false); 
      $('#select_release_staff').append(newOption).trigger('change');
    });
  } 
  if (datas.length <= 0 && data_select_department == "") {
    var newOption = new Option("Tất cả nhân sự", "all", false, false); 
    $('#select_release_staff').append(newOption).trigger('change');
  }
  if (datas.length <= 0 && data_select_department != "") {
    var newOption = new Option("Không có nhân sự", "all", false, false); 
    $('#select_release_staff').append(newOption).trigger('change');
    $("#select_release_staff option").prop("disabled", true);

  }
}

/** PHAN DEPARTMENT */
var arrUsser = [];

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
  minDate: new Date(),
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


reloadChoices();
initDatePicker();
initDatePickerChosses();
let content_leader,content_department;
$( document ).ready(function() {
    initTinymce();
  $('#table_show_user_chosse').find('tr').length == 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $("#table_show_user_chosse input.submit-get").filter(':checked').length <= 0 ? $('#btn-submit-assign-user').prop("disabled", true) : $('#btn-submit-assign-user').prop("disabled", false);
  $.ajax({
    url: mandocs_get_department_path,
    method: 'get',
    data: { department_id: $('.form_VT_XL select#department_id').val() },
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
  $.ajax({
    url: mandocs_get_department_path,
    method: 'get',
    data: { department_id: $('#form_add_document_infor select#mdepartment').val() },
    success: function(data) {
      var usersArr = [];
      var department = "";
      $.each(data, function(index, user) {
        if (user.positionjob_name.includes("Trưởng")) {
            usersArr.push('<option value="'+user.email+'" selected>'  + user.last_name +' '+ user.first_name +' (' + user.positionjob_name +')'+'</option>');
            
        } else {
            usersArr.push('<option value="'+user.email+'">'  + user.last_name +' '+ user.first_name +' (' + user.positionjob_name +')'+'</option>');
            
        }
        department = user.department_name;
      });
      $('#signed_by_chosses_leader_department').html(usersArr.join(''));
      $('#form_add_document_infor #signed_by').html(usersArr.join(''));
      $('#render_title_chosses_leader_department').text("Chọn trưởng phòng/phó phòng"+ department);
    }
  });
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

$('#form_add_document_infor select#mdepartment').on('change', function() {
  var departmentId = $(this).val();
  var department = "";
  $.ajax({
    url: mandocs_get_department_path,
    method: 'get',
    data: { department_id: departmentId },
    success: function(data) {
      var usersArr = [];
      $.each(data, function(index, user) {
        if (user.positionjob_name.includes("Trưởng")) {
          usersArr.push('<option value="' + user.email + '" selected>' + user.last_name + ' ' + user.first_name + ' (' + user.positionjob_name + ')' + '</option>');
        } else {
          usersArr.push('<option value="' + user.email + '">' + user.last_name + ' ' + user.first_name + ' (' + user.positionjob_name + ')' + '</option>');
        }
        department = user.department_name;
      });
      $('#form_add_document_infor #signed_by').html(usersArr.join(''));
      $('#signed_by_chosses_leader_department').html(usersArr.join(''));
      $('#render_title_chosses_leader_department').text("Chọn trưởng phòng/phó phòng"+ department);
    }
  });
}).trigger('change');

function initTinymce(){
  var tinymceOptions = {
    language_url: '/mywork/assets/myjs/vi.js',
    language: 'vi',
    plugins: 'lists advlist anchor autolink autosave autoresize charmap code codesample directionality emoticons fullscreen image importcss insertdatetime link lists media nonbreaking pagebreak preview quickbars save searchreplace table template visualblocks visualchars wordcount',
    toolbar1: 'undo redo | blocks fontfamily fontsize | align lineheight | bold italic underline strikethrough forecolor backcolor',
    toolbar2: 'template |image checklist numlist bullist table mergetags | addcomment showcomments | spellcheckdialog a11ycheck typography | link media indent outdent',
    table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | tableinsertcolbefore tableinsertcolafter tabledeletecol',
    min_height: 500,
    file_picker_types: 'image',
    file_picker_callback: (cb, value, meta) => {
      const input = document.createElement('input');
      input.setAttribute('type', 'file');
      input.setAttribute('accept', 'image/*');
  
      input.addEventListener('change', (e) => {
        const file = e.target.files[0];
  
        const reader = new FileReader();
        reader.addEventListener('load', () => {
          /*
            Note: Now we need to register the blob in TinyMCEs image blob
            registry. In the next release this part hopefully won't be
            necessary, as we are looking to handle it internally.
          */
          const id = 'blobid' + (new Date()).getTime();
          const blobCache =  tinymce.activeEditor.editorUpload.blobCache;
          const base64 = reader.result.split(',')[1];
          const blobInfo = blobCache.create(id, file, base64);
          blobCache.add(blobInfo);
  
          /* call the callback and populate the Title field with the file name */
          cb(blobInfo.blobUri(), { title: file.name });
        });
        reader.readAsDataURL(file);
      });
  
      input.click();
    },
    automatic_uploads: false,
    relative_urls: false,
    remove_script_host: false,
    color_map: [
        '#BFEDD2', 'Light Green',
        '#FBEEB8', 'Light Yellow',
        '#F8CAC6', 'Light Red',
        '#ECCAFA', 'Light Purple',
        '#C2E0F4', 'Light Blue',
      
        '#2DC26B', 'Green',
        '#F1C40F', 'Yellow',
        '#E03E2D', 'Red',
        '#B96AD9', 'Purple',
        '#3598DB', 'Blue',
      
        '#169179', 'Dark Turquoise',
        '#E67E23', 'Orange',
        '#BA372A', 'Dark Red',
        '#843FA1', 'Dark Purple',
        '#236FA1', 'Dark Blue',
      
        '#ECF0F1', 'Light Gray',
        '#CED4D9', 'Medium Gray',
        '#95A5A6', 'Gray',
        '#7E8C8D', 'Dark Gray',
        '#34495E', 'Navy Blue',
      
        '#000000', 'Black',
        '#ffffff', 'White'
    ],
    templates : [
      {
        title: 'Mẫu nội dung ban hành văn bản của BMU',
        description: 'Xem trước mẫu - "Mẫu nội dung ban hành văn bản của BMU"',
        content: `<p><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong>K&iacute;nh gửi:&nbsp;</strong></span></p>
        <div>
        <div>&nbsp;</div>
        <div><em><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">(Nội dung chi tiết xem file đ&iacute;nh k&egrave;m)</span></em></div>
        <div><em><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">Tr&acirc;n trọng!./.</span></em></div>
        <div>&nbsp;</div>
        <span style="color: rgb(136, 136, 136); font-family: arial, helvetica, sans-serif; font-size: 12pt;">--<br></span>
        <div dir="ltr" data-smartmail="gmail_signature">
        <div dir="ltr">
        <div dir="ltr">
        <div dir="ltr">
        <div dir="ltr"><span style="font-size: 12pt;"><span style="font-family: arial, helvetica, sans-serif;"><span style="font-family: arial, helvetica, sans-serif;"><strong><em><span style="color: #ff0000;">*&nbsp;<u>Lưu &yacute;</u>:</span><span style="color: #0000ff;"> </span></em></strong></span></span><span style="color: rgb(35, 111, 161);"><strong><em><span style="line-height: 107%;">Đ&acirc;y l&agrave; hộp thư th&ocirc;ng b&aacute;o nội bộ, đề nghị Qu&yacute; Thầy/C&ocirc; kh&ocirc;ng phản hồi v&agrave;o mail n&agrave;y. Nếu c&oacute; vấn đề cần giải đ&aacute;p xin li&ecirc;n hệ trực tiếp với đơn vị soạn thảo văn bản.</span></em></strong></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">&nbsp;</span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><em><span style="color: #0000ff;"><img src="https://erp.bmtu.edu.vn/assets/image/logo.svg" width="238" height="87"></span></em></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="color: #0000ff;"><span style="color: rgb(0, 0, 0);">Đơn vị: </span></span><span style="line-height: 107%; color: rgb(132, 63, 161);">Văn thư - Trường Đại học Y Dược Bu&ocirc;n Ma Thuột</span></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="line-height: 107%; color: rgb(47, 84, 150);"><span style="color: rgb(0, 0, 0);">Email:&nbsp;</span></span></strong><span style="line-height: 107%; color: rgb(47, 84, 150); font-size: 14pt;"><span style="color: rgb(0, 0, 0);"><span style="line-height: 107%; font-family: 'Times New Roman', serif;"><a href="mailto:vanthu@benhvienbmt.com" target="_blank" rel="noopener"><span style="line-height: 107%; color: blue;">vanthu@bmu.edu.vn</span></a></span></span></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><span style="color: rgb(0, 0, 0);"><span style="color: rgb(0, 0, 0);"><strong><span style="line-height: 107%;"><span style="line-height: 107%;">SĐT: </span></span></strong></span></span><span style="line-height: 107%; color: rgb(0, 0, 0); font-size: 14pt;"><span style="line-height: 107%; font-family: 'Times New Roman', serif; color: blue;">(0262) 3 98 66 88 - Nh&aacute;nh 3020</span></span></span></div>
        </div>
        </div>
        </div>
        </div>
        </div>`
      },
      {
        title: 'Mẫu nội dung ban hành văn bản của BUH',
        description: 'Xem trước mẫu - "Mẫu nội dung ban hành văn bản của BUH"',
        content: `<p><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong>K&iacute;nh gửi:&nbsp;</strong><strong>.........</strong></span></p>
        <div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">Bệnh viện gửi ....... số ............ ng&agrave;y .........................Nội dung................................................</span></div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">(Nội dung chi tiết xem file đ&iacute;nh k&egrave;m)</span></div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">K&iacute;nh đề nghị c&aacute;c c&aacute; nh&acirc;n v&agrave; bộ phận li&ecirc;n quan nghi&ecirc;m t&uacute;c thực hiện.</span></div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">Tr&acirc;n trọng!./.</span></div>
        <div>&nbsp;</div>
        <span style="color: rgb(136, 136, 136); font-family: arial, helvetica, sans-serif; font-size: 12pt;">--<br></span>
        <div dir="ltr" data-smartmail="gmail_signature">
        <div dir="ltr">
        <div>
        <div dir="ltr">
        <div>
        <div dir="ltr">
        <div>
        <div dir="ltr"><span style="font-size: 12pt;"><span style="font-family: arial, helvetica, sans-serif;"><span style="font-family: arial, helvetica, sans-serif;"><strong><em><span style="color: #ff0000;">*&nbsp;<u>Lưu &yacute;</u>:</span><span style="color: #0000ff;"> </span></em></strong><span style="color: rgb(255, 25, 0);"><em>Đ&acirc;y l&agrave; hộp thư th&ocirc;ng b&aacute;o nội bộ, đề nghị Qu&yacute; Khoa/Ph&ograve;ng/Đơn vị kh&ocirc;ng phản hồi v&agrave;o mail n&agrave;y. Nếu c&oacute; vấn đề cần giải đ&aacute;p vui l&ograve;ng li&ecirc;n hệ trực tiếp với đơn vị soạn thảo văn bản.<br>Thank &amp; Best Regards!</em></span><strong><em><span style="color: #0000ff;"><br></span></em></strong></span></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">&nbsp;</span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><em><span style="color: #0000ff;"><img src="https://erp.bmtu.edu.vn/assets/buhlogo-47aad89b49cb2af2e9d61bda94c3db156183995b0e410521e0e053f6711d10f7.png" width="231" height="66"></span></em></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="color: #0000ff;"><span style="color: rgb(0, 0, 0);">Đơn vị: </span></span><span style="line-height: 107%; color: rgb(255, 25, 0);">Văn thư - Bệnh viện Đại học Y Dược Bu&ocirc;n Ma Thuột</span></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="line-height: 107%; color: rgb(47, 84, 150);"><span style="color: rgb(0, 0, 0);">Email:&nbsp;</span></span></strong><span style="line-height: 107%; color: rgb(47, 84, 150);"><span style="color: rgb(0, 0, 0);"><span style="line-height: 107%; font-family: 'Times New Roman', serif;"><a href="mailto:vanthu@benhvienbmt.com" target="_blank" rel="noopener"><span style="line-height: 107%; color: blue;">vanthu@benhvienbmt.com</span></a></span></span></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif;"><span style="color: rgb(0, 0, 0); font-size: 12pt;"><span style="color: rgb(0, 0, 0);"><strong><span style="line-height: 107%;"><span style="line-height: 107%;">SĐT: </span></span></strong></span></span><span style="font-size: 12pt; line-height: 107%; color: rgb(0, 0, 0);"><span style="line-height: 107%; font-family: 'Times New Roman', serif; color: blue;">(0262) 3 765 999 - Nh&aacute;nh 21112</span></span></span></div>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>`
      },
    ],
  }
  
  var tinymceOptionsSendEmail = {
    language_url: '/mywork/assets/myjs/vi.js',
    language: 'vi',
    plugins: 'lists advlist anchor autolink autosave autoresize charmap code codesample directionality emoticons fullscreen image importcss insertdatetime link lists media nonbreaking pagebreak preview quickbars save searchreplace table template visualblocks visualchars wordcount',
    toolbar1: 'undo redo | blocks fontfamily fontsize | align lineheight | bold italic underline strikethrough forecolor backcolor',
    toolbar2: 'template |image checklist numlist bullist table mergetags | addcomment showcomments | spellcheckdialog a11ycheck typography | link media indent outdent',
    table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | tableinsertcolbefore tableinsertcolafter tabledeletecol',
    min_height: 500,
    images_upload_handler: image_upload_handler,
    file_picker_types: 'image',
    file_picker_callback: (cb, value, meta) => {
      const input = document.createElement('input');
      input.setAttribute('type', 'file');
      input.setAttribute('accept', 'image/*');
  
      input.addEventListener('change', (e) => {
        const file = e.target.files[0];
  
        const reader = new FileReader();
        reader.addEventListener('load', () => {
          /*
            Note: Now we need to register the blob in TinyMCEs image blob
            registry. In the next release this part hopefully won't be
            necessary, as we are looking to handle it internally.
          */
          const id = 'blobid' + (new Date()).getTime();
          const blobCache =  tinymce.activeEditor.editorUpload.blobCache;
          const base64 = reader.result.split(',')[1];
          const blobInfo = blobCache.create(id, file, base64);
          blobCache.add(blobInfo);
  
          /* call the callback and populate the Title field with the file name */
          cb(blobInfo.blobUri(), { title: file.name });
        });
        reader.readAsDataURL(file);
      });
  
      input.click();
    },
    relative_urls: false,
    remove_script_host: false,
    color_map: [
        '#BFEDD2', 'Light Green',
        '#FBEEB8', 'Light Yellow',
        '#F8CAC6', 'Light Red',
        '#ECCAFA', 'Light Purple',
        '#C2E0F4', 'Light Blue',
      
        '#2DC26B', 'Green',
        '#F1C40F', 'Yellow',
        '#E03E2D', 'Red',
        '#B96AD9', 'Purple',
        '#3598DB', 'Blue',
      
        '#169179', 'Dark Turquoise',
        '#E67E23', 'Orange',
        '#BA372A', 'Dark Red',
        '#843FA1', 'Dark Purple',
        '#236FA1', 'Dark Blue',
      
        '#ECF0F1', 'Light Gray',
        '#CED4D9', 'Medium Gray',
        '#95A5A6', 'Gray',
        '#7E8C8D', 'Dark Gray',
        '#34495E', 'Navy Blue',
      
        '#000000', 'Black',
        '#ffffff', 'White'
    ],
    templates : [
      {
        title: 'Mẫu nội dung ban hành văn bản của BMU',
        description: 'Xem trước mẫu - "Mẫu nội dung ban hành văn bản của BMU"',
        content: `<p><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong>K&iacute;nh gửi:&nbsp;</strong></span></p>
        <div>
        <div>&nbsp;</div>
        <div><em><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">(Nội dung chi tiết xem file đ&iacute;nh k&egrave;m)</span></em></div>
        <div><em><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">Tr&acirc;n trọng!./.</span></em></div>
        <div>&nbsp;</div>
        <span style="color: rgb(136, 136, 136); font-family: arial, helvetica, sans-serif; font-size: 12pt;">--<br></span>
        <div dir="ltr" data-smartmail="gmail_signature">
        <div dir="ltr">
        <div dir="ltr">
        <div dir="ltr">
        <div dir="ltr"><span style="font-size: 12pt;"><span style="font-family: arial, helvetica, sans-serif;"><span style="font-family: arial, helvetica, sans-serif;"><strong><em><span style="color: #ff0000;">*&nbsp;<u>Lưu &yacute;</u>:</span><span style="color: #0000ff;"> </span></em></strong></span></span><span style="color: rgb(35, 111, 161);"><strong><em><span style="line-height: 107%;">Đ&acirc;y l&agrave; hộp thư th&ocirc;ng b&aacute;o nội bộ, đề nghị Qu&yacute; Thầy/C&ocirc; kh&ocirc;ng phản hồi v&agrave;o mail n&agrave;y. Nếu c&oacute; vấn đề cần giải đ&aacute;p xin li&ecirc;n hệ trực tiếp với đơn vị soạn thảo văn bản.</span></em></strong></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">&nbsp;</span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><em><span style="color: #0000ff;"><img src="https://erp.bmtu.edu.vn/assets/image/logo.svg" width="238" height="87"></span></em></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="color: #0000ff;"><span style="color: rgb(0, 0, 0);">Đơn vị: </span></span><span style="line-height: 107%; color: rgb(132, 63, 161);">Văn thư - Trường Đại học Y Dược Bu&ocirc;n Ma Thuột</span></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="line-height: 107%; color: rgb(47, 84, 150);"><span style="color: rgb(0, 0, 0);">Email:&nbsp;</span></span></strong><span style="line-height: 107%; color: rgb(47, 84, 150); font-size: 14pt;"><span style="color: rgb(0, 0, 0);"><span style="line-height: 107%; font-family: 'Times New Roman', serif;"><a href="mailto:vanthu@benhvienbmt.com" target="_blank" rel="noopener"><span style="line-height: 107%; color: blue;">vanthu@bmu.edu.vn</span></a></span></span></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><span style="color: rgb(0, 0, 0);"><span style="color: rgb(0, 0, 0);"><strong><span style="line-height: 107%;"><span style="line-height: 107%;">SĐT: </span></span></strong></span></span><span style="line-height: 107%; color: rgb(0, 0, 0); font-size: 14pt;"><span style="line-height: 107%; font-family: 'Times New Roman', serif; color: blue;">(0262) 3 98 66 88 - Nh&aacute;nh 3020</span></span></span></div>
        </div>
        </div>
        </div>
        </div>
        </div>`
      },
      {
        title: 'Mẫu nội dung ban hành văn bản của BUH',
        description: 'Xem trước mẫu - "Mẫu nội dung ban hành văn bản của BUH"',
        content: `<p><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong>K&iacute;nh gửi:&nbsp;</strong><strong>.........</strong></span></p>
        <div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">Bệnh viện gửi ....... số ............ ng&agrave;y .........................Nội dung................................................</span></div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">(Nội dung chi tiết xem file đ&iacute;nh k&egrave;m)</span></div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">K&iacute;nh đề nghị c&aacute;c c&aacute; nh&acirc;n v&agrave; bộ phận li&ecirc;n quan nghi&ecirc;m t&uacute;c thực hiện.</span></div>
        <div><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">Tr&acirc;n trọng!./.</span></div>
        <div>&nbsp;</div>
        <span style="color: rgb(136, 136, 136); font-family: arial, helvetica, sans-serif; font-size: 12pt;">--<br></span>
        <div dir="ltr" data-smartmail="gmail_signature">
        <div dir="ltr">
        <div>
        <div dir="ltr">
        <div>
        <div dir="ltr">
        <div>
        <div dir="ltr"><span style="font-size: 12pt;"><span style="font-family: arial, helvetica, sans-serif;"><span style="font-family: arial, helvetica, sans-serif;"><strong><em><span style="color: #ff0000;">*&nbsp;<u>Lưu &yacute;</u>:</span><span style="color: #0000ff;"> </span></em></strong><span style="color: rgb(255, 25, 0);"><em>Đ&acirc;y l&agrave; hộp thư th&ocirc;ng b&aacute;o nội bộ, đề nghị Qu&yacute; Khoa/Ph&ograve;ng/Đơn vị kh&ocirc;ng phản hồi v&agrave;o mail n&agrave;y. Nếu c&oacute; vấn đề cần giải đ&aacute;p vui l&ograve;ng li&ecirc;n hệ trực tiếp với đơn vị soạn thảo văn bản.<br>Thank &amp; Best Regards!</em></span><strong><em><span style="color: #0000ff;"><br></span></em></strong></span></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;">&nbsp;</span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><em><span style="color: #0000ff;"><img src="https://erp.bmtu.edu.vn/assets/buhlogo-47aad89b49cb2af2e9d61bda94c3db156183995b0e410521e0e053f6711d10f7.png" width="231" height="66"></span></em></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="color: #0000ff;"><span style="color: rgb(0, 0, 0);">Đơn vị: </span></span><span style="line-height: 107%; color: rgb(255, 25, 0);">Văn thư - Bệnh viện Đại học Y Dược Bu&ocirc;n Ma Thuột</span></strong></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif; font-size: 12pt;"><strong><span style="line-height: 107%; color: rgb(47, 84, 150);"><span style="color: rgb(0, 0, 0);">Email:&nbsp;</span></span></strong><span style="line-height: 107%; color: rgb(47, 84, 150);"><span style="color: rgb(0, 0, 0);"><span style="line-height: 107%; font-family: 'Times New Roman', serif;"><a href="mailto:vanthu@benhvienbmt.com" target="_blank" rel="noopener"><span style="line-height: 107%; color: blue;">vanthu@benhvienbmt.com</span></a></span></span></span></span></div>
        <div dir="ltr"><span style="font-family: arial, helvetica, sans-serif;"><span style="color: rgb(0, 0, 0); font-size: 12pt;"><span style="color: rgb(0, 0, 0);"><strong><span style="line-height: 107%;"><span style="line-height: 107%;">SĐT: </span></span></strong></span></span><span style="font-size: 12pt; line-height: 107%; color: rgb(0, 0, 0);"><span style="line-height: 107%; font-family: 'Times New Roman', serif; color: blue;">(0262) 3 765 999 - Nh&aacute;nh 21112</span></span></span></div>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>
        </div>`
      },
    ],
  }
  
  tinymce.init({
    ...{selector: '#form_add_mandoc_pending [name="contents"]'},
    ...tinymceOptions
  });
  tinymce.init({
    ...{selector: '#xu_ly_user_assign [name="user_process_mandoc_content"]'},
    ...tinymceOptions
  });

  tinymce.init({
    ...{selector: '#FORM-ASSIGN-BLD [name="mandoc_content_leader"]'},
    ...tinymceOptions
  });

  tinymce.init({
    ...{selector: '#FORM-ASSIGN-PB [name="mandoc_content_department"]'},
    ...tinymceOptions
  });

  tinymce.init({
    ...{selector: '#form_release_mandoc textarea#content_email'},
    ...tinymceOptionsSendEmail
  });

}
// on change select department
$("#department_id").on('change',(e)=>{
    reloadChoices();
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
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  if(!mandoc){
    return;
  }
  $("#preview-contents").html(mandoc.contents);
  $("#preview-title").html(mandoc.notes);
  formMediaPreview.tableAddItems(files);
  $("#preview-modal").modal('show');
}

function checkDupliceSrole(id,idRecive) {
  var selectedIds = $('.radio-receive').filter(':checked').map(function() {
    var idview = "#To_know_"+this.dataset.id;
    $(idview).prop('checked', false);
    return {
      id: "#"+this.id,
      data: this.dataset.id
  }}).get();
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

  datePick_arr.forEach(picker=>{
    picker.set("maxDate",mandoc_deadline);
  })
  var id_dhandle = $(e.relatedTarget).attr('data-id-dhandle'); 
  $(this).find('#id_dhandle_dv').val(id_dhandle);
});
$('#xu_ly_process_DV').on('hidden.bs.modal', function (e) {
  arrUsser = [];
  $('#table_show_user_chosse').find('tr').remove();
});
function onOpenUserHandleForm(mandocId,uHandleId,uHandleContents,assignName){
  // form static data
  $('#xu_ly_user_assign [name="id_uhandle"]').val(uHandleId);
  
  $('#xu_ly_user_assign [name="mandoc_id"]').val(mandocId);
  $('#xu_ly_user_assign [name="assign_name"]').val(assignName);

  uHandleContents = decodeURIComponent(uHandleContents).replace(/\+/g, ' ');
  $('#xu_ly_user_assign [id="content_department"]').val(uHandleContents);
  $("textarea#content_department").prop("readonly", true);
  showLoadding(true);
  callGetMandocRemote(mandocId,"loadMandocContent");
  formMediaMandocfileUser.removeTableItemAll();
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
}

function loadMandocContent(mandoc, files){
  if(!mandoc){
    return;
  }
  formMediaMandocfileUser.tableAddItems(files);
  tinymce.get("user_process_mandoc_content").setContent(mandoc.contents);
  $("#xu_ly_user_assign").modal('show');
  showLoadding(false);

  $('#table_file_upload_file_mandocfile_user tbody.list tr').each(function() {
    $(this).find('input[type="radio"]').prop('disabled', true);
  });
}

$("#btn-submit-assign-user").on("click",function(){
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

$("#btn_add_doc_pending_close").on("click",function(){
  var err_add= $('#err_add');

  $('#sno').val('');
  $('#ssymbol').val('');
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

  err_add.css("display", "none");
  $(".modal-backdrop").remove()

  
});

$("#btn_add_doc_pending_exit").on("click",function(){
  var err_add= $('#err_add');
  var contents= $('#contents').val();

  $('#sno').val('');
  $('#ssymbol').val('');
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

  err_add.css("display", "none");
  $(".modal-backdrop").remove()


  // if(contents == ""){
  //   $('#contents').css('border','1px solid red');
  //   err_add.html(blank_contents);
  //   err_add.css("display", "block");
  //   $('#sno').val('');
  //   $('#ssymbol').val('');
  //   $('#signed_by').val('');
  //   $('#created_by').val('');
  //   $("#type_book").prop('selectedIndex', 0).val();
  //   $("#stype").prop('selectedIndex', 0).val();
  //   $("#spriority").prop('selectedIndex', 0).val();
  //   $("#dt_document_date").val(time_now);
  //   $('#slink').val('');
  //   $('#contents').val('');
  //   $('#notes').val('');
  //   $('#number_pages').val('');

  //   $('#signed_by').css("border", "1px solid var(--falcon-input-border-color)");
  //   $('#created_by').css("border", "1px solid var(--falcon-input-border-color)");
  //   $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
  //   $('#ssymbol').css("border", "1px solid var(--falcon-input-border-color)");

  // }else {
  //   $('#contents').css("border", "1px solid var(--falcon-input-border-color)");
  //   $('#status_doc').val("PENDING");
  //   $("#form_add_document_infor").submit();
  // }
});

$("#btn_add_doc").on("click",function(){
  var err_add= $('#err_add');
  var ds_ids_media = $('#form_add_document_infor input[name="media_ids[]"]').val();
  if (ds_ids_media == undefined) {
    if (confirm("Chưa có tập tin đính kèm, xác nhận thêm và trình lên Trưởng/Phó phòng")) {
    } else {
      return
    }
  }
  var notes = $("#notes").val()
   if (notes == ""){
    $("#notes").css('border','1px solid red');
    err_add.html(blank_contents);
    err_add.css("display", "block");
   }else {
     $('#chosses_leader_department').modal('show');
   }
});

$("#btn_update_doc").on("click",function(){
  var err_add= $('#err_add');
  var notes = $("#notes").val()
   if (notes == ""){
    $("#notes").css('border','1px solid red');
    err_add.html(blank_contents);
    err_add.css("display", "block");
   }else {
     // Xử lý
     $("#form_add_document_infor input[name='media_ids[]']").remove();
     $("#form_add_document_infor input[name='option_media[]']").remove();
     var input_radio = $('input[data-radio="radio_option"]:checked');    
     for (let i = 0; i < input_radio.length; i++) {
       var parts = input_radio[i].value.split('-');
       var value = parts[1];
   
       $("#form_add_document_infor").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
       $("#form_add_document_infor").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
     }
     $("#form_add_document_infor").submit();

     
   }
});

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
  initDatePickerChosses();
  
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
                      <input id="dt_issued_date_dealine_${item.users.id}" type="text" name="deadline[${item.users.id}]" data-user-dealine="${item.users.id}" value="${Time_Now}" class="form-control openemr-datepicker input-textbox outline-element incorrect" objtype="7" maxlength="10" name="action_element" aria-label="Select Date"> 
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

$("#notes").change(function(){
  var err_add= $('#err_add');
  var notes = $("#notes").val()

  if (notes != ""){
    $("#notes").css("border", "1px solid var(--falcon-input-border-color)");
    // err_add.html(blank_contents);
    err_add.css("display", "none");
  }

});

$('#signed_by_chosses_leader_department').on("change",function(){
  $('#signed_by').val($('#signed_by_chosses_leader_department').val());
});

$("#confirm_form_chosses_leader_department").on("click",function(){
  if (confirm("Bạn có chắc chắn muốn thêm văn bản ?")) {
    showLoadding(true);
    add_docs_out();
  }
});

function add_docs_out(){
  var err_add= $('#err_add');
    
  // pass value from editer to textarea
  $("#contents").val(tinymce.get("contents").getContent())
  var contents= $('#contents').val();
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#form_add_document_infor input[name='media_ids[]']").remove();
  $("#form_add_document_infor input[name='option_media[]']").remove();
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];
    $("#form_add_document_infor").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#form_add_document_infor").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }
    $('#status_doc').val("INPROGRESS");
    $("#form_add_document_infor").submit();
    $("#btn_add_doc").css("display","none")
    $("#btn_add_doc_pending").css("display","none")
    $("#loading_button_add_doc_out").css("display","block")

  

}



$("#btn_add_doc_pending").on("click",function(){
    var err_add= $('#err_add');

    $("#contents").val(tinymce.get("contents").getContent())
    var contents = $('#contents').val();

    
      $('#contents').css("border", "1px solid var(--falcon-input-border-color)");
      $('#status_doc').val("PENDING");
      $("#form_add_document_infor").submit();
      $("#btn_add_doc_pending").css("display","none")
      $("#btn_add_doc").css("display","none")
      $("#loading_button_add_doc_pending_out").css("display","block")
      err_add.css("display", "none");
 
});

function clickDeleteMandocfile(id,name){
    href_mandocfile_delete += `?id=${id}`;

    let html = `${mess_del}  <span style="font-weight: bold; color: red">${name}</span>?`
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href_mandocfile_delete,'get')
      }
    });

}

function deleteMandocfileOutgoing(id){
  action_delete_outgoingfile += `?aid=${id}`;
  let link = document.createElement('a');
  link.setAttribute('data-action',"delete");
  link.setAttribute('href',action_delete_outgoingfile);
  link.click();
}

//preview media
const formMediaPreview = new FormMedia("preview-files");
formMediaPreview.setIconPath(root_path_mandoc+'assets/image/');
formMediaPreview.showDeleteButton(false);
formMediaPreview.showLabelAdd(false);
formMediaPreview.init();
formMediaPreview.setTranslate(media_trans);

//preview media
const formMediaDepartmentVT = new FormMedia("media-assign-department-vt");
formMediaDepartmentVT.setIconPath(root_path_mandoc+'assets/image/');
formMediaDepartmentVT.setAction(mandocfile_upload_mediafile);
formMediaDepartmentVT.showDeleteButton(false);
formMediaDepartmentVT.init();
formMediaDepartmentVT.setTranslate(media_trans);
formMediaDepartmentVT.addEventListener("confirmdel",(data)=>{
  deleteMandocfileOutgoing(data.id);
});

formMediaDepartmentVT.addEventListener("upload_success",(data)=>{
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
    // đưa id media vào input media_ids của form mandocfile
    $("#form_assign_VT").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});

// leader handle media
const formMediaLeaderHandle = new FormMedia("media-leader-handle");
formMediaLeaderHandle.setIconPath(root_path_mandoc+'assets/image/');
formMediaLeaderHandle.showDeleteButton(false);
formMediaLeaderHandle.setAction(mandocfile_upload_mediafile);
formMediaLeaderHandle.setEditStatus(true);

formMediaLeaderHandle.init();
formMediaLeaderHandle.setTranslate(media_trans);
formMediaLeaderHandle.addEventListener("confirmdel",(data)=>{
  deleteMandocfileOutgoing(data.id);
});

formMediaLeaderHandle.addEventListener("upload_success",(data)=>{
    // đưa id media vào input media_ids của form mandocfile
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
    $("#new_mandocdhandle").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});

const formMediaMandocfile = new FormMedia("upload_file_mandocfile");
formMediaMandocfile.setIconPath(root_path_mandoc+'assets/image/');
formMediaMandocfile.setAction(mandocfile_upload_mediafile);
formMediaMandocfile.setTranslate(media_trans);
formMediaMandocfile.showDeleteButton(false);
formMediaMandocfile.setEditStatus(true);
formMediaMandocfile.init();
// formMediaMandocfile.tableAddItems(listMandocfiles);
formMediaMandocfile.addEventListener("confirmdel",(data)=>{
  deleteMandocfileOutgoing(data.id);
});

formMediaMandocfile.addEventListener("upload_success",(data)=>{
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
    // đưa id media vào input media_ids của form mandocfile
    $("#form_add_document_infor").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)

 });

const mediaFileRelease = new FormMedia("medias-mandoc-release");
mediaFileRelease.setIconPath(root_path_mandoc+'assets/image/');
mediaFileRelease.setAction(mandocfile_upload_mediafile);
mediaFileRelease.showStatus(false);
mediaFileRelease.showEnactRadioBtn(true);
mediaFileRelease.setTranslate(media_trans);
mediaFileRelease.showDeleteButton(false);
mediaFileRelease.init();

mediaFileRelease.addEventListener("confirmdel",(data)=>{
  deleteMandocfileOutgoing(data.id);
});

mediaFileRelease.addEventListener("upload_success",(data)=>{
  formMediaPreview.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  // đưa id media vào input media_ids của form mandocfile
  $("#form_release_mandoc").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});


const formMediaMandocfileUser = new FormMedia("upload_file_mandocfile_user");
  formMediaMandocfileUser.setIconPath(root_path_mandoc+'assets/image/');
  formMediaMandocfileUser.setAction(mandocfile_upload_mediafile);
  formMediaMandocfileUser.showDeleteButton(false);
  formMediaMandocfileUser.setEditStatus(true);
  formMediaMandocfileUser.setTranslate(media_trans);
  formMediaMandocfileUser.init();
  formMediaMandocfileUser.addEventListener("confirmdel",(data)=>{
    deleteMandocfile(data.id);
  });
  formMediaMandocfileUser.addEventListener("upload_success",(data)=>{
    formMediaPreview.removeTableItemAll();
    mediaFileRelease.removeTableItemAll();
    formMediaDepartmentVT.removeTableItemAll();
    formMediaLeaderHandle.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaAssignDepratment.removeTableItemAll();
    formMediaAssignLeader.removeTableItemAll();
    // đưa id media vào input media_ids của form mandocfile
    $("#upload_file_mandocfile_user").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
  });
  
  const formMediaAssignLeader = new FormMedia("media-assign-BGD");
  formMediaAssignLeader.setIconPath(root_path_mandoc+'assets/image/');
  formMediaAssignLeader.setAction(mandocfile_upload_mediafile);
  formMediaAssignLeader.setTranslate(media_trans);
  formMediaAssignLeader.showDeleteButton(false);
  formMediaAssignLeader.setEditStatus(true);
  formMediaAssignLeader.init();
  formMediaAssignLeader.addEventListener("confirmdel",(data)=>{
    deleteMandocfile(data.id);
  });
  formMediaAssignLeader.addEventListener("upload_success",(data)=>{
    formMediaPreview.removeTableItemAll();
    mediaFileRelease.removeTableItemAll();
    formMediaDepartmentVT.removeTableItemAll();
    formMediaLeaderHandle.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaAssignDepratment.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    // đưa id media vào input media_ids của form mandocfile
    $("#assign_leader_BLD").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
  });

  const formMediaAssignDepratment = new FormMedia("media-assign-department");
  formMediaAssignDepratment.setIconPath(root_path_mandoc+'assets/image/');
  formMediaAssignDepratment.setAction(mandocfile_upload_mediafile);
  formMediaAssignDepratment.setTranslate(media_trans);
  formMediaAssignDepratment.showDeleteButton(false);
  formMediaAssignDepratment.setEditStatus(true);
  formMediaAssignDepratment.init();
  formMediaAssignDepratment.addEventListener("confirmdel",(data)=>{
    deleteMandocfile(data.id);
  });
  formMediaAssignDepratment.addEventListener("upload_success",(data)=>{
    formMediaPreview.removeTableItemAll();
    mediaFileRelease.removeTableItemAll();
    formMediaDepartmentVT.removeTableItemAll();
    formMediaLeaderHandle.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    formMediaAssignLeader.removeTableItemAll();
    formMediaMandocfileUser.removeTableItemAll();
    // đưa id media vào input media_ids của form mandocfile
    $("#form_add_mandoc_dhandle").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
  });


  const mediaFileSaveRelease = new FormMedia("medias-mandoc-save-release");
  mediaFileSaveRelease.setIconPath(root_path_mandoc+'assets/image/');
  mediaFileSaveRelease.setAction(mandocfile_upload_mediafile);
  mediaFileSaveRelease.showStatus(false);  
  mediaFileSaveRelease.showEnactRadioBtn(true);
  mediaFileSaveRelease.setTranslate(media_trans);
  mediaFileSaveRelease.showDeleteButton(false);
  mediaFileSaveRelease.init();

function openFormUpdateMandocPending(id,type_book,sno,ssymbol,stype,signed_by,contents,notes,slink,created_by,received_at,effective_date,spriority,number_pages,mdepartment) {
  
  document.getElementById("id_mandoc").value = id;
  document.getElementById("type_book").value = type_book;
  $("#type_book").trigger("change");
  document.getElementById("sno").value = sno;
  document.getElementById("ssymbol").value = ssymbol;
  document.getElementById("stype").value = stype;
  $("#stype").trigger("change");
  document.getElementById("signed_by").value = signed_by;
  document.getElementById("notes").value = notes;
  document.getElementById("slink").value = slink;
  document.getElementById("dt_document_date").value = received_at;
  document.getElementById("created_by").value = created_by;
  document.getElementById("spriority").value = spriority;
  $("#spriority").trigger("change");
  document.getElementById("number_pages").value = number_pages;
  document.getElementById("mdepartment").value = mdepartment;
  document.getElementById("btn_add_doc_pending").style.display = "none";
  showLoadding(true);
  callGetMandocRemote(id,"loadMandocFile");
  formMediaMandocfile.removeTableItemAll();
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  // get mandoc files 
  // load contents
  tinymce.get("contents").setContent(contents)

}

function open_form_assign_leader_outgoing(mandocid, contents, received_at,effective_date,iddhandle) {
  $("#mandoc_id_leader_outgoing").val(mandocid);
  $("#contentsPBVT").text(contents);
  $("#iddhandle").val(iddhandle);
  if (effective_date == ""){
      $("#deadline_mandocs_leader_outgoing").val(received_at);
  }else {
      $("#deadline_mandocs_leader_outgoing").val(effective_date);
  }
}

function open_form_assign_handle_department_outgoing(mandocid, contents, received_at,effective_date,iddhandle) {
  showLoadding(true);
  callGetMandocRemote(mandocid,"loadLeaderViewDataVBT");
  formMediaDepartmentVT.removeTableItemAll();
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  $("#mandoc_id_handle_department_outgoing_VT").val(mandocid);
  $("#iddhandle_VT").val(iddhandle);
  if (effective_date == ""){
      $("#deadline_mandocs_leader_outgoing_VT").val(received_at);
  }else {
      $("#deadline_mandocs_leader_outgoing_VT").val(effective_date);
  }
}

function loadLeaderViewDataVBT(mandoc,files){ 
  formMediaDepartmentVT.tableAddItems(files);
  showLoadding(false);
}

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
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} listDocs
 */
function loadMandocData(mandoc,listDocs){
  showLoadding(false);
  if(!mandoc){
    return;
  }
  // BGD 
  var editer = tinymce.get("mandoc_content_leader");
  editer.setContent("");
  if(editer && mandoc.contents){
    editer.setContent(mandoc.contents);
  }
  formMediaAssignLeader.removeTableItemAll();
  // formMediaPreview.removeTableItemAll();
  // mediaFileRelease.removeTableItemAll();
	// formMediaDepartmentVT.removeTableItemAll();
	// formMediaLeaderHandle.removeTableItemAll();
	// formMediaMandocfile.removeTableItemAll();
	// formMediaAssignDepratment.removeTableItemAll();
	// formMediaMandocfileUser.removeTableItemAll();
  formMediaAssignLeader.tableAddItems(listDocs);
  $('#media-assign-BGD tbody.list tr').each(function() {
    $(this).find('input[type="radio"]').prop('disabled', true);
  });

  // Department
  editer = tinymce.get("mandoc_content_department");
  editer.setContent("");
  if(editer && mandoc.contents){
    editer.setContent(mandoc.contents);
  }
  formMediaAssignDepratment.removeTableItemAll();
  // formMediaPreview.removeTableItemAll();
  // mediaFileRelease.removeTableItemAll();
	// formMediaDepartmentVT.removeTableItemAll();
	// formMediaLeaderHandle.removeTableItemAll();
	// formMediaMandocfile.removeTableItemAll();
	// formMediaAssignLeader.removeTableItemAll();
	// formMediaMandocfileUser.removeTableItemAll();
  formMediaAssignDepratment.tableAddItems(listDocs);
  $('#media-assign-department tbody.list tr').each(function() {
    $(this).find('input[type="radio"]').prop('disabled', true);
  });

}

/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} listDocs 
 */
function loadMandocData_with_medias(mandoc,listDocs = []){

  showLoadding(false);
  if(!mandoc){
    return;
  }
  $('#leader-handle-form [name="contents"]').html(mandoc.contents);
  //  load scontent to editers
  var editer = tinymce.get("mandoc_content_leader");
  editer.setContent("");
  if(editer && mandoc.contents){
    editer.setContent(mandoc.contents);
  }
  editer = tinymce.get("mandoc_content_department");
  editer.setContent("");
  if(editer && mandoc.contents){
    editer.setContent(mandoc.contents);
  }

  // media files
	formMediaLeaderHandle.removeTableItemAll();

  formMediaLeaderHandle.tableAddItems(listDocs);

  $('#media-leader-handle tbody.list tr').each(function() {
    $(this).find('input[type="radio"]').prop('disabled', true);
  });
}

function save_current_tab(current_tab){
  window.localStorage.setItem('current_tab', current_tab);
} 
var current_tab = window.localStorage.getItem('current_tab');
$(document).ready(function() {
  if(current_tab == "tab_2"){
    document.getElementById("out_going_tab_1").classList.remove("show");
    document.getElementById("out_going_tab_1").classList.remove("active");
    document.getElementById("page_documents_processed").classList.remove("active");
    document.getElementById("page_process_2").classList.add("active");
    document.getElementById("page_process_2").classList.add("show");
    document.getElementById("out_going_tab_2").classList.add("active");
    $("#li_in_tab_2").click();
  }else if(current_tab == "tab_3") {
    document.getElementById("out_going_tab_1").classList.remove("show");
    document.getElementById("out_going_tab_1").classList.remove("active");
    document.getElementById("page_documents_processed").classList.remove("active");
    document.getElementById("page_pending").classList.add("active");
    document.getElementById("page_pending").classList.add("show");
    document.getElementById("out_going_tab_3").classList.add("active");
  }
  var form = document.getElementById("form_add_document_infor");

  form.addEventListener("keydown", function(event) {
    if (event.key === "Enter") {
      event.preventDefault();
    }
  });
  $('[data-toggle="tooltip"]').tooltip({
    delay: { "show": 100, "hide": 100 }
  });

});

function get_form_by_scode(scode) {

  $('#formchonxuly [name="back-icon"]').toggle(scode != "CHOICE-FORM");
  $("#form-wrap [data-title]").each((i,element)=>{
    var jq_element = $("#"+element.id);
    jq_element.toggle(element.id == scode);
    if(element.id == scode){
      $('#formchonxuly [name="modal-title"]').html(jq_element.attr("data-title"));
    }
  });

  
}

function get_mandoc_info(mandoc_id, content, received_at,effective_date, uhandle_id, department_id, deadline, dhandle_id){

  // call remote form to get mandoc content
  callGetMandocRemote(mandoc_id,"loadMandocData");
  
  $("#mandoc_id_dhandle").val(mandoc_id);
  content = decodeURIComponent(content).replace(/\+/g, ' ');
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC").val(content);
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC_in").val(content);
  $("textarea#mandoc_dhandle_Proposal_of_the_TC-HC_in").prop("readonly", true);

  if (deadline == ""){
    $("#deadline").val(received_at);
  }else {
    $("#deadline").val(deadline);
    $("#deadlines").val(deadline);
  }

  if (department_id != ""){
    $("#department_id").val(department_id);
    $("#department_id").trigger("change");
    reloadChoices();
  }

  $("#mandoc_id_leader_outgoing").val(mandoc_id);
  $("#contentsPBVT").text(contents);
  $("#iddhandle").val(dhandle_id);

  if (effective_date == ""){
      $("#deadline_mandocs_leader_outgoing").val(received_at);
  }else {
      $("#deadline_mandocs_leader_outgoing").val(effective_date);
  } 
  
  $("#iduhandle_pb").val(uhandle_id);
  $("#iduhandle_vt").val(uhandle_id);
  $("#iduhandle_bgd").val(uhandle_id);
  
  $("#mandoc_id_handle_department_outgoing").val(mandoc_id);
  $("#deadline_mandocs_leader_outgoing_2").val(deadline);
}
function clickLeaderHandle(mandoc_id, content, received_at,effective_date, uhandle_id, department_id, deadline, dhandle_id,last_uhandle_contents,showUnapproval){
  // call remote form to get mandoc content
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  callGetMandocRemote(mandoc_id,"loadMandocData_with_medias");
  
 
  
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

  if (department_id != ""){
    $("#department_id").val(department_id);
    reloadChoices();
  }

  $("#mandoc_id_leader_outgoing").val(mandoc_id);
  $("#contentsPBVT").text(contents);
  $("#iddhandle").val(dhandle_id);

  if (effective_date == ""){
      $("#deadline_mandocs_leader_outgoing").val(received_at);
  }else {
      $("#deadline_mandocs_leader_outgoing").val(effective_date);
  } 
  
  $("#iduhandle_pb").val(uhandle_id);
  $("#iduhandle_vt").val(uhandle_id);
  $("#iduhandle_bgd").val(uhandle_id);
  
  $("#mandoc_id_handle_department_outgoing").val(mandoc_id);
  $("#deadline_mandocs_leader_outgoing_2").val(deadline);

  // form data
  // formMediaLeaderHandle.removeTableItemAll();
  // formMediaPreview.removeTableItemAll();
  // mediaFileRelease.removeTableItemAll();
	// formMediaDepartmentVT.removeTableItemAll();
	// formMediaMandocfile.removeTableItemAll();
	// formMediaAssignDepratment.removeTableItemAll();
	// formMediaAssignLeader.removeTableItemAll();
	// formMediaMandocfileUser.removeTableItemAll();
  $('#leader-handle-form [name="contents"]').html("");
  // $('#leader-handle-form [name="contents"]').html(last_uhandle_contents);
  let unapproval = $("#leader-handle-form .unapproval-button");
  if(showUnapproval){
    unapproval.show();
    unapproval.attr("data-id",mandoc_id);
    unapproval.attr("data-content",last_uhandle_contents);
    unapproval.attr("data-id-dhandle",dhandle_id);
    unapproval.attr("data-deadline",deadline);
  }else{
    unapproval.hide();
    unapproval.attr("data-id",'');
    unapproval.attr("data-content",'');
    unapproval.attr("data-id-dhandle",'');
    unapproval.attr("data-deadline",'');
  }


}

function openReleaseModal(mandoc_id, count_out,stype,id_stype,ssymbol, ssymbol_VB){
  dataSsymbol = ssymbol;
  $("#modal-release-mandoc .assign-button").attr("data-mandoc-id",mandoc_id);
  $('#form_release_mandoc [name="mandoc_id"]').val(mandoc_id);
  $('#form_release_mandoc input[name="release_symbol"]').val(ssymbol_VB);
  $('#form_save_release_mandoc input[name="release_symbol"]').val(ssymbol_VB);
  $('#form_save_release_mandoc [name="mandoc_id"]').val(mandoc_id);
  $('#form_release_mandoc [name="release_sno"]').val(parseInt(count_out));
  $('#form_save_release_mandoc [name="release_sno"]').val(count_out);
  $('.stype_mandoc_relase').text(stype);
  $('#check_duplicate_symboll #check_mandoc_stype').val(id_stype);
  callGetMandocRemote(mandoc_id,"loadReleaseMandocFormData");
  showLoadding(true);
}

function openFormAssign(element) {
  let mandoc_id = $(element).attr("data-mandoc-id");
  $("#open_form_assign_"+mandoc_id).click();
}
function clickRelease(element) {
  $("#modal-release-mandoc").find(".choice-wrap").hide();
  $("#modal-release-mandoc").find("#form_release_mandoc").show();
}
function clickSaveRelease(element) {
  $("#modal-release-mandoc").find(".choice-wrap").hide();
  $("#modal-release-mandoc").find("#form_save_release_mandoc").show();
}
function backOnFormRelease(id) {
  $("#modal-release-mandoc").find(".choice-wrap").show();
  $("#modal-release-mandoc").find("#form_release_mandoc").hide();
  $("#modal-release-mandoc").find("#form_save_release_mandoc").hide();
}

/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadReleaseMandocFormData(mandoc,files){
  showLoadding(false);
  if(mandoc){
    if(mediaFileRelease){
      mediaFileRelease.removeTableItemAll();
      formMediaPreview.removeTableItemAll();
      formMediaDepartmentVT.removeTableItemAll();
      formMediaLeaderHandle.removeTableItemAll();
      formMediaMandocfile.removeTableItemAll();
      formMediaAssignDepratment.removeTableItemAll();
      formMediaAssignLeader.removeTableItemAll();
      formMediaMandocfileUser.removeTableItemAll();
    }else{
      // TODO: debug issue to fix this
    }
    $("#modal-release-mandoc").find(".choice-wrap").show();
    $("#modal-release-mandoc").find("#form_release_mandoc").hide();
    $("#modal-release-mandoc").find("#form_save_release_mandoc").hide();
    $("#modal-release-mandoc").modal("show");
  }else{
    // TODO: show not found message?
  }
}

/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMandocFile(mandoc,files){
  showLoadding(false);
  if(mandoc){
	  formMediaMandocfile.removeTableItemAll();

    formMediaMandocfile.tableAddItems(files);
    $("#upload_file_mandocfile").modal("show");
  }else{
    // TODO: show error
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


/**
 * 
 * @param {HTMLElement} element 
 */
function clickCollapse(element){
  $(element).find('#collapse-icon').css("rotate",element.className.includes('collapsed') ? "unset" : "-90deg");
  // document.getElementById('collapse-icon').style.rotate = 
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

function clickExport(mandoc_id){
  $('#export-pdf-form [name="mandoc_id"]').val(mandoc_id);
  $("#export-pdf-form").submit();
}

$("#li_in_tab_2").click(function() {
  var type = $("#submit_form_mandocs_status_out").attr("type");
  if (type=="submit"){
  $("#get_mandocs_status_out").submit();
  $("#loading_screen").css("display", "flex");  
  $("#submit_form_mandocs_status_out").attr("type", "button");
  } 
});
function openModal(element) {
  var target = $(element).data('target');
  $(target).modal('show');
}

$("#user_handle").click(function(){  
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#new_mandocdhandle input[name='media_ids[]']").remove();
  $("#new_mandocdhandle input[name='option_media[]']").remove();
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];
    $("#new_mandocdhandle").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#new_mandocdhandle").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }
  $("#new_mandocdhandle").submit();
  $("#user_handle").prop("disabled", true);

})

function openFormAddMandocPending() {
  $("#form_add_document_infor").prop("action", mandocs_outgoing_update_path);
  $("#add_Form_Label").text("Thêm văn bản đi");
  $("#type_book").val("VAN-BAN-DI").trigger("change");
  $(".element_update").css('display', 'none');
  $(".element_add").css('display', 'block !important');
  $("#mdepartment_edit").prop("disabled", true);
  $("#select_edit_mdepartment").addClass("d-none");
  $("#mdepartment").prop("disabled", false);
  $("#select_mdepartment").removeClass("d-none")
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
}

function changeRead(mandoc_id) {
  console.log(mandoc_id);
  $("#id_mandoc_change_read").val(mandoc_id);
  $("#outgoing_change_read").submit();
}

function openFormEditMandocPending(mandoc_id, type_book, stype, received_at, mdepartment, spriority, slink, number_pages, notes, created_by) {
  $("#form_add_document_infor").prop("action", mandocs_outgoing_edit_path);
  $("#add_Form_Label").text("Sửa văn bản đi");
  $("#type_book").val(type_book).trigger("change");
  $("#created_by_view").val(created_by);
  $("#created_by").val(created_by);
  $("#id_mandoc").val(mandoc_id);
  $("#mdepartment").val(mdepartment).trigger("change");
  $("#spriority").val(spriority).trigger("change");
  $("#stype").val(stype).trigger("change");
  $("#slink").val(slink);
  $("#dt_document_date").val(received_at);
  $("#number_pages").val(number_pages);
  $("#notes").val(notes);
  $(".element_add").css('display', 'none');
  $(".element_update").css('display', 'block');
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  showLoadding(true);
  callGetMandocRemote(mandoc_id,"loadMandocEdit");
  

}
function openFormEditMandocHandle(mandoc_id, type_book, stype, received_at,id_mdepartment, name_mdepartment, spriority, slink, number_pages, notes, created_by) {
  $("#mdepartment_edit").html(`<option value="${id_mdepartment}">${name_mdepartment}</option>`);
  $("#mdepartment_edit").val(id_mdepartment).trigger("change");
  $("#mdepartment").prop("disabled", true);
  $("#select_mdepartment").addClass("d-none");
  $("#mdepartment_edit").prop("disabled", false);
  $("#select_edit_mdepartment").removeClass("d-none");
  $("#form_add_document_infor").prop("action", mandocs_edit_handle_path);
  $("#add_Form_Label").text("Sửa văn bản đi");
  $("#type_book").val(type_book).trigger("change");
  $("#created_by_view").val(created_by);
  $("#created_by").val(created_by);
  $("#id_mandoc").val(mandoc_id);
  $("#spriority").val(spriority).trigger("change");
  $("#stype").val(stype).trigger("change");
  $("#slink").val(slink);
  $("#dt_document_date").val(received_at);
  $("#number_pages").val(number_pages);
  $("#notes").val(notes);
  $(".element_add").css('display', 'none');
  $(".element_update").css('display', 'block');
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
  showLoadding(true);
  callGetMandocRemote(mandoc_id,"loadMandocEdit");
}

function clickDeleteMandoc(id,name){
  let href = `${action_del_mandocs}`;
  href += `?id=${id}`;

  let html = `${mess_del_man} <span style="font-weight: bold; color: red">${name}</span>?`
  openConfirmDialog(html,(result )=>{
  if(result){
      doClick(href,'delete')
  }
  });
}

$("#user_vt_handle").click(function(){  

  formMediaPreview.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	mediaFileRelease.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#assign_leader_BLD input[name='media_ids[]']").remove();
  $("#assign_leader_BLD input[name='option_media[]']").remove();

  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];

    $("#assign_leader_BLD").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#assign_leader_BLD").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }
  $("#assign_leader_BLD").submit();
  $("#user_vt_handle").prop("disabled", true);

})

function onclickSubmitVTPB() {
  formMediaPreview.removeTableItemAll();
  mediaFileRelease.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#form_add_mandoc_dhandle input[name='media_ids[]']").remove();
  $("#form_add_mandoc_dhandle input[name='option_media[]']").remove();
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];

    $("#form_add_mandoc_dhandle").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#form_add_mandoc_dhandle").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }
  $("#form_add_mandoc_dhandle").submit();
  $("#btn_submit_VT_PB").prop("disabled", true);
}


$("#user_pb_handle").click(function(){  
  
  // // $("#form-user-process").submit();
  // $("#tooltippopovers").show();
})

$('#form_release_mandoc input[name="release_symbol"]').on("change", function() {
  $('#form_release_mandoc .error_release').html("");
  var val_release_symbol = $('#form_release_mandoc input[name="release_symbol"]').val();
  // if (val_release_symbol == "" || val_release_symbol == null) {
  //   $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng nhập số/ ký hiệu</div>`);
  // } else {
  //   if (val_release_symbol === dataSsymbol) {
  //   } else {
  //     $('#check_duplicate_symboll #check_symbol_release').val(val_release_symbol);
  //     var check_mandoc_stype = $('#check_duplicate_symboll #check_mandoc_stype').val();
  //     $.ajax({
  //       url: check_duplicate_symboll,
  //       type: 'POST',
  //       dataType: 'script',
  //       data: {
  //         release_mandoc_stype: check_mandoc_stype,
  //         str_symbol_release: val_release_symbol
  //       },
  //       success: function(data) {
  //         if (data == "false") {
  //           $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Số/ký hiệu đã tồn tại trong hệ thống, vui lòng nhập lại</div>`);
  //           return
  //         }
  //       }
  //     });
  //   }
  // }
});

$('#form_save_release_mandoc input[name="release_symbol"]').on("change", function() {
  $('#form_save_release_mandoc .error_release').html("");
  var val_release_symbol = $('#form_save_release_mandoc input[name="release_symbol"]').val();
  // if (val_release_symbol == "" || val_release_symbol == null) {
  //   $('#form_save_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng nhập số/ ký hiệu</div>`);
  // } else {
  //   $('#check_duplicate_symboll #check_symbol_release').val(val_release_symbol);
  //   var check_mandoc_stype = $('#check_duplicate_symboll #check_mandoc_stype').val();
  //   $.ajax({
  //     url: check_duplicate_symboll,
  //     type: 'POST',
  //     dataType: 'script',
  //     data: {
  //       release_mandoc_stype: check_mandoc_stype,
  //       str_symbol_release: val_release_symbol
  //     },
  //     success: function(data) {
  //       if (data == "false") {
  //         $('#form_save_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Số/ký hiệu đã tồn tại trong hệ thống, vui lòng nhập lại</div>`);
  //         return
  //       }
  //     }
  //   });
  // }
});

$('#form_release_mandoc #release_sno').on("change", function() {
  $('#form_release_mandoc .error_release').html("");
});

$('#form_save_release_mandoc #release_sno').on("change", function() {
  $('#form_save_release_mandoc .error_release').html("");
});

$('#subject_email').on("change", function() {
  var subject_email = $('#subject_email').val();
  var content_email =  tinymce.get("content_email").getContent();
  if (subject_email != "" && content_email != "") {
    $('#form_release_mandoc .error_release').html("");
  }
});

$('#content_email').on("change", function() {
  var subject_email = $('#subject_email').val();
  var content_email =  tinymce.get("content_email").getContent();
  if (subject_email != "" && content_email != "") {
    $('#form_release_mandoc .error_release').html("");
  }
});

$("#vt_ban_hanh").click(function(){  
  formMediaPreview.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();

  
  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#form_release_mandoc input[name='media_ids[]']").remove();
  $("#form_release_mandoc input[name='option_media[]']").remove();
  $('#form_release_mandoc .error_release').html("");
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];
    $("#form_release_mandoc").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#form_release_mandoc").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }

  var val_release_symbol = $('#form_release_mandoc input[name="release_symbol"]').val();
  var ds_ids_media = $('#form_release_mandoc input[name="media_ids[]"]').val();
  var list_staff = $('#select_release_staff').val();
  var list_department = $('#select_release_department').val();
  var release_sno = $('#release_sno').val();
  var subject_email = $('#subject_email').val();
  var content_email = tinymce.get("content_email").getContent();
  if (release_sno == "" || release_sno == null) {
    $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng nhập số văn bản</div>`);
    return
  }
  if (val_release_symbol == "" || val_release_symbol == null) {
    $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng nhập số/ ký hiệu</div>`);
    return
  }
  $('#check_duplicate_symboll #check_symbol_release').val(val_release_symbol);
  var check_mandoc_stype = $('#check_duplicate_symboll #check_mandoc_stype').val();

  // if (list_staff.length === 0 && list_department.length === 0) {
  //   $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng chọn phòng ban/đơn vị hoặc nhân sự để ban hành</div>`);
  //   return
  // }
  if (subject_email == "") {
    $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng soạn tiêu đề email để ban hành</div>`);
    $('#compose_email_content_collapse').click();
    return
  }
  if (ds_ids_media == undefined) {
    $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng đính kèm file ban hành</div>`);
    return
  }
  if (confirm("Bạn có muốn gửi email cho bạn kiểm tra trước khi gửi email không?")) {
    var mandoc_id_release = $('#mandoc_id_release').val();
    var subject_email = $('#subject_email').val();
    var content_email = tinymce.get("content_email").getContent();
    var mediaValues = [];
    $("input[name='media_ids[]']").each(function() {
      mediaValues.push($(this).val());
    });
    var email_test = prompt("Nhập Email muốn gửi thử nghiệm:", '');
    if (email_test != "" && email_test != null) {
      const xhr = new XMLHttpRequest();
      xhr.withCredentials = false;
      xhr.open('POST', action_send_email_test);
      xhr.onload = () => {
          if (xhr.status === 403) {
            reject({ message: 'HTTP Error: ' + xhr.status, remove: true });
            return;
          }
      
          if (xhr.status < 200 || xhr.status >= 300) {
            reject('HTTP Error: ' + xhr.status);
            return;
          }
      
          const json = JSON.parse(xhr.responseText);
      
          if (!json || typeof json.location != 'string') {
            reject('Invalid JSON: ' + xhr.responseText);
            return;
          }
      
          alert(json.location);
        };
      const formData = new FormData();
      formData.append("authenticity_token",document.querySelector('meta[name="csrf-token"]').getAttribute('content'));
      formData.append("subject_email", subject_email);
      formData.append("content_email", content_email);
      formData.append("email_test", email_test);
      formData.append("media_ids", mediaValues);
      formData.append("mandoc_id", mandoc_id_release);
      xhr.send(formData);
    }
  } else {
    $("#form_release_mandoc").submit();
  }

  // if (val_release_symbol === dataSsymbol) {
  //   $("#form_release_mandoc").submit();
  // } else {
  //   $.ajax({
  //     url: check_duplicate_symboll,
  //     type: 'POST',
  //     dataType: 'script',
  //     data: {
  //       release_mandoc_stype: check_mandoc_stype,
  //       str_symbol_release: val_release_symbol
  //     },
  //     success: function(data) {
  //       if (data == "false") {
  //         $('#form_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Số/ký hiệu đã tồn tại trong hệ thống, vui lòng nhập lại</div>`);
  //         return
  //       } else {
  //         $("#form_release_mandoc").submit();
  //       }
  //     }
  //   });
  // }
})

$("#save_no_release").click(function(){  
  formMediaPreview.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();
	formMediaMandocfileUser.removeTableItemAll();

  $('#form_save_release_mandoc .error_release').html("");
  var val_release_symbol = $('#form_save_release_mandoc input[name="release_symbol"]').val();
  var release_sno = $('#release_sno').val();
  if (release_sno == "" || release_sno == null) {
    $('#form_save_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng nhập số văn bản</div>`);
    return
  }
  if (val_release_symbol == "" || val_release_symbol == null) {
    $('#form_save_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Vui lòng nhập số/ ký hiệu</div>`);
    return
  }
  $('#check_duplicate_symboll #check_symbol_release').val(val_release_symbol);
  var check_mandoc_stype = $('#check_duplicate_symboll #check_mandoc_stype').val();

  var input_radio = $('input[data-radio="radio_option"]:checked');
  $("#form_save_release_mandoc input[name='media_ids[]']").remove();
  $("#form_save_release_mandoc input[name='option_media[]']").remove();
  $('#form_save_release_mandoc .error_release').html("");
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];
    $("#form_save_release_mandoc").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#form_save_release_mandoc").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }


  $("#form_save_release_mandoc").submit();

  // $.ajax({
  //   url: check_duplicate_symboll,
  //   type: 'POST',
  //   dataType: 'script',
  //   data: {
  //     release_mandoc_stype: check_mandoc_stype,
  //     str_symbol_release: val_release_symbol
  //   },
  //   success: function(data) {
  //     if (data == "false") {
  //       $('#form_save_release_mandoc .error_release').html(`<div class="alert alert-danger" role="alert">Số/ký hiệu đã tồn tại trong hệ thống, vui lòng nhập lại</div>`);
  //       return
  //     } else {
  //       $("#form_save_release_mandoc").submit();
  //     }
  //   }
  // });
})

$('#medias-mandoc-release').on('click', function() {
  $('#form_release_mandoc .error_release').html("");
});
function conFirmHandle() {

  formMediaPreview.removeTableItemAll();
	formMediaDepartmentVT.removeTableItemAll();
	formMediaLeaderHandle.removeTableItemAll();
	formMediaMandocfile.removeTableItemAll();
	mediaFileRelease.removeTableItemAll();
	formMediaAssignDepratment.removeTableItemAll();
	formMediaAssignLeader.removeTableItemAll();

  
  var input_radio = $('input[data-radio="radio_option"]:checked');
  var get_name = $("#assign_name").val()
  $("#inner_assign_handle").html(get_name);
  $("#form-user-process input[name='media_ids[]']").remove();
  $("#form-user-process input[name='option_media[]']").remove();
  for (let i = 0; i < input_radio.length; i++) {
    var parts = input_radio[i].value.split('-');
    var value = parts[1];
    $("#form-user-process").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
    $("#form-user-process").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
  }
  var get_name = $("#assign_name").val();
  alert(`Văn bản đã được chuyển đến: ${get_name}`);
    showLoadding(true);
    $("#form-user-process").submit();
 
}

function onclickOpenModalVTAddComment(mandoc) {

  $("#mandoc_id_vt_add_comment").val(mandoc.id);
  $("#Mandoc_comment").html(mandoc.comment);
}

function onclickVTAddComment() {
  showLoadding(true);  
  $("#btn_add_VT_comment").prop('disabled', true);
  $("#form_VT_add_comment").submit();
}

function loadMandocEdit(mandoc,files){ 
  
  formMediaMandocfile.tableAddItems(files);
  $('#form_add_document_infor tbody.list tr').each(function() {
    $(this).find('input[type="radio"]').prop('disabled', true);
  });
  showLoadding(false);
}
