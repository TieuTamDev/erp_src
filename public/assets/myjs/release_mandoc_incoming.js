function deleteFileManIncoming(id){
    action_del += `?aid=${id}`;
    let link = document.createElement('a');
    link.setAttribute('data-action',"delete");
    link.setAttribute('href',action_del);
    link.click();
}

function clickEditMandocMedias(mandoc_id){
    showLoadding(true);
    $('#mandoc-media [name="mandoc_id"]').val(mandoc_id);
    formMediaManfile.removeTableItemAll();
    formMediaMandocfile.removeTableItemAll();
    callGetMandocRemote(mandoc_id,"loadMandocFile")
}

function loadPreview(mandoc){
    showLoadding(false);
    if(!mandoc){
        return;
    }
    $("#preview-contents").html(mandoc.contents);
    $("#preview-title").html(mandoc.notes);
    $("#preview-modal").modal('show');
}

/**
 * submit remote form with data
 * @param {string} mandoc_id 
 * @param {string} func_name name of func callback from controller
 */
function callGetMandocRemote(mandoc_id,func_name,type){
    $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr('content'));
    $('#get_mandoc_form [name="mandoc_id"]').val(mandoc_id);
    $('#get_mandoc_form [name="func_name"]').val(func_name);
    $('#get_mandoc_form [name="type"]').val(type);
    $("#get_mandoc_form").submit();
}

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

  
      formMediaManfile.removeTableItemAll();
      formMediaSendMailManfile.removeTableItemAll();
      var input_radio = $('input[data-radio="radio_option"]:checked');
      $('#form_add_document_infor .error_release').html("");
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

  function choose_user(){
    $("#staticBackdropLabel_add").html("Thêm văn bản đến");
    $("#created_by").val(User_full_name);
    var type_book = "VAN-BAN-DEN";
    document.getElementById("type_book").value = type_book;
    $('#sno').val(value_sno)
    document.getElementById("mandoc_id").value = "";
  }

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
	  formMediaManfile.removeTableItemAll();

    $('#signed_by').css("border", "1px solid var(--falcon-input-border-color)");
    $('#created_by').css("border", "1px solid var(--falcon-input-border-color)");
    $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
    $('#ssymbol').css("border", "1px solid var(--falcon-input-border-color)");
}


const formMediaManfile = new FormMedia("upload_mandoc_file");
formMediaManfile.setIconPath(root_path_mandoc+'assets/image/');
formMediaManfile.setAction(mandocfile_upload_mediafile);
formMediaManfile.setTranslate(media_trans);
formMediaManfile.showEnactRadioBtn(true);
formMediaManfile.showLabelAdd(false);
formMediaManfile.init();

formMediaManfile.addEventListener("confirmdel",(data)=>{
    deleteFileManOutgoing(data.id);
  });
formMediaManfile.addEventListener("upload_success",(data)=>{
// đưa id media vào input media_ids của form mandocfile
    $("#mandoc-media").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});

const formMediaMandocfile = new FormMedia("upload_file_mandocfile");
formMediaMandocfile.setIconPath(root_path_mandoc+'assets/image/');
formMediaMandocfile.setAction(mandocfile_upload_mediafile_new);
formMediaMandocfile.setTranslate(media_trans);
formMediaMandocfile.showStatus(false);
formMediaMandocfile.showEnactRadioBtn(true);
formMediaMandocfile.setEditStatus(true);

formMediaMandocfile.init();

formMediaMandocfile.addEventListener("confirmdel",(data)=>{
  
});
formMediaMandocfile.addEventListener("upload_success",(data)=>{
// đưa id media vào input media_ids của form mandocfile
    $("#form_add_document_infor").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});

function btnDeleteMediafile(modal) {
    $('#form_remove_mediafile').submit();
    $(`#${modal}`).modal('hide');
}
function deleteTrMediafile(id_tr_mediafile, id_mandocfile) {
    $(`#${id_tr_mediafile}`).remove();
    $(`input[name="media_ids[]"][value="${id_mandocfile}"]`).remove();
    data_tr_remove.push(id_tr_mediafile);
}

// Xử lý sự kiện click trên button
function deleteFileManOutgoing(id){
    action_del += `?aid=${id}`;
    let link = document.createElement('a');
    link.setAttribute('data-action',"delete");
    link.setAttribute('href',action_del);
    link.click();
}
// click preview mandoc
$(".preview-mandoc").on('click',(e)=>{
let mandocId = $(e.currentTarget).attr("data-id");
callGetMandocRemote(mandocId,"loadPreview");
showLoadding(true);
})

