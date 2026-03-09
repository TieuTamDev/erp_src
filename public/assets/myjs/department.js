$(document).ready(function() {
  $("#txt_issued_by").val("");
  $("#txt_leader_department").val("");
});
document.getElementById('btn_add_new_department').onclick = function(){
    var name = document.getElementById('txt_name_department').value;
    var name_erro = document.getElementById('txt_name_department');
    var scode = document.getElementById('txt_scode_department').value;
    var scode_erro = document.getElementById('txt_scode_department');
    var issued_id = document.getElementById('txt_issue_id_department').value;
    var issued_id_erro = document.getElementById('txt_issue_id_department');
    if(name == "") {
      error_label.innerHTML = Please_enter_department_name;
      error_label.style.display="block";
      name_erro.style.border= "1px solid red";
    return;
    }
    else if (scode == "") {
      error_label.innerHTML = Please_enter_department_scode;
      error_label.style.display="block";
      scode_erro.style.border= "1px solid red";
      name_erro.style.border= "1px solid #ced4da";
    return;
    }
   
    else if (txt_issue_id_department=="") {
    error_label.innerHTML = Please_enter_department_issued_id;
    error_label.style.display="block";
    issued_id_erro.style.border= "1px solid red";
    scode_erro.style.border= "1px solid #ced4da";
    return;
    }
    else{
    issued_id_erro.style.border= "1px solid #ced4da";
    document.getElementById('btn_add_new_department').type="submit";
    document.getElementById("name-btn-department").style.display = "none";
    document.getElementById("loading_button_department").style.display = "block";
    }
}