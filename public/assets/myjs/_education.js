function clickCollapseEducationInfo(element){
  document.getElementById('collapse-education-icon-info').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
} 

  document.getElementById("id_cancel_add_school").onclick = function() {
    document.getElementById("id_add_school").style.display = "block";
    document.getElementById("id_cancel_add_school").style.display = "none";
   }
 
   document.getElementById("school_add_name").addEventListener("change", function () {
     var erro_labble_content_school = document.getElementById("erro_labble_content_school");
     var school_name_erro = document.getElementById("school_add_name");   
     erro_labble_content_school.style.display = "none";
     school_name_erro.style.border = "1px solid #ced4da";
   });
   
  //  document.getElementById("school_add_period").addEventListener("change", function () {
  //    var erro_labble_content_school = document.getElementById("erro_labble_content_school");
  //    var school_peroid_erro = document.getElementById("school_add_period");   
  //    erro_labble_content_school.style.display = "none";
  //    school_peroid_erro.style.border = "1px solid #ced4da";
  //  });
 
   document.getElementById("school_add_certificate").addEventListener("change", function () {
     var erro_labble_content_school = document.getElementById("erro_labble_content_school");
     var school_certificate_erro = document.getElementById("school_add_certificate");   
     erro_labble_content_school.style.display = "none";
     school_certificate_erro.style.border = "1px solid #ced4da";
   });

   document.getElementById("school_add_address").addEventListener("change", function () {
    var erro_labble_content_school = document.getElementById("erro_labble_content_school");
    var school_address_erro = document.getElementById("school_add_address");   
    erro_labble_content_school.style.display = "none";
    school_address_erro.style.border = "1px solid #ced4da";
  });
 
   document.getElementById('btn_add_new_school').onclick = function() {
   
   var erro_labble_content_school = document.getElementById("erro_labble_content_school");
   var school_name = document.getElementById("school_add_name").value;
   var school_name_erro = document.getElementById("school_add_name");
  //  var school_peroid = document.getElementById("school_add_period").value;
  //  var school_peroid_erro = document.getElementById("school_add_period");
   var school_certificate = document.getElementById("school_add_certificate").value;
   var school_certificate_erro = document.getElementById("school_add_certificate");
   var school_address = document.getElementById("school_add_address").value;
   var school_address_erro = document.getElementById("school_add_address");
  
 
 
    if (school_name == "") {
       erro_labble_content_school.innerHTML = strVaildSchoolName;
       erro_labble_content_school.style.display = "block";
       school_name_erro.style.border = "1px solid red"; 
       school_name_erro.focus();                    
    //  } else if (school_peroid == "") {
    //    erro_labble_content_school.innerHTML = strVaildSchoolPeroid;
    //    erro_labble_content_school.style.display = "block";
    //    school_peroid_erro.style.border = "1px solid red";
    //    school_name_erro.style.border = "1px solid #ced4da";
    //    school_peroid_erro.focus();
     } else if (school_certificate == "") {
       erro_labble_content_school.innerHTML = strVaildSchoolCertificate;
       erro_labble_content_school.style.display = "block";
       school_certificate_erro.style.border = "1px solid red";
       school_peroid_erro.style.border = "1px solid #ced4da";
       school_certificate_erro.focus();
     } else if (school_address == "") {
       erro_labble_content_school.innerHTML = "Vui lòng nhập thời gian cấp";
       erro_labble_content_school.style.display = "block";
       school_address_erro.style.border = "1px solid red";
       school_certificate_erro.style.border = "1px solid #ced4da";
       school_address_erro.focus();
     }      
     else {  
         school_address_erro.style.border = "1px solid #ced4da";
         erro_labble_content_school.style.display = "none";     
         document.getElementById("btn_add_new_school").type= "submit";
         document.getElementById("btn_add_new_school").style.display = "none";
         document.getElementById("loading_education").classList.remove("d-none");
         
     }
 
    
      
   }
   function openFormAddSchool (){
     document.getElementById("school_id").value = "";
     document.getElementById("school_apply_id").value = apply_id;
     document.getElementById("school_add_name").value ="";
     document.getElementById("school_add_period").value="";
     document.getElementById("school_add_certificate").value="";
     document.getElementById("school_add_address").value="";
     document.getElementById("school_add_ranking").value="";
     document.getElementById("id_add_school").style.display = "none";
     document.getElementById("id_cancel_add_school").style.display = "block";
     $('#no_term_cetificate').prop('checked', false);
   }
 
   function openFormUpdateSchool (id,apply_id,name,period,certificate,address,status,ranking,dtexpired){
   document.getElementById("form_add_education").classList.add("show");
   var school_id = document.getElementById("school_id");
   var apply_id = document.getElementById("school_apply_id");
   var school_name = document.getElementById("school_add_name");
   var school_peroid = document.getElementById("school_add_period");
   var school_certificate = document.getElementById("school_add_certificate");
   var school_ranking= document.getElementById("school_add_ranking");
   var school_address = document.getElementById("school_add_address");
   var school_status_ACTIVE = document.getElementById("school_add_ACTIVE");
   var school_status_INACTIVE = document.getElementById("school_add_INACTIVE");
 
     document.getElementById("id_add_school").style.display = "none";
     document.getElementById("id_cancel_add_school").style.display = "block";
 
     school_id.value = id;
     apply_id.value = apply_id;
     school_name.value = name;
     school_peroid.value = period;
     school_certificate.value = certificate;
     school_address.value = address;
     school_ranking.value = ranking;
     $('#term_cetificate').val(dtexpired);
     if (dtexpired == "") {
      $('#term_cetificate').val('Vô thời hạn');
      $('#no_term_cetificate').prop('checked', true);
    } else {
       $('#no_term_cetificate').prop('checked', false);

     }
     if(status == "ACTIVE"){
     school_status_ACTIVE.checked = true;
     }
     else {
     school_status_INACTIVE.checked = true;
     }
     document.getElementById("txt_education_title").scrollIntoView();

 
   }

   function clickDeleteEducation(id,name,user_id){
    let href = linkDeleteEducationName;
    href += `?id=${id}&uid=${user_id}`;
    let html = deleteMessageEducation +" "+ `<span style="font-weight: bold; color: red">${name}</span>?`;
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href,'delete')
      }
    });

  }