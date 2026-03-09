const formMediaArchive = new FormMedia("upload_file_archive");
formMediaArchive.setIconPath(setIconPath);
formMediaArchive.setTranslate(media_trans);
formMediaArchive.init();
formMediaArchive.addEventListener("confirmdel",(data)=>{
  deleteArchive(data.id, data.uid);
});

$("#id_cancel_archive").click(function (){
  $('#id_cancel_archive').css({"display" : "none"});

  $("#btn-add-archive").css({"display" : "block"});
  $("#card-upload-mediafile_archive").css({"display" : "none"});
});

function clickCollapseArchive(element){
  document.getElementById('colapse-icon-archive').style.rotate = element.className.includes('collapsed') ? "unset" : "-90deg";
}
function delete_loading_archive(element){
  element.style.display = "none"
  element.previousElementSibling.style.display = "none"
  element.nextElementSibling.style.display = "block"
}
  
  function openFormAddArchive() {

    var date = new Date();
    var day = date.getDate();
    var month = date.getMonth() + 1;
    var year = date.getFullYear();
    
    if (month < 10) month = "0" + month;
    if (day < 10) day = "0" + day;

    document.getElementById('archive_id_add').value= '';
    document.getElementById('archive_name_add').value= '';
    $("#sel_archive_stype_add").prop("selectedIndex", 0).val();
    $("#sel_archive_issued_place_add").prop("selectedIndex", 0).val();
    $("#archive_issued_date_add").prop("selectedIndex", 0).val();
    document.getElementById("archive_issued_date_add").value = [day,month,year].join('/');
    document.getElementById("cls_bmtu_form_add_title_archive").innerHTML =Add_new_archive;
    document.getElementById("name-btn-archive").innerHTML = Add_archive;
    document.getElementById('archive_issue_id').value= '';
    document.getElementById("btn-colapse-archive-label").classList.add("d-none"); 
    $("#sel_archive_issue_level").prop("selectedIndex", 0).val();
  
    $('#id_cancel_archive').css({"display" : "block"});
  
    $("#btn-add-archive").css({"display" : "none"});
  
  };
  
  function closeFormAddArchive() {
    document.getElementById("form-add-archive-container").style.display ="none";
    document.getElementById("archive_name_add").value = "";
    document.getElementById('archive_name_add').style.border ="1px solid var(--falcon-input-border-color)";
    document.getElementById('erro_archive').style.display="none";
  };
  
  function openFormUpdateArchive(id, user_id, name, issued_place, stype, issue_date, status,issue_id,issue_type,issue_level, session_id_archive) {
    $("html, body").animate({scrollTop: 0}, 500);

    document.getElementById("form_archive").classList.add("show");
    document.getElementById("list-mediafile-archive").value = "";
    $('#id_cancel_archive').css({"display" : "block"});
  
    $("#btn-add-archive").css({"display" : "none"});
    $("#card-upload-mediafile_archive").css({"display" : "block"});
  
    document.getElementById("btn-colapse-archive-label").classList.remove("d-none"); 
    $("#list-mediafile-archive tr").remove();
  
  
    document.getElementById("cls_bmtu_form_add_title_archive").innerHTML = Update_archive;
    document.getElementById("name-btn-archive").innerHTML = Update_archive;
    document.getElementById("archive_id_add").value = id;
    document.getElementById("archive_user_id_add").value = user_id;
    document.getElementById("archive_name_add").value = name;
    document.getElementById("sel_archive_issued_place_add").value = issued_place;
    document.getElementById("sel_archive_stype_add").value = issue_type;
    document.getElementById("archive_issued_date_add").value = issue_date;
    document.getElementById("archive_issue_id").value = issue_id;
    document.getElementById("sel_archive_issue_level").value = issue_level;
          
    formMediaArchive.setAction(archive_upload_mediafile + "?archive_id="+ id);
  
    // start show filemedia list
    $.ajax({
      type: "GET",
      url: user_archive_edit_path,
      data: { idArchive: id },
      dataType: "JSON",
      success: function (response) {
        formMediaArchive.removeTableItemAll();
        formMediaArchive.tableAddItems(response.docs);
      }
    });
    //end
  };

