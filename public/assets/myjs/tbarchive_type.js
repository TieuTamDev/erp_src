function getTextToASCII() {
    var value_name = document.getElementById("tbarchivetype_name_add").value;
    var value_scode = document.getElementById("tbarchivetype_scode_add");
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
// close modal create 
function openFormTbarchivetype() {
    // document.getElementById("form-add-tbarchivetype-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = title_add;
    document.getElementById("btn_add_new_tbarchivetype_buttton").value = title_add;
    document.getElementById("tbarchivetype_name_add").addEventListener("keyup", function() {getTextToASCII()} );
    $('#tbarchivetype_name_add').val("");
    $('#tbarchivetype_name_add').css({"border": "1px solid var(--falcon-input-border-color)"});
    $('#tbarchivetype_scode_add').val("");
    $('#tbarchivetype_status_active' ).prop('checked',true);
    $('#erro_labble_content').css({'display':'none'});
}

// close modal update
function closeFormAddTbarchivetype() {
    document.getElementById("form-add-tbarchivetype-container").style.display = "none";
    $('#tbarchivetype_name_add').val("");
    $('#tbarchivetype_name_add').css({"border": "1px solid var(--falcon-input-border-color)"});
    $('#tbarchivetype_scode_add').val("");
    $('#tbarchivetype_status_active' ).prop('checked',true);
    $('#erro_labble_content').css({'display':'none'});

}
// open modal update
function openFormUpdateTbarchivetype(id, name, scode, status) {
    // document.getElementById("form-add-tbarchivetype-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = title_update;
    document.getElementById("btn_add_new_tbarchivetype_buttton").value = title_update;

    $('#tbarchivetype_id').val(id);
    $('#tbarchivetype_name_add').val(name);
    document.getElementById("tbarchivetype_name_add").addEventListener("keyup", function() {} );
    $('#tbarchivetype_scode_add').val(scode);
    $('#tbarchivetype_id').val(id);
    $('#tbarchivetype_id').val(id);
    if(status == "ACTIVE"){
        $('#tbarchivetype_status_active' ).prop('checked',true);
    }else {
        $('#tbarchivetype_status_inactive' ).prop('checked',true);
    };
}

function checkNospace(value){
    if ( value != "  "  &&  value.indexOf("  ") < 0 ){
    return true;
    }else{
    return false;
    }
}

function clickDeleteTbarchivetype(id,name){
    let href = `${action_del}`;
    href += `?id=${id}`;

    let html = `${mess_del} <span style="font-weight: bold; color: red">${name}</span>?`
    openConfirmDialog(html,(result )=>{
    if(result){
        doClick(href,'delete')
    }
    });

}
document.getElementById("btn_add_new_tbarchivetype_buttton").addEventListener("click", function() {
    document.getElementById("btn_add_new_tbarchivetype_buttton").style.display = "none";
    document.getElementById("loading_button_tbarchivetype").style.display = "block";
});
function delete_loading_tbarchivetypes(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
}
