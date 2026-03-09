const formMediaContract = new FormMedia("upload_file_contract");
formMediaContract.setIconPath(iconImg);
formMediaContract.setTranslate(media_trans);
formMediaContract.init();
formMediaContract.addEventListener("confirmdel",(data)=>{
    deleteContract(data.id, data.uid);
});

function clickCollapseContract(element){
    document.getElementById('colapse-icon-contract').style.rotate = element.className.includes('collapsed') ? "unset" : "90deg";
}

$('#id_cancel_add_contract').click(function (){
    document.getElementById("id_add_contract").style.display = "block";
    document.getElementById("id_cancel_add_contract").style.display = "none";
});

/**
 * On change status 
 * @param {HTMLElement} element 
 */
function onChangeStatus(element){
  changeCheckboxState(element.checked);
}

function openFormAddContract() {

  $('#form_add_contract').trigger("reset");
  document.getElementById("id_add_contract").style.display = "none";
  document.getElementById("id_cancel_add_contract").style.display = "block";
  var today = new Date().toLocaleDateString();

  $('#contract_issued_date').val(today);
  $('#dt_dtfrom').val(today);
  $("#cls_bmtu_form_add_contract_title").html(newContract);
  $("#name-btn-contract").html(newContract);
  $("#button-contract-file").toggleClass("d-none",true);
}


function openFormUpdateContract(id, user_id, name, issued_date, issued_by, issued_place, dtfrom, dtto, status,base_salary, note, session_id_contract) {
    $("html, body").animate({scrollTop: 0}, 100);
    document.getElementById("collapse_form_add_contract").classList.add("show");
    document.getElementById("id_add_contract").style.display = "none";
    document.getElementById("id_cancel_add_contract").style.display = "block";

    document.getElementById("button-contract-file").classList.remove("d-none");
    $("#list-mediafile-contract tr").remove();
    let arrcontractFile = [];
    document.getElementById('erro_lable_contract').value = "";
    document.getElementById("cls_bmtu_form_add_contract_title").innerHTML = upContract;
    document.getElementById("name-btn-contract").innerHTML = upContract;

    // document.getElementById("select2-contract_issued_by-container").innerHTML = issued_by;
    document.getElementById("select2-contract_name-container").innerHTML = name;
    document.getElementById("select2-contract_issued_place-container").innerHTML = issued_place;

    changeCheckboxState(status == "ACTIVE");

    document.getElementById("contract_id").value = id;
    document.getElementById("contract_name").value = name;
    document.getElementById("contract_issued_date").value = issued_date;
    document.getElementById("contract_issued_by").value = issued_by;
    document.getElementById("contract_base_salary").value = money(base_salary);
    document.getElementById("contract_issued_place").value = issued_place;
    document.getElementById("dt_dtfrom").value = dtfrom;
    document.getElementById("dt_dtto").value = dtto;
    document.getElementById("contract_note").value = note;

    let action_upload_contract = actionUp;
  
    formMediaContract.setAction(action_upload_contract + "?contract_id="+ id);
    let idContract = document.getElementById("id_cont_btn").getAttribute("myidContract");
    // start show filemedia list
        $.ajax({
          type: "GET",
          url: urlContract,
          data: { idContract: session_id_contract },
          dataType: "JSON",
          success: function (response) {
                formMediaContract.removeTableItemAll();
                formMediaContract.tableAddItems(response.docs);
          }
      });
  //end     
    
}

/**
 * Change checkbox state
 * @param {boolean} bChecked 
 */
function changeCheckboxState(bChecked){
  $("#contract_status").prop("checked",bChecked);
  $("#status_label").html(bChecked ? "Có hiệu lực" : "Bản nháp");
  $("#status_label").attr('class', bChecked ? "text-success" : "text-500" );
}

function money(m) {
  m = m.toString().split('');
  for (var i = m.length - 3; i > 0; i -= 3)
      m.splice(i,0,",");

  return m.join('');
}
// check valid 
var erro_label_contract = document.getElementById('erro_lable_contract');

document.getElementById("contract_name").addEventListener("change", function () {

var name_contract = document.getElementById('contract_name');
var erro_label_contract = document.getElementById('erro_lable_contract');

erro_label_contract.style.display = "none";
name_contract.style.border = "1px solid #ced4da";
});

document.getElementById('btn_add_new_contract').onclick = function () {
updateDtto(document.getElementById("contract_issued_place"));
document.getElementById("btn_add_new_contract").type = "submit";
document.getElementById("name-btn-contract").style.display = "none"; 
document.getElementById("loading_button_contract").style.display = "block";
}
function clickEditMediaContract(contract_id, user_id){
  
  if($('#file-upload-contract-'+contract_id).html().length == 0){

    let action_upload = actionUp;
      var formmedia_edit_doc = new FormMedia("file-upload-contract-" + contract_id);
      formmedia_edit_doc.setAction(action_upload + "?contract_id="+ contract_id);
      formmedia_edit_doc.setIconPath(iconImg);
      formmedia_edit_doc.setTranslate(media_trans);
      formmedia_edit_doc.init();
      formmedia_edit_doc.addEventListener("confirmdel",(data)=>{
        deleteContract(data.id, data.uid);
      });
          
        $.ajax({
          type: "GET",
          url: urlContract,
          data: { idContract: contract_id },
          dataType: "JSON",
          success: function (response) {
              formmedia_edit_doc.removeTableItemAll();
              formmedia_edit_doc.tableAddItems(response.docs);
          }
      });
    }else{

    }

}
function deleteContract(doc_id,user_id){
  let action = delMed;
  action += `&did=${doc_id}&uid=${user_id}`;
  let link = document.createElement('a');
  link.setAttribute('data-action',"delete");
  link.setAttribute('href',action);
  link.click();
}


function clickDeleteContract(id,name,user_id){
  let href = conDel;
  href += `?id=${id}&uid=${user_id}`;

  let html = `${messDel} <span style="font-weight: bold; color: red">${name}</span>?`
  openConfirmDialog(html,(result )=>{
    if(result){
      doClick(href,'delete')
    }
  });

}

var id_add_contract = document.getElementById("id_add_contract")
if (id_add_contract) {
  id_add_contract.addEventListener("click", function() {
    updateDtto(document.getElementById("contract_issued_place"));
  });
}



function updateDtto(element) {  
  var str = $(element).find(':selected').attr("data-id");

  var pattern = /[0-9]/g;

  var num = str.search(pattern);

  var splitted = str.substring(num);
  
  var check2 = splitted.substr(0,1);

  var check = splitted.substr(2);
  if(check == "NAM"){
  	var mm = check2*12;
  } else if(check == "THANG"){
  	var mm = check2*1;
  } else{
    var nil = "";
  }
  
  let start = document.getElementById("dt_dtfrom").value;
  // Tách chuỗi thành các thành phần ngày, tháng và năm
  var [dayString, monthString, yearString] = start.split('/');

  // Chuyển đổi các chuỗi thành số nguyên
  var dayInput = parseInt(dayString);
  
  var monthInput = parseInt(monthString);
  
  var yearInput = parseInt(yearString);
  
  var end = new Date(yearInput, monthInput - 1, dayInput);
  
  
  end.setMonth(end.getMonth() + mm);
  var day = end.getDate();
  var month = end.getMonth()+1;
  var year = end.getFullYear();
  if (month < 10) month = "0" + month;
  if (day < 10) day = "0" + day;
  
  var dateend = day + "/" + month + "/" + year;
  document.getElementById("dt_dtto").innerHTML =  dateend;
  document.getElementById("dt_dtto").value =  dateend;
}


