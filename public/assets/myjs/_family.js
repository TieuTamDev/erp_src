
 document.getElementById("id_cancel_add_famlily").onclick = function() {
    document.getElementById("id_add_relative").style.display = "block";
    document.getElementById("id_cancel_add_famlily").style.display = "none";
   }
 
   function save_relative_info(){
     document.getElementById("btn_add_new_relative").click();
   }
 
   document.getElementById("relative_add_name").addEventListener("change", function () { 
     var erro_labble_content_relative = document.getElementById("erro_labble_content_relative");
     var relative_name_erro = document.getElementById("relative_add_name");   
     erro_labble_content_relative.style.display = "none";
     relative_name_erro.style.border = "1px solid #ced4da";
   });

   document.getElementById("relative_add_id_card").addEventListener("change", function () { 
    var erro_labble_content_relative = document.getElementById("erro_labble_content_relative");
    var relative_id_card_erro = document.getElementById("relative_add_id_card");   
    erro_labble_content_relative.style.display = "none";
    relative_id_card_erro.style.border = "1px solid #ced4da";
  });

  document.getElementById("relative_add_identity_type").addEventListener("change", function () { 
    var id_card_type = document.getElementById("relative_add_identity_type").value;
    var id_card_lable = document.getElementById("relative_add_id_card_lable");

    if (id_card_type == "CCCD"){
      id_card_lable.innerHTML = strCCCDNumber;
    }else {
      id_card_lable.innerHTML = strCMNDNumber;
    };
    
  });
 
   document.getElementById('btn_add_new_relative').onclick = function() {
     var erro_labble_content_relative = document.getElementById("erro_labble_content_relative");
     var relative_name = document.getElementById("relative_add_name").value;
     var relative_name_erro = document.getElementById("relative_add_name");

     var relative_id_card = document.getElementById("relative_add_id_card").value;
     var relative_id_card_erro = document.getElementById("relative_add_id_card");
 
 
 
     if (relative_name == ""){
       erro_labble_content_relative.innerHTML = strRltNameVaild1;
       erro_labble_content_relative.style.display = "block";
       relative_name_erro.style.border = "1px solid red"; 
       relative_name_erro.focus();  
     } else if (relative_id_card == ""){
      erro_labble_content_relative.innerHTML = strCMNDVaild;
       erro_labble_content_relative.style.display = "block";
       relative_id_card_erro.style.border = "1px solid red"; 
       relative_id_card_erro.focus(); 
     }
     else {
         erro_labble_content_relative.style.display = "none";
         relative_id_card_erro.style.border = "1px solid #ced4da"; 
         document.getElementById("btn_add_new_relative").type= "submit";
         document.getElementById("btn_add_new_relative").style.display = "none";
         document.getElementById("loading_relative").classList.remove("d-none");        
     }
    
 
   }
 
   function openFormAddRelative (){
    var date = new Date();
    var day = date.getDate();
    var month = date.getMonth() + 1;
    var year = date.getFullYear();

    if (month < 10) month = "0" + month;
    if (day < 10) day = "0" + day;

    var today = day + "/" + month + "/" + year;
    var today1 = day + "/" + month + "/" + (year+40);

     document.getElementById("relative_add_id_card_lable").innerHTML = strCCCDNumber;
     document.getElementById("relative_add_identity_type").value = "CCCD";
     document.getElementById("relative_add_id").value = "";
     document.getElementById("relative_add_birthday").value = "01/01/2002";
     document.getElementById("relative_add_apply_id").value = applyId;
     document.getElementById("relative_add_name").value ="";
     document.getElementById("relative_add_phone").value="";
     document.getElementById("relative_add_email").value="";
     document.getElementById("relative_add_note").value="";
     document.getElementById("relative_add_id_card").value="";
     document.getElementById("relative_add_tax_code").value="";
     document.getElementById("relative_add_inden_start_date").value=today;
     document.getElementById("relative_add_inden_end_date").value=today1;
     document.getElementById("relative_add_id_card_Issued_place").value="";
     document.getElementById("id_add_relative").style.display = "none";
     document.getElementById("id_cancel_add_famlily").style.display = "block";
   }
 
   function openFormUpdateRelative (id,apply_id,name,birthday, phone,email,stype,state,note,status,
    identity,identity_type,identity_date,identity_place,taxid,identity_expired){
       document.getElementById("form_add_relative").classList.add("show");
       var relative_id = document.getElementById("relative_add_id");
       var apply_id = document.getElementById("relative_add_apply_id");
       var relative_name = document.getElementById("relative_add_name");
       var relative_birthday = document.getElementById("relative_add_birthday");
       var relative_phone = document.getElementById("relative_add_phone");
       var relative_email = document.getElementById("relative_add_email");
       var relative_stype = document.getElementById("relative_add_stype");
       var relative_note = document.getElementById("relative_add_note");
       var relative_status_ACTIVE = document.getElementById("relative_add_ACTIVE");
       var relative_status_INACTIVE = document.getElementById("relative_add_INACTIVE");
       var relative_state_Live = document.getElementById("relative_state_live");
       var relative_state_Death = document.getElementById("relative_state_death");

       document.getElementById("relative_add_identity_type").value=identity_type;
       document.getElementById("relative_add_id_card").value=identity;
       document.getElementById("relative_add_tax_code").value=taxid;
       document.getElementById("relative_add_inden_start_date").value=identity_date;
       document.getElementById("relative_add_inden_end_date").value=identity_expired;
       document.getElementById("relative_add_id_card_Issued_place").value=identity_place; 
       document.getElementById("id_add_relative").style.display = "none";
       document.getElementById("id_cancel_add_famlily").style.display = "block";
 
         relative_id.value = id;
         apply_id.value = apply_id;
         relative_name.value = name;
         relative_birthday.value = birthday;
         relative_phone.value = phone;
         relative_email.value = email;
         relative_stype.value = stype;
         relative_note.value = note;
 
         if(status == "ACTIVE"){
         relative_status_ACTIVE.checked = true;
         }
         else {
         relative_status_INACTIVE.checked = true;
         }
         if(state == "L"){
         relative_state_Live.checked = true;
         }
         else {
         relative_state_Death.checked = true;
         }
   }

   
   function clickDeleterelative(id,name,user_id){
    let href = linkDeleteRelativeName;
    href += `?id=${id}&uid=${user_id}`;
    let html = deleteMessageRelative +" "+ `<span style="font-weight: bold; color: red">${name}</span>?`;
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href,'delete')
      }
    });

  }