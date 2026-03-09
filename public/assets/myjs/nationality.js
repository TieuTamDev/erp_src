function getTextToASCII() {
    var nationality_name = document.getElementById("nationality_name").value;
    var nationality_scode = document.getElementById("nationality_scode");
    if (nationality_name) {
    var content = removeVietnameseTones(nationality_name).replace(/ /g, '-');
        content = content.replace('---', '-');
        nationality_scode.value = content.toUpperCase()
    }
}
function removeVietnameseTones(str) {
      str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g,"a"); 
      str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g,"e"); 
      str = str.replace(/ì|í|ị|ỉ|ĩ/g,"i"); 
      str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g,"o"); 
      str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g,"u"); 
      str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g,"y"); 
      str = str.replace(/đ/g,"d");
      str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
      str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
      str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
      str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
      str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
      str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
      str = str.replace(/Đ/g, "D");
      // Some system encode vietnamese combining accent as individual utf-8 characters
      // Một vài bộ encode coi các dấu mũ, dấu chữ như một kí tự riêng biệt nên thêm hai dòng này
      str = str.replace(/\u0300|\u0301|\u0303|\u0309|\u0323/g, ""); // ̀ ́ ̃ ̉ ̣  huyền, sắc, ngã, hỏi, nặng
      str = str.replace(/\u02C6|\u0306|\u031B/g, ""); // ˆ ̆ ̛  Â, Ê, Ă, Ơ, Ư
      // Remove extra spaces
      // Bỏ các khoảng trắng liền nhau
      str = str.replace(/ + /g," ");
      str = str.trim();
      // Remove punctuations
      // Bỏ dấu câu, kí tự đặc biệt
      str = str.replace(/!|@|%|\^|\*|\(|\)|\+|\=|\<|\>|\?|\/|,|\.|\:|\;|\'|\"|\&|\#|\[|\]|~|\$|_|`|-|{|}|\||\\/g," ");
      return str;
}
function delete_loading_nationality(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
}
function openFormAddNationality() { 
    // document.getElementById("form-add-nationality-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = create_translate;
    document.getElementById("btn_add_new_nationality_buttton").value = create_translate;
    document.getElementById("nationality_id").value = "";
    document.getElementById("nationality_name").value = ""; 
    document.getElementById("nationality_scode").value = ""; 
    document.getElementById("nationality_name").addEventListener("keyup", function() {getTextToASCII()} );
    document.getElementById("nationality_name").addEventListener("change", function() {getTextToASCII()} );
}

function closeFormAddNationality() {
    document.getElementById("form-add-nationality-container").style.display = "none";
    document.getElementById("nationality_id").value = "";
    document.getElementById("nationality_name").value = "";
    document.getElementById("nationality_scode").value = "";  
}

function openFormUpdateNationality(id, name, scode, status) { 
    // document.getElementById("form-add-nationality-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = update_translate;
    document.getElementById("btn_add_new_nationality_buttton").value = update_translate;
    document.getElementById("nationality_id").value = id;
    document.getElementById("nationality_name").value = name;
    document.getElementById("nationality_scode").value = scode;
    document.getElementById("nationality_name").addEventListener("keyup", function() {} );
    document.getElementById("nationality_name").addEventListener("change", function() {} );
    if(status == "ACTIVE"){
    document.getElementById("nationality_status_active").checked = true;
    }
    else {
    document.getElementById("nationality_status_inactive").checked = true;
    }
}
document.getElementById('btn_add_new_nationality_buttton').onclick = function () {
    document.getElementById("btn_add_new_nationality_buttton").style.display = "none";
    document.getElementById("loading_button_nationality").style.display = "block";
    document.getElementById("btn_add_new_nationality_buttton").type = "submit";
}
$('#search').bind('keypress keydown keyup', function(e){
  if(e.keyCode == 13) { e.preventDefault(); }
});