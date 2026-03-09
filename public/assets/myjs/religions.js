function checkNospace(value){
    if ( value != " "  &&  value.indexOf("  ") < 0 ){
        return true;
    }else{
        return false;
    }
}
document.getElementById("btn_add_new_religions_buttton").addEventListener("click", function() {
    document.getElementById("btn_add_new_religions_buttton").style.display = "none";
    document.getElementById("loading_button_religions").style.display = "block";
});

function getTextToASCII() {
    var value_name = document.getElementById("religions_name").value;
    var value_scode = document.getElementById("religion_scode");
    if (value_name) {
    var content = removeVietnameseTones(value_name).replace(/ /g, '-');
        if (value_scode) {
                    value_scode.value = content.toUpperCase()
                }
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

function delete_loading_religions(element){
element.style.display = "none"
element.previousElementSibling.style.display = "none"
element.nextElementSibling.style.display = "block"
}

var error_label = document.getElementById('erro_labble_content'); 
var sid_erro = document.getElementById('user_sid');

function openFormAddreligions() {
    // document.getElementById("form-add-religions-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = strCreateReligions;
    document.getElementById("religion_id").value = "";
    document.getElementById("religions_name").value = "";
    document.getElementById("religion_scode").value = "";    
    document.getElementById("religions_name").addEventListener("keyup", function() {getTextToASCII()} );

}

function closeFormAddreligions() {
    document.getElementById("form-add-religions-container").style.display = "none";
    document.getElementById("religion_id").value = "";
    document.getElementById("religions_name").value = "";
    document.getElementById("religion_scode").value = "";  
    document.getElementById("religions_name").style.border = "1px solid #ced4da";
    document.getElementById("religion_scode").style.border = "1px solid #ced4da";
    document.getElementById('erro_labble_content').style.display = "none";
}



function openFormUpdatereligions(id, name , scode, status) {
    // document.getElementById("form-add-religions-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = strUpdateReligions;
    document.getElementById("religion_id").value = id;
    document.getElementById("religions_name").value = name;
    document.getElementById("religion_scode").value = scode;
    document.getElementById("religions_name").addEventListener("keyup", function() {} );

    if(status == "ACTIVE"){
        document.getElementById("religions_status_active").checked = true;
    }
    else {
        document.getElementById("religions_status_inactive").checked = true;
    }

}
function checkNospace(value){
    if ( value != " "  &&  value.indexOf("  ") < 0 ){
        return true;
    }else{
        return false;
    }
}

$('#myModal').on('shown.bs.modal', function () {
$('#myInput').trigger('focus')
})
$('#search').bind('keypress keydown keyup', function(e){
    if(e.keyCode == 13) { e.preventDefault(); }
});
