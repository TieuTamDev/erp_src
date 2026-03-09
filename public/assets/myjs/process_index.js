
const formMediaMandocs = new FormMedia("upload_file_mandoc");
formMediaMandocs.setIconPath(root_path_mandoc+'assets/image/');
formMediaMandocs.setTranslate(media_trans);
formMediaMandocs.init();
formMediaMandocs.addEventListener("confirmdel",(data)=>{
    // action_del_mandoc += `&id=${data.relative_id}&did=${data.id}`;
    // doClick(action_del_mandoc,'delete');
});


function save_current_tab(current_tab){
  window.localStorage.setItem('current_tab', current_tab);
} 
var current_tab = window.localStorage.getItem('current_tab');

if(current_tab == "tab_2"){
  document.getElementById("processes_tab_1").classList.remove("show");
  document.getElementById("processes_tab_1").classList.remove("active");
  document.getElementById("page_documents_processed").classList.remove("active");
  document.getElementById("page_process_2").classList.add("active");
  document.getElementById("page_process_2").classList.add("show");
  document.getElementById("processes_tab_2").classList.add("active");
  $("#li_in_tab_2").click();
}

$("#li_in_tab_2").click(function() {
  var type = $("#submit_form_mandocs_status_process").attr("type");
  if (type=="submit"){
  $("#get_mandocs_status_processed").submit();
  $("#loading_screen").css("display", "flex");  
  $("#submit_form_mandocs_status_process").attr("type", "button");
  } 
});