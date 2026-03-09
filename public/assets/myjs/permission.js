// function isempty(value){
//     if ( value != " "  &&  value.indexOf(" ") < 0 ){
//         return false;
//     }else{
//         return true;
//     }
// }
function openFormAddPer() {
    //   document.getElementById("form-add-per-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_per_title").innerHTML = newPer;
    document.getElementById("btn_add_new_per").value = newPer;
    document.getElementById("sel_per_status_active").checked = true;
    document.getElementById("per_id").value = "";
    document.getElementById("per_name").value = "";
    document.getElementById("per_scode").value = "";
    document.getElementById('erro_lable_per').value = "";
    document.getElementById('erro_lable_per').style.display = "none";  
    document.getElementById('per_name').style.border = "1px solid #ced4da"
    document.getElementById('per_scode').style.border = "1px solid #ced4da"
    document.getElementById("btn_add_new_per").disabled = false;
    document.getElementById("per_id").value = "";
  }

  function closeFormAddPer() {
    document.getElementById("form-add-per-container").style.display = "none";
    document.getElementById("per_name").value = "";
    document.getElementById("per_scode").value = "";
    document.getElementById('erro_lable_per').value = "";
    document.getElementById('erro_lable_per').style.display = "none";  
    document.getElementById('per_name').style.border = "1px solid #ced4da"
    document.getElementById('per_scode').style.border = "1px solid #ced4da"
    document.getElementById("btn_add_new_per").disabled = false;
    document.getElementById("per_id").value = "";

  }

  function openFormUpdatePer(id, name, scode, status) {
      document.getElementById('erro_lable_per').value = "";
    //   document.getElementById("form-add-per-container").style.display = "block";        
      document.getElementById("cls_bmtu_form_add_per_title").innerHTML = upPer;
      document.getElementById("btn_add_new_per").value = upPer;

      if(status == "ACTIVE"){
        document.getElementById("sel_per_status_active").checked = true;
      }
      else {
        document.getElementById("sel_per_status_inactive").checked = true;
      }
      document.getElementById("per_id").value = id;
      document.getElementById("per_name").value = name;
      document.getElementById("per_scode").value = scode;
  }

  var erro_lable_per = document.getElementById('erro_lable_per');

  function toUpperCaseScode() {
    document.getElementById("per_scode").value = document.getElementById("per_scode").value.toUpperCase();
  }
  // (function($) {
  //   $(document.getElementById("per_scode").addEventListener("keyup",function(){
  //       var per_scode_error = document.getElementById('per_scode');
  //       var per_scode = document.getElementById('per_scode').value;
  //       per_scode = per_scode.toUpperCase();
  //       var pId = document.getElementById('per_id').value;
  //     $.ajax({
  //       data: { check_pername: per_scode, per_id: pId},
  //       type: 'GET',
  //       url: linkCheck,
  //       dataType:"JSON",
  //       success: function (response) {
  //               if (response.msg == 'true' && response.scode !='') {
  //                   erro_lable_per.innerHTML= erroPer;
  //                   erro_lable_per.style.display = "block"
  //                   per_scode_error.style.border="1px solid red"
  //                   document.getElementById("btn_add_new_per").disabled = true;
  //               }else if (response.results == 'true'){
  //                   erro_lable_per.innerHTML= erroPer;
  //                   erro_lable_per.style.display = "block"
  //                   per_scode_error.style.border="1px solid red"
  //                   document.getElementById("btn_add_new_per").disabled = true;
  //               }else if (response.result == 'false'){
  //                   // document.getElementById('btn_add_new_per').submit();
  //               }else if(response.results == 'false'){
  //                   // document.getElementById('btn_add_new_per').submit();
  //               }else {
  //                   // document.getElementById('btn_add_new_per').submit();
  //               }
  //       }
  //     });
  //   }));
  //   })(jQuery);
    document.getElementById("per_scode").addEventListener("keyup", function () {

    var per_scode_error = document.getElementById('per_scode');
    var per_scode = document.getElementById('per_scode').value;
    per_scode = per_scode.toUpperCase();
    var pId = document.getElementById('per_id').value;
    jQuery.ajax({
        data: { check_pername: per_scode, per_id: pId},
        type: 'GET',
        url: linkCheck,
        dataType:"JSON",
        success: function (response) {
                if (response.msg == 'true' && response.scode !='') {
                    erro_lable_per.innerHTML= erroPer;
                    erro_lable_per.style.display = "block"
                    per_scode_error.style.border="1px solid red"
                    document.getElementById("btn_add_new_per").disabled = true;
                }else if (response.results == 'true'){
                    erro_lable_per.innerHTML= erroPer;
                    erro_lable_per.style.display = "block"
                    per_scode_error.style.border="1px solid red"
                    document.getElementById("btn_add_new_per").disabled = true;
                }else if (response.result == 'false'){
                    // document.getElementById('btn_add_new_per').submit();
                }else if(response.results == 'false'){
                    // document.getElementById('btn_add_new_per').submit();
                }else {
                    // document.getElementById('btn_add_new_per').submit();
                }
        }
    });
    erro_lable_per.style.display = "none";
    per_scode_error.style.border = "1px solid #ced4da";
    document.getElementById("btn_add_new_per").disabled = false;
    });

    document.getElementById('btn_add_new_per').onclick = function () {

    var per_scode = document.getElementById('per_scode').value;
    var per_scode_error = document.getElementById('per_scode');

        if(per_scode == ""){
            erro_lable_per.innerHTML = erroScode;
            erro_lable_per.style.display = "block";
            per_scode_error.style.border = "1px solid red";
            document.getElementById("btn_add_new_per").disabled = true;
            return;
        }else {
            per_scode_error.style.border = "1px solid #d8e2ef";
            erro_lable_per.style.display = "none";                    
        }
    // if(isempty(per_scode) == true) {
    //     erro_lable_per.innerHTML = "<%= lib_translate('Please_do_not_enter_spaces')%>";
    //     erro_lable_per.style.display = "block";
    //     per_scode_error.style.border = "1px solid red";
    //     document.getElementById("btn_add_new_per").disabled = true;
    //     return;                
    // }
    document.getElementById("btn_add_new_per").style.display = "none"; 
    document.getElementById("loading_button_per").style.display = "block";
    document.getElementById("btn_add_new_per").type = "submit";            
    document.getElementById("btn_add_new_per").disabled = false;

    };

    $("#myModal").on("shown.bs.modal", function () {
      $("#myInput").trigger("focus");
    });