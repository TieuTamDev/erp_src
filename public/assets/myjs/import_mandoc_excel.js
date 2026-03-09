// init import form event
function initImportFile(){
  // On file selected
  $("#file-import-user").on('change',(e)=>{
    let file = $("#file-import-user")[0].files[0];
    if(file != undefined && file != null){
      $("#import-file-containter").show();
      $("#button-upload-file").toggleClass("btn-secondary disabled",false);
      $("#file-process").css("width","0%");
      $("#import-file-size").html(formatBytes(file.size));
      $("#import-file-name").html(file.name);
    }
  })
}
initImportFile();

/**
 * Call when click import file
 */
function clickOpenImport(){
  // clean form
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let reUpload = $("#reupload-button");
  $("#import-file-containter").hide();
  uploadBtn.toggleClass("disabled",true);
  uploadBtn.show();
  selectBtn.toggleClass("disabled",false);
  selectBtn.show();
  reUpload.hide();

  $("#file-import-user").val(null);
  $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr("content"));
  $('#import-result').collapse("hide");
  uploadBtn.find(".upload-text").show();
  uploadBtn.find(".upload-process").hide();

  $("#update_list").html("");
  $("#error_list").html("");
  $("#import-server-error").hide();
}

/**
 * Click upload file to server
 */
function clickImportFile(){
  let file = $("#file-import-user")[0].files[0];
    if(file != undefined && file != null){
      
      let uploadBtn = $("#button-upload-file");
      let selectBtn = $("#label-select-file");
    
      // disable cancel when on process
      $(".button-cancel-import").toggleClass("disabled",true);

      // process state: 2
      uploadBtn.toggleClass("disabled",true);
      selectBtn.toggleClass("disabled",true);
      selectBtn.toggleClass("btn-secondary disabled",true);
      uploadBtn.find(".upload-text").html(trans_uploading);
      uploadBtn.find(".upload-process").show();

      // send file
      sendImportFile(file);

      document.getElementById("btn_close").setAttribute("onclick","reloadPage('blah');");
      document.getElementById("btn_X").setAttribute("onclick","reloadPage('blah');");
    }
}

function reloadPage() {
  window.location.reload();
}

function clickReupload(){
  let resultShow = $('#import-result');
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let reUpload = $("#reupload-button");

  $("#import-file-containter").hide();
  resultShow.collapse('hide');
  uploadBtn.toggleClass("btn-secondary disabled",true);
  uploadBtn.find(".upload-text").html(trans_upload + `<span class="fas fa-upload ms-1"></span>`);
  reUpload.hide();
  uploadBtn.show();
  selectBtn.show();

  $("#update_list").html("");
  $("#error_list").html("");
  $("#import-server-error").hide();
}


let import_update_list = [];
function renderResult(result){
  import_update_list = result.updates;
  // disable cancel when upload done
  $(".button-cancel-import").toggleClass("disabled",false);
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let resultShow = $('#import-result');
  let reUpload = $("#reupload-button");

  uploadBtn.toggleClass("btn-secondary disabled",true);
  uploadBtn.find(".upload-text").html(trans_upload);
  uploadBtn.find(".upload-process").hide();
  uploadBtn.hide();
  
  selectBtn.toggleClass("disabled",false);
  selectBtn.hide();

  reUpload.show();

  $("#file-import-user").val(null);
  //  load data
  $("#result_total").html(result.result_total);
  $("#success_count").html(result.success_count);
  let valids = result.valids;
  let error_count = $("#error_count");
  error_count.html(valids.length);
  error_count.toggleClass("text-400",valids.length <= 0);

  // update
  let update_count = $("#update_count");
  update_count.html(import_update_list.length);
  update_count.toggleClass("text-400",import_update_list.length <= 0);

  // errors
  let error_list = $("#error_list");
  error_list.html("");
  valids.forEach(valid=>{
    error_list.append(`<p class="m-0">
                        <span class="badge me-1 badge-soft-danger">${valid.line}</span>
                      </p>`);
  })
  resultShow.collapse('show');

}

/**
 * Handle update duplicate import
 * @param {any} userId
 */
function updateImport(userId){
  // get user data
  let user = null
  import_update_list.forEach(item=>{
    if(item.id === userId){
      user = item;
    }
  })

  if(user == null){
    console.log("Not find :",userId)
    return;
  }
  submitUpdateImportForm(`#update-import-${userId}`,[user]);

}