// ở đây thêm mới
function clickEditMediaArchive(archive_id, user_id){
    
    if($('#file-upload-archive-'+archive_id).html().length == 0){
      var formmedia_edit_doc = new FormMedia("file-upload-archive-" + archive_id);
      formmedia_edit_doc.setAction(archive_upload_mediafile + "?archive_id="+ archive_id);
      formmedia_edit_doc.setIconPath(setIconPath);
      formmedia_edit_doc.setTranslate(media_trans);
      formmedia_edit_doc.init();
      formmedia_edit_doc.addEventListener("confirmdel",(data)=>{
        deleteArchive(data.id, user_id);
      });
          
        $.ajax({
          type: "GET",
          url: user_archive_edit_path,
          data: { idArchive: archive_id },
          dataType: "JSON",
          success: function (response) {
              formmedia_edit_doc.removeTableItemAll();
              formmedia_edit_doc.tableAddItems(response.docs);
          }
      });
    }else{

    }
}
  // ở đây thêm mới
  function deleteArchive(doc_id,user_id){
    action += `&did=${doc_id}&uid=${user_id}`;
    let link = document.createElement('a');
    link.setAttribute('data-action',"delete");
    link.setAttribute('href',action);
    link.click();
  }
  
  function showModalDeleteArchive(element) {
    let href = element.getAttribute("data-action");
    let name = element.getAttribute("data-name");
    $("#archive-confirm").find('#button_delete').attr('href',href);
    $("#archive-confirm").find('#modal-mesasge-delete-name').text(name);
    // show modal
    $("#archive-confirm").modal('show');
  
  }
  
  // 
  
  document.getElementById("btn_add_news_archive").onclick= function(){
    console.log(true);
    var name_archive= document.getElementById('archive_name_add').value;
    var border_err_name_archive= document.getElementById('archive_name_add');
    var error_label_archive = document.getElementById('erro_archive');
    if (name_archive=="") {
      error_label_archive.innerHTML=err_archive;
      error_label_archive.style.display= "block";
      border_err_name_archive.style.border ="1px solid red"
    }else{
      border_err_name_archive.style.boder ="1px solid var(--falcon-input-border-color)";
      error_label_archive.style.display= "none";
      document.getElementById("name-btn-archive").style.display = "none"; 
      document.getElementById("loading_button_archive").style.display = "block";
      document.getElementById('form_add_archive').submit();
    };
  };
  
  document.getElementById('archive_name_add').onchange = function(){
    var name_archive= document.getElementById('archive_name_add').value;
    var border_err_name_archive= document.getElementById('archive_name_add');
    var error_label_archive = document.getElementById('erro_archive');
    console.log(name_archive);
    if (name_archive=="") {
      error_label_archive.innerHTML=err_archive;
      error_label_archive.style.display= "block";
      border_err_name_archive.style.border ="1px solid red"
    }else{
      error_label_archive.style.display= "none";
      border_err_name_archive.style.border ="1px solid var(--falcon-input-border-color)";
    };
  };
  
  function clickDeleteArchive(id,name,user_id){
      href_archive += `?id=${id}&uid=${user_id}`;
  
      let html = `${mess_del}  <span style="font-weight: bold; color: red">${name}</span>?`
      openConfirmDialog(html,(result )=>{
        if(result){
          doClick(href_archive,'get')
        }
      });
  
    }
  // back to top
  $(window).scroll(function() {
    if ($(this).scrollTop()) {
        $('#btn_edit_item').fadeIn();
    } else {
        // $('#btn_edit_item').fadeOut();
    }
  });

  // <!-- released date 10/01/2023 -->