function loadPreview(mandoc, list_file){
    $("#render_mandoc_file").html('');
    showLoadding(false);
    if(!mandoc){
        return;
    }
    list_file.forEach(item=>{
        if (item.file_type == "image/png" || item.file_type == "image/jpeg") {
            $("#render_mandoc_file").append(`
                <div class="swiper-slide"><img style="width: 100%;" src="https://erp.bmtu.edu.vn/mdata/hrm/${item.file_name}" alt="" srcset=""></div>
            `);
        } else if (item.file_type == "application/pdf") {
            $("#render_mandoc_file").append(`
                <div class="swiper-slide"><iframe src="https://erp.bmtu.edu.vn/mdata/hrm/${item.file_name}" width="100%" style="height: 80vh;"></iframe></div>
            `);
        }
    })
    new Swiper('.swiper', {
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev',
          },
        slidesPerView: 1,
        paginationClickable: true,
        spaceBetween: 20,
    });
    $("#preview-title").html(mandoc.notes);
    $("#preview-modal").modal('show');
}
$("#save_file").on('click', function(){
    var input_radio = $('input[data-radio="radio_option"]:checked');

        for (let i = 0; i < input_radio.length; i++) {
            $("#mandoc-media").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
        }
    $("#mandoc-media").submit();
})
function clickEditMandocMedias(element, mandoc_id){
    
    showLoadding(true);
    $('#mandoc-media [name="mandoc_id"]').val(mandoc_id);
    formMediaMandocfile.removeTableItemAll();
    formMediaManfile.removeTableItemAll();
    callGetMandocRemote(mandoc_id,"loadMandocFile")
}

$("#btn_add_doc").on("click",function(){
    var err_add= $('#err_add');
    var notes= $('#notes').val();
    var sno= $('#sno').val();
    if(sno == ""){
        $('#sno').css('border','1px solid red');
        err_add.html(blank_contents);
        err_add.css("display", "block");
        return;
    } else if(notes == ""){
        $('#notes').css('border','1px solid red');
        err_add.html(blank_contents);
        err_add.css("display", "block");
        return;
    } else {
        err_add.css("display", "none");
        $('#notes').css("border", "1px solid var(--falcon-input-border-color)");
        $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
        $("#btn_add_doc").css("display","none");
        var input_radio = $('input[data-radio="radio_option"]:checked');

        for (let i = 0; i < input_radio.length; i++) {
            $("#form_add_document_release").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
        }

        $("#form_add_document_release").submit();
        $("#loading_button_add_doc_out").css("display","block")
    }
});

/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMandocFile(mandoc,files){
    formMediaManfile.removeTableItemAll();
	  formMediaMandocfile.removeTableItemAll();

    formMediaManfile.tableAddItems(files);
    showLoadding(false);
    $("#upload_file_mandoc").modal("show");
    $('tbody.list tr').each(function() {
        $(this).find('input[type="radio"]').prop('disabled', true);
      });
}

/**
 * call form controller
 * @param {boolean} success 
 */
