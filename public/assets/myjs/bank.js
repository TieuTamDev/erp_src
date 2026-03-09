// 

  var error_label= document.getElementById('erro_labble_content_bank');
// update bank

  document.getElementById("id_cancel_add_bank").onclick = function() {
    document.getElementById("id_add_relative_bank").style.display = "block";
    document.getElementById("id_cancel_add_bank").style.display = "none";
    }
  function openFormUpdateBank(id,user_id,name, branch,address,ba_number,  ba_name,status) {
    document.getElementById("open_add_bank").classList.add("show");
    document.getElementById("id_add_relative_bank").style.display = "none";
    document.getElementById("id_cancel_add_bank").style.display = "block";

    document.getElementById("bank_id").value = id;
    document.getElementById("user_id").value = user_id;
    document.getElementById("txt_name_bank").value = name;
    document.getElementById("txt_branch_bank").value = branch;
    document.getElementById("txt_address_bank").value = address;
    document.getElementById("txt_ba_number").value = ba_number;
    document.getElementById("sel_bank_name_add").value = ba_name;

    if(status == "0"){
    document.getElementById("sel_bank_status_active").checked = true;
    }
    else {
      document.getElementById("sel_bank_status_inactive").checked = true;
    }
    document.getElementById("txt_bank_title").scrollIntoView();

  
  }
  //  add bank
    function openFormAddBank() {
        
            document.getElementById("id_add_relative_bank").style.display = "none";
            document.getElementById("id_cancel_add_bank").style.display = "block";
            document.getElementById("bank_id").value = "";
            document.getElementById("user_id").value = "";
            document.getElementById("txt_name_bank").value = "";
            document.getElementById("txt_branch_bank").value = "";
            document.getElementById("txt_address_bank").value = "";
            document.getElementById("txt_ba_number").value = "";

    }

        document.getElementById("txt_name_bank").addEventListener("change", function () {
        var error_label_bank = document.getElementById("erro_labble_content_bank");
        var name_erro_bank = document.getElementById("txt_name_bank");
        error_label_bank.style.display = "none";
        name_erro_bank.style.border = "1px solid #ced4da";
      });

        document.getElementById("txt_branch_bank").addEventListener("change", function () {
        var error_label_bank = document.getElementById("erro_labble_content_bank");
        var branch_erro_bank = document.getElementById("txt_branch_bank");
        error_label_bank.style.display = "none";
        branch_erro_bank.style.border = "1px solid #ced4da";
      });

        document.getElementById("txt_address_bank").addEventListener("change", function () {
        var error_label_bank = document.getElementById("erro_labble_content_bank");
        var address_erro_bank = document.getElementById("txt_address_bank");
        error_label_bank.style.display = "none";
        address_erro_bank.style.border = "1px solid #ced4da";
      });

        document.getElementById("txt_ba_number").addEventListener("change", function () {
        var error_label_bank = document.getElementById("erro_labble_content_bank");
        var ba_number_erro_bank = document.getElementById("txt_ba_number");
        error_label_bank.style.display = "none";
        ba_number_erro_bank.style.border = "1px solid #ced4da";
      });

            document.getElementById('btn_add_new_bank').onclick = function(){
              var error_label_bank= document.getElementById('erro_labble_content_bank');
              var name = document.getElementById('txt_name_bank').value;
              var name_erro = document.getElementById('txt_name_bank');
              var branch = document.getElementById('txt_branch_bank').value;
              var branch_erro = document.getElementById('txt_branch_bank');
              var address = document.getElementById('txt_address_bank').value;
              var address_erro = document.getElementById('txt_address_bank');
              var ba_number = document.getElementById('txt_ba_number').value;
              var ba_number_erro = document.getElementById('txt_ba_number');
              var ba_name = document.getElementById('sel_bank_name_add').value;
              var ba_name_erro = document.getElementById('sel_bank_name_add');
            
              if(branch == "") {
                error_label_bank.innerHTML = Please_enter_bank_branch;
                error_label_bank.style.display="block";
                branch_erro.style.border= "1px solid red";
              return;
              }
          
              else if (address == "") {
              error_label_bank.innerHTML = Please_enter_bank_address;
              error_label_bank.style.display="block";
              address_erro.style.border= "1px solid red";
              name_erro.style.border= "1px solid #ced4da";

              return;
              }

              else if (branch == "") {
                error_label_bank.innerHTML = Please_enter_bank_branch;
                error_label_bank.style.display="block";
                branch_erro.style.border= "1px solid red";
                address_erro.style.border= "1px solid #ced4da";
              return;
              }
              else if (name == "") {
                error_label_bank.innerHTML = Please_enter_bank_name;
                error_label_bank.style.display="block";
                name_erro.style.border= "1px solid red";
                branch.style.border= "1px solid #ced4da";
              return;
              }
              else if (ba_number == "") {
                error_label_bank.innerHTML = Please_enter_bank_ba_number;
                error_label_bank.style.display="block";
                ba_number_erro.style.border= "1px solid red";
                name_erro.style.border= "1px solid #ced4da";
              return;
              }
              else{
              document.getElementById('btn_add_new_bank').type="submit";
              document.getElementById("btn_add_new_bank").style.display = "none";
              document.getElementById("loading_button_bank").style.display = "block";
              }
          }
  function clickCollapseBank(element){
    document.getElementById('collapse-icon-bank').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
  }
                
