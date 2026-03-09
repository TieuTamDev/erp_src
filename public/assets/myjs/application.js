$(document).ready(function() {
  // scroll columns table H-anh
  $("table").not( "#tableleaverequest" ).addClass("resizable");
  (function($) {
    $('table.resizable').resizableColumns();
  })(jQuery);

  // open change Pw
  if(showChangePw){
    openResetPw(false);
  }else{
    // Show system popup
    $('#popup_show_system').modal('show');
  }

  // auto fix authenticity_token
  $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr('content'));

  // submit event
  $("#change-password-form").on('submit',(e)=>{
    let button = $("#btn-submit-change-password");
    button.find("#loadding").show();
    button.attr("style", 'color: var(--falcon-btn-disabled-color);pointer-events: none;background-color: var(--falcon-btn-disabled-bg);border-color: var(--falcon-btn-disabled-border-color);opacity: var(--falcon-btn-disabled-opacity);-webkit-box-shadow: none;box-shadow: none;');
  });

  // hide valid 
  $('#change-password-form input[data-type="pass"]').on('focus',(e)=>{
    clearValidForm();
  })

});

/**
 * Open popup reset password
 * @param {boolean} bClose show/hide close button
 */
function openResetPw(bClose = false){
  cleanFormPassword();
  if(bClose){
    $("#popup-change-pw .close-modal").show();
  }else{
    $("#popup-change-pw .close-modal").hide();

  }
  $("#popup-change-pw").modal("show");
}

// gobal confirm dialog
function openConfirmDialog(html,callback){
  let dialog = $('#capp-confirm-dialog');
  if(html != null && html != undefined){
    dialog.find('#message').html(html);
  }
  dialog.modal('show');

  dialog.find("#close").off().on('click',()=>{
      callback(false);
  });

  dialog.find("#confirm").off().on('click',()=>{
      callback(true);
  });
}

function toggleConfirmDialog(bshow){
  if (bshow == null || bshow == undefined){
    $('#capp-confirm-dialog').modal('toggle');
  }else{
    $('#capp-confirm-dialog').modal(bshow ? 'show':'hide');
  }
}

// do click link with:  href, method
function doClick(href,method){
  let link = document.createElement("a");
  link.href= href;
  link.setAttribute("data-method","delete");
  document.body.append(link);
  link.click();
}

function showLoadding(bShow){
  $("#loading_handle").css("display",bShow ? "flex" : "none");
}

function js_translate(key){
  if(!key){
    return "NO_TRANS";
  }
  let trans = $(`#translate [data-key="${key}"]`).attr("data-trans");
  if(!trans){
    trans = key;
  }
  return trans;
}

function validChangePassword(){
    let valid = {
      field:'',
      message:'',
      status:true
    }
    let old_pw = $(`#popup-change-pw input[name="password"]`).val();
    let new_pw = $(`#popup-change-pw input[name="new_password"]`).val();
    let confirm_pw = $(`#popup-change-pw input[name="confirm_password"]`).val();

    // lenght
    if(old_pw.length < 8){
      valid.field = 'password';
      valid.message = js_translate('Pwd_invalid_min_8');
      valid.status = false;
    }
    else if(new_pw.length < 8){
      valid.field = 'new_password';
      valid.message = js_translate('Pwd_invalid_min_8');
      valid.status = false;
    }
    // special character
    else if(!checkPassSpecial(new_pw)){
      valid.field = 'new_password';
      valid.message = js_translate("Pwd_invalid_symbol") + ` ! @ # $ % ^ & *...`;
      valid.status = false;
    }
    else if(!checkPassLow(new_pw)){
      valid.field = 'new_password';
      valid.message = js_translate('Pwd_invalid_contain_regurlar');
      valid.status = false;
    }
    else if(!checkPassCap(new_pw)){
      valid.field = 'new_password';
      valid.message = js_translate('Pwd_invalid_contain_upercase');
      valid.status = false;
    }
    else if(!checkPassNumber(new_pw)){
      valid.field = 'new_password';
      valid.message = js_translate('Pwd_invalid_contain_one_number');
      valid.status = false;
    }
    else if(confirm_pw != new_pw){
      valid.field = 'confirm_password';
      valid.message = js_translate('Pwd_invalid_confirm_pwd');
      valid.status = false;
    }

    return valid;
}

function showValidChangePass(field_name,message){
    // message
    let validshow = $(`#popup-change-pw [data-filed="${field_name}"]`)
    validshow.show();
    validshow.html(message);

    //field
    let input = $(`#popup-change-pw [data-wrap="${field_name}"]`);
    input.css("box-shadow", "inset 0px 0px 2px #e8216c");
    input.css("border","1px solid #f42f53");
}

function checkPassCap(pass){
    let regex = /^(?=.*[A-Z])/;
    return regex.test(pass);
}
function checkPassSpecial(pass){
    let regex = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;
    return regex.test(pass);
}
function checkPassNumber(pass){
    let regex = /^(?=.*\d)/;
    return regex.test(pass);
}
function checkPassLow(pass){
    let regex = /^(?=.*[a-z])/;
    return regex.test(pass);
}
// click show password icon
function clickShowPassword(element){
    // effect, class
    let icon = $(element);
    let status = icon.data("status");
    let bHide = status == 'hide';
    let next_status = bHide ? 'show': 'hide';
    let next_class = bHide ? 'far fa-eye-slash': 'far fa-eye';
    icon.attr("data-status",next_status);
    icon.attr('class',next_class);

    // input
    let name = icon.data("name");
    let input = $(`#popup-change-pw input[name="${name}"]`);
    let next_type = bHide ? 'text': 'password';
    input.attr("type",next_type)
}

function onClickSubmit(){
    clearValidForm();
    let valid = validChangePassword();
    if(!valid.status){
      showValidChangePass(valid.field,valid.message);
      return;
    }
    $('#change-password-form').submit();
}

// show valid from controller
function changePasswordResult(result){
  clearValidForm();

  if(!result.success){
    showValidChangePass(result.field,result.msg);
  }else{

    $('[data-name="valid-message"]').hide();
    $('[data-name="valid-message"]').html("");
    $("#popup-change-pw").modal('hide');
    // show alert
    showAlert(js_translate("Update_success"));
  }
  let button = $("#btn-submit-change-password");
  button.removeAttr("style");
  button.find("#loadding").hide();
}

function cleanFormPassword(){
  $("#change-password-form")[0].reset();
  clearValidForm();
}

function clearValidForm(){
  $(`#popup-change-pw [data-name="valid-message"]`).hide();
  $(`#popup-change-pw [data-name="valid-message"]`).html("");

  let inputWrap = $(`#popup-change-pw div[data-wrap]`);
  inputWrap.css("box-shadow", "");
  inputWrap.css("border","");

}