function onSavedMandocFiles(success){
    //clear saved ids
    $('#mandoc-media [name="media_ids[]"]').remove()
    showLoadding(false);
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
$(document).ready(function() {
    // $('#mdepartment').on('change', function() {
    //   var departmentId = $(this).val();
    //   $.ajax({
    //     url: get_users_by_department_released_mandocs_path,
    //     method: 'get',
    //     data: { department_id: departmentId },
    //     success: function(data) {
    //       var usersArr = [];
    //       $.each(data, function(index, user) {
    //         usersArr.push('<option value="' + user.last_name +' '+ user.first_name + '">'  + user.last_name +' '+ user.first_name + '</option>');
    //       });
    //       $('#signed_by, #created_by').html(usersArr.join(''));
    //     }
    //   });
    // });
    initTinymce();
    $('#notes').on('click', function() {
        $('#notes').css("border", "1px solid var(--falcon-input-border-color)");
        $('#err_add').css("display", "none");
    });
    $('#sno').on('click', function() {
        $('#sno').css("border", "1px solid var(--falcon-input-border-color)");
        $('#err_add').css("display", "none");
    });
  });

function clickAgainRelease(mandoc, stype, department, user) {
    $('#modal-release-mandoc').modal('show');
    $('#mandoc_id_release').val(mandoc.id);
    $('.show_info_mandoc').html(`
        <h5>Thông tin văn bản:</h5>
        <div class="info_mandoc mt-2">
            <span>- <b>Trích yếu nội dung:</b> ${mandoc.contents}</span><br>
            <span>- <b>Số đi:</b> ${mandoc.sno}</span><br>
            <span>- <b>Loại văn bản:</b> ${stype}</span><br>
            <span>- <b>Gửi từ:</b> ${mandoc.sfrom}</span><br>
        </div>
        <h5 class="mt-4">Phòng ban/đơn vị được chọn ban hành:</h5>
        <div id="list_deparment_release">
        </div>
        <h5 class="mt-4">Nhân sự được chọn ban hành:</h5>
        <div id="list_user_release">
        </div>
    `);
    department.forEach(item=>{
        $('#list_deparment_release').append(`
            <span>- ${item}</span><br>
        `);
    })
    user.forEach(item=>{
        $('#list_user_release').append(`
            <span>- ${item.last_name} ${item.first_name}</span><br>
        `);
    })
 
    if (mandoc.publish_email_subject != null) {
        $('#subject_email').val(mandoc.publish_email_subject);
    }
    if (mandoc.publish_email_content != null) {
        tinymce.get("content_email").setContent(mandoc.publish_email_content);
    }

    // dat add 05/09/2023
    showLoadding(true);
	  formMediaMandocfile.removeTableItemAll();
    formMediaSendMailManfile.removeTableItemAll();
    callGetMandocRemote(mandoc.id,"loadMandocFileRelease","release");

}

function backFormRelease() {
    $('#modal-release-mandoc').modal('hide');
}


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

function initTinymce(){
    var tinymceOptions = {
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
      ...{selector: '#form_release_mandoc textarea#content_email'},
      ...tinymceOptions
    });
  
  }

//   Dat add 05/09/2023
const formMediaSendMailManfile = new FormMedia("upload_mandoc_file_release_mandoc");
formMediaSendMailManfile.setIconPath(root_path_mandoc+'assets/image/');
formMediaSendMailManfile.setAction(mandocfile_upload_mediafile);
formMediaSendMailManfile.showDeleteButton(true);
formMediaSendMailManfile.showStatus(false);
formMediaSendMailManfile.showEnactRadioBtn(true);
formMediaSendMailManfile.setTranslate(media_trans);
formMediaSendMailManfile.setEditStatus(true);
formMediaSendMailManfile.init();


formMediaSendMailManfile.addEventListener("confirmdel",(data)=>{
    deleteFileManOutgoing(data.id);
  });
formMediaSendMailManfile.addEventListener("upload_success",(data)=>{
// đưa id media vào input media_ids của form mandocfile
    $("#form_release_mandoc").append(`<input name="media_ids[]" value = "${data.id}" style="display: none"></input>`)
});


/**
 * Call from controller
 * @param {object} mandoc 
 * @param {[]} files 
 */
function loadMandocFileRelease(mandoc,files){
    formMediaSendMailManfile.removeTableItemAll();
    formMediaSendMailManfile.tableAddItems(files);
    showLoadding(false);
    $('tbody.list tr').each(function() {
        $(this).find('input[type="radio"]').prop('disabled', true);
      });
}

$("#vt_ban_hanh").click(function(){
    formMediaMandocfile.removeTableItemAll();
    formMediaManfile.removeTableItemAll();  
    var input_radio = $('input[data-radio="radio_option"]:checked');
    $('#form_release_mandoc .error_release').html("");
    $("#form_release_mandoc input[name='media_ids[]']").remove();
    $("#form_release_mandoc input[name='option_media[]']").remove();
    for (let i = 0; i < input_radio.length; i++) {
      var parts = input_radio[i].value.split('-');
      var value = parts[1];
      $("#form_release_mandoc").append(`<input name="media_ids[]" value="${value}" style="display: none">`);
      $("#form_release_mandoc").append(`<input name="option_media[]" value="${input_radio[i].value}" style="display: none">`);
    }

    var ds_ids_media = $('#form_release_mandoc input[name="media_ids[]"]').val();
    var subject_email = $('#subject_email').val();
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
        console.log(email_test);
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
        $("#vt_ban_hanh").prop("disabled", true);
        $("#form_release_mandoc").submit();
        showLoadding(true);
    }
});  

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