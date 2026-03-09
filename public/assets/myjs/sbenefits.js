function delete_loading_sbenefits(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
  }

  function openFormAddsbenefits(list) {
    // document.getElementById("form-add-sbenefits-container").style.display = "block";
    document.getElementById("sbenefits_id_add").value = "";
    document.getElementById("sbenefits_syear_add").value = document.getElementById("sbenefits_syear_select").value;  
    let checkboxs = $("#select-sbenefit-name input")
    for (let i = 0; i < checkboxs.length; i++) {
    const element = checkboxs[i]; 
    element.checked = String(list).includes(element.value);
    }
  }

  document.getElementById("sbenefits_syear_select").addEventListener("change", function() {
    var Select_year = document.getElementById("sbenefits_syear_select").value;
    document.getElementById("sbenefits_syear_add").value = Select_year;  
    location.href = urlChosesYear +"&year="+ Select_year;
  
  
  });



  document.getElementById('btn_update_sbenefits_buttton').onclick = function(){
    document.getElementById('btn_update_sbenefits_buttton').style.display = "none";
    document.getElementById('loading_button_update_sbenefits').style.display = "block";
  }
  
  document.getElementById('btn_add_new_sbenefits_buttton').onclick = function(){
    document.getElementById('btn_add_new_sbenefits_buttton').style.display = "none";
    document.getElementById('loading_button_sbenefits').style.display = "block";
  }

  function closeFormAddsbenefits() {
    document.getElementById("form-add-sbenefits-container").style.display = "none";
    document.getElementById("sbenefits_id_add").value = "";
    document.getElementById("sbenefits_syear_add").value = "";
  }

 

  $('#myModal').on('shown.bs.modal', function () {
    $('#myInput').trigger('focus')
  })
    $('#search').bind('keypress keydown keyup', function(e){
      if(e.keyCode == 13) { e.preventDefault(); }
    });

  function numberWithCommas(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }

  function on_amount_change(input) {
      let value = input.value; // 10 | 1,000
  
      //  xoa ki tu k phai chu so
      value = value.replace(/\D/g, '');
  
      // check null, empty
      if (value == null || value.trim().length == 0) {
          value = "";
      }
  
      let input_number = "";
      let real_user_input = 0;
      //  lay so cua input
      input_number = value;
      // check valid:xx
  
  
      // format : add ","
      let format_input = (numberWithCommas(input_number));
      input.value = numberWithCommas(format_input);
  }
  function checkAllItemBenefitOther(isChecked) {
    if(isChecked) {
        $('input[type="checkbox"]').each(function() { 
            this.checked = true; 
        });
    } else {
        $('input[type="checkbox"]').each(function() {
            this.checked = false;
        });
    }
}