function submitUpdateImportForm(itemId,data){
  // pass data to remote form
  let uploadForm = $("#update_import_form");
  uploadForm.find("#datas").attr("value", JSON.stringify(data))

  $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr("content"));
  // submit
  uploadForm.submit();

  // upload button effect
  if (itemId != null){
    let itemContainer = $(itemId);
    itemContainer.find(".text-update").hide();
    itemContainer.find(".process-update").show();
  
    // all button effect
    itemContainer.find(".btn-action").toggleClass("disabled",true);
    itemContainer.find(".error-message").hide();
  }else{
    let list_item = $("#update_list");

    list_item.find(".text-update").hide();
    list_item.find(".process-update").show();
    // all button effect
    list_item.find(".btn-action").toggleClass("disabled",true);
    list_item.find(".error-message").hide();
  }
}

/**
 * Handle update all duplicate import
 */
function uploadAllImport(){
  submitUpdateImportForm(null,import_update_list);
}

/**
 * Onclick Skip update
 * @param {any} userId 
 */
function skipUpdate(userId){
  // remove store user
  for (let i = 0; i < import_update_list.length; i++) {
    if(userId == import_update_list[i].id){
      import_update_list.splice(i, 1);
      break;
    }
  }
  // remove element
  $(`#update-import-${userId}`).remove();

  // count
  $("#update_count").html(import_update_list.length);

  if(import_update_list.length > 0){
    $("#update-all-button").show();
  }else{
    $("#update-all-button").hide();
  }
}

/**
 * Call from back end
 */
function resultUpdateImport(result){
  result.updateds.forEach(update=>{

    for (let i = 0; i < import_update_list.length; i++) {
      if(update.id == import_update_list[i].id){
        import_update_list.splice(i, 1);
        break;
      }
    }

    let wrapContainer = $(`#update-import-${update.id}`);
    wrapContainer.find(".icon-done").show();
    wrapContainer.find(".btn-action").remove();
  });

  result.errors.forEach(item=>{
    
    let wrapContainer = $(`#update-import-${item.id}`);
    // update button
    wrapContainer.find(".text-update").show();
    wrapContainer.find(".process-update").hide();
    // all action button
    wrapContainer.find(".btn-action").toggleClass("disabled",false);
    // show error message
    wrapContainer.find(".error-message").show();
    wrapContainer.find(".error-message").html(item.message);
  })
}

/**
 * Send file to backend action
 * @param {File} file 
 */
function sendImportFile(file){

  let processItem = $("#file-process");

  let formdata = new FormData();
  formdata.append("file",file);
  formdata.append("authenticity_token",$('meta[name="csrf-token"]').attr("content"));

  var request = new XMLHttpRequest();
  request.onreadystatechange = function(){
      if(request.readyState == 4 && request.status >= 200 && request.status <= 299){
          try {
            let result = JSON.parse(request.responseText);
            if (result.code >= 400){
              showServerError();
            }else{
              renderResult(result);
            }
          } catch (e){
            console.log(e)
            showServerError();
          }
      }
      else if(request.status >= 400 && request.readyState == 4){
        try{
          let result = JSON.parse(request.responseText);
        }catch(e){
          console.log(e);
        }
        showServerError();
      }
  };

  request.upload.addEventListener('progress', function(e){
      var progress_width = Math.ceil(e.loaded/e.total * 100);
      processItem.css("width",`${progress_width}%`);
      if(progress_width == 100){
        setTimeout(() => {
          $("#import-file-containter").hide();
          processItem.css("width","0%");
          $("#button-upload-file").find(".upload-text").html(trans_processing);
        }, 400);
      }
  }, false);

  let action = $("#import-action").html();
  request.open('POST', action);
  request.send(formdata);
}

function showServerError(){
  $(".button-cancel-import").toggleClass("disabled",false);
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let resultShow = $('#import-result');
  let reUpload = $("#reupload-button");


  uploadBtn.toggleClass("btn-secondary disabled",true);
  uploadBtn.find(".upload-text").html(trans_upload);
  uploadBtn.find(".upload-process").hide();
  uploadBtn.hide();
  
  selectBtn.toggleClass("disabled",false);
  selectBtn.hide();

  reUpload.show();

  $("#file-import-user").val(null);
  $("#update_list").html("");
  $("#error_list").html("");
  resultShow.collapse('hide');
  $("#import-server-error").show();
}

/**
 * Fortmat file size
 * @param {*} a Fiel size
 * @param {*} b 
 * @param {*} k 
 * @returns 
 */
function formatBytes(a,b=2,k=1024)
{
    let d=Math.floor(Math.log(a)/Math.log(k));
    return 0 == a ? "0 Bytes" : parseFloat((a/Math.pow(k,d)).toFixed(Math.max(0,b)))+" "+["Bytes","KB","MB","GB","TB","PB","EB","ZB","YB"][d]
}