function getUserList(){
   var radio_NAM = document.getElementById('target_id_NAM');
   var radio_NU = document.getElementById('target_id_NU');  
   var target ;
   $("#loading_benefits").css("display", "flex"); 
   $("#loading_user").css("display", "flex");  


  if (radio_NAM.checked == true){
    target = "NAM"
  }else if (radio_NU.checked == true){
    target = "NU"
  }else {
    target = "TATCA"
  }

  var benefit_type = document.getElementById("user_benefits_type").value;
  var select_year = document.getElementById("selected_year").value;

  $.ajax({
      type: 'GET',
      url: urlGetUserList,
      data: { target: target, benefit_type: benefit_type ,select_year: select_year},
      dataType: "JSON",
      success: function (result) {  
        if (document.getElementById("tab_2").classList.contains("active") == true){
          document.getElementById("list_users").innerHTML = "";
          document.getElementById("btn_next").style.display = "block";
          for (let i = 0; i < result.result_users_list.length; i++) {
            document.getElementById("list_users").innerHTML +=
            `
            <td  class="align-middle white-space-nowrap">
              <label style="cursor: pointer;" for="user_id_${result.result_users_list[i].id}" class="form-check mb-0">
                  <input id="user_id_${result.result_users_list[i].id}" value="${result.result_users_list[i].id}" class="form-check-input users" style="margin-left: -1.8em !important; margin-top:0.5em !important"  type="checkbox" id="checkbox-1" data-bulk-select-row="data-bulk-select-row" checked/>
              </label>
            </td>
            <td class="fw-bold" style="text-align: left;cursor: pointer;white-space: nowrap;text-transform: capitalize;width:auto">
                <label for="user_id_${result.result_users_list[i].id}" style="margin: 0 auto;cursor: pointer; text-transform: capitalize;  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" class="">${result.result_users_list[i].sid}</label>
            </td>
            <td class="fw-bold" style="text-align: left;cursor: pointer;white-space: nowrap;text-transform: capitalize;width:auto">
                <label for="user_id_${result.result_users_list[i].id}" style="margin: 0 auto;cursor: pointer; text-transform: capitalize;  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" class="">${result.result_users_list[i].last_name} ${result.result_users_list[i].first_name}</label>
            </td>
            `
          }
          $("#loading_benefits").css("display", "none");        
          $("#loading_user").css("display", "none");
        }

        if (document.getElementById("tab_3").classList.contains("active") == true){
          document.getElementById("list-benefit").innerHTML = "";
          document.getElementById("btn_next").style.display = "none";
          document.getElementById("btn_submit").style.display = "block";
          $('#card-footer').removeClass('d-none');
          $('#tab_1 , #tab_2, #tab_3').removeAttr('data-bs-target');
          $('#tab_1 , #tab_2, #tab_3').removeAttr('data-bs-toggle');

          for (let i = 0; i < result.result_benefits_list.length; i++) {
            if (result.result_benefits_list[i].btype == "MONEY"){
              document.getElementById("list-benefit").innerHTML +=
              `
              <td  class="align-middle white-space-nowrap ">
                <label for="benefits_id_${result.result_benefits_list[i].id}" style="cursor: pointer;" class="form-check mb-0">
                    <input id="benefits_id_${result.result_benefits_list[i].id}"  value="${result.result_benefits_list[i].id}"  class="form-check-input benefit" style="margin-left: -1.8em !important; margin-top:0.5em !important"  type="checkbox" id="checkbox-1" data-bulk-select-row="data-bulk-select-row" checked/>
                </label>
              </td>
              <td class=" fw-bold" style="text-align: left;cursor: pointer;white-space: nowrap;text-transform: capitalize;width:auto">
                  <label for="benefits_id_${result.result_benefits_list[i].id}" style="margin: 0 auto;cursor: pointer; text-transform: capitalize;  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" class="">${result.result_benefits_list[i].name} </label>
              </td>
              <td class="fw-bold" style="text-align: left;cursor: pointer;white-space: nowrap;text-transform: capitalize;width:auto">
                  <label for="benefits_id_${result.result_benefits_list[i].id}" style="margin: 0 auto;cursor: pointer; text-transform: capitalize;  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" class="">${result.result_benefits_list[i].amount.toLocaleString('it-IT', {style : 'currency', currency : 'VND'})} </label>
              </td>
              `  
            }else {
              document.getElementById("list-benefit").innerHTML +=
              `
              <td  class="align-middle white-space-nowrap ">
                <label for="benefits_id_${result.result_benefits_list[i].id}" style="cursor: pointer;" class="form-check mb-0">
                    <input id="benefits_id_${result.result_benefits_list[i].id}"  value="${result.result_benefits_list[i].id}"  class="form-check-input benefit" style="margin-left: -1.8em !important; margin-top:0.5em !important"  type="checkbox" id="checkbox-1" data-bulk-select-row="data-bulk-select-row" checked/>
                </label>
              </td>
              <td class=" fw-bold" style="text-align: left;cursor: pointer;white-space: nowrap;text-transform: capitalize;width:auto">
                  <label for="benefits_id_${result.result_benefits_list[i].id}" style="margin: 0 auto;cursor: pointer; text-transform: capitalize;  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" class="">${result.result_benefits_list[i].name} </label>
              </td>
              <td class="fw-bold" style="text-align: left;cursor: pointer;white-space: nowrap;text-transform: capitalize;width:auto">
                  <label for="benefits_id_${result.result_benefits_list[i].id}" style="margin: 0 auto;cursor: pointer; text-transform: capitalize;  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" class="">${result.result_benefits_list[i].desc} </label>
              </td>
              ` 
            }
                
          }  
          $("#loading_user").css("display", "none");
          $("#loading_benefits").css("display", "none");        
        }
      }
  });

}

document.getElementById('btn_prev').onclick = function(){
  document.getElementById("btn_next").style.display = "block";
  document.getElementById("btn_submit").style.display = "none";  
}




document.getElementById('btn_submit').onclick = function(){
  $("#btn_close_modal_config").click();
  // var items= $('#list_users').find('.form-check-input:checkbox:checked');
  // var item_user=[];
  // var item_benefit=[];
  // for (let i = 0; i < items.length; i++) {
  //   item_user.push(items[i].value);
  // }
  // document.getElementById('userArray').value=item_user;
  // var benefit_item= $('#list-benefit').find('.form-check-input:checkbox:checked');
  // for (let i = 0; i < benefit_item.length; i++) {
  //   item_benefit.push(benefit_item[i].value);
  // }


  // document.getElementById('benefitArray').value=item_benefit;
  // document.getElementById("form_add_users_benefits").submit();
  // document.getElementById("loading_button_update_staff_sbenefits").style.display = "block";
  // $('#btn_submit').remove();
  
}

document.getElementById('btn_confirm').onclick = function(){
  var items= $('#list_users').find('.form-check-input:checkbox:checked');
  var item_user=[];
  var item_benefit=[];
  for (let i = 0; i < items.length; i++) {
    item_user.push(items[i].value);
  }
  document.getElementById('userArray').value=item_user;
  var benefit_item= $('#list-benefit').find('.form-check-input:checkbox:checked');
  for (let i = 0; i < benefit_item.length; i++) {
    item_benefit.push(benefit_item[i].value);
  }

  document.getElementById('benefitArray').value=item_benefit;
  document.getElementById("form_add_users_benefits").submit();
  document.getElementById("loading_button_update_staff_sbenefits").style.display = "block";
  $('#btn_confirm').remove();  
}



function checkAllUser(isChecked) {
  if(isChecked) {
      $('input.users[type="checkbox"]').each(function() { 
          this.checked = true; 
      });
  } else {
      $('input.users[type="checkbox"]').each(function() {
          this.checked = false;
      });
  }
}


function checkAllBenefit(isChecked) {
  if(isChecked) {
      $('input.benefit[type="checkbox"]').each(function() { 
          this.checked = true; 
      });
  } else {
      $('input.benefit[type="checkbox"]').each(function() {
          this.checked = false;
      });
  }
}
// 