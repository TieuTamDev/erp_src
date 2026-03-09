var sid_erro = document.getElementById('user_sid');
var error_label = document.getElementById('erro_labble_content'); 

/**
 * When the user clicks on the loading resource, the loading resource is hidden, the loading resource's
 * previous sibling is hidden, and the loading resource's next sibling is displayed.
 * @param element - The element that you want to delete.
 */
function delete_loading_resource(element){
element.style.display = "none"
element.previousElementSibling.style.display = "none"
element.nextElementSibling.style.display = "block"
}

/**
 * The function is called when the user types in the input field. The function then checks if the input
 * field is empty or not. If it's not empty, it will then remove the Vietnamese tones and replace the
 * spaces with dashes. Then it will check if the input field is empty or not. If it's not empty, it
 * will then remove the Vietnamese tones and replace the spaces with dashes. Then it will check if the
 * input field is empty or not. If it's not empty, it will then remove the Vietnamese tones and replace
 * the spaces with dashes. Then it will check if the input field is empty or not. If it's not empty, it
 * will then remove the Vietnamese tones and replace the spaces with dashes. Then it will check if the
 * input field is empty or not. If it's not empty, it will then remove the Vietnamese tones and replace
 * the spaces with dashes. Then it will check if the input field is empty or not
 */
function getTextToASCII() {
var value_resource_url = document.getElementById("resource_url").value;
var value_resource_scode = document.getElementById("resource_scode");
if (value_resource_url) {
    var content = removeVietnameseTones(value_resource_url).replace(/ /g, '-');
        content = content.replace('---', '-');
        if (value_resource_scode) {
                    value_resource_scode.value = content.toUpperCase()
                    jQuery.ajax({
                                data: {scode: content.toUpperCase()},
                                type: 'GET',
                                url: url_resource_required_path,
                                success: function (result) {
                                    if (result.result_scode == false ) {
                                    var err = document.getElementById('resource_scode');  
                                    error_label.innerHTML = translate_error_scode_1;
                                    error_label.style.display = "block";
                                    err.style.border = "1px solid red"; 
                                    document.getElementById("btn_add_new_resource_buttton").disabled = true; 
                                    return;
                                    } else {
                                    var err = document.getElementById('resource_scode');   
                                    error_label.style.display = "none";
                                    err.style.border = "1px solid #ced4da"; 
                                    document.getElementById("btn_add_new_resource_buttton").disabled = false; 
                                    }
                                }
                    });
        }
}
}

/**
 * It replaces all the Vietnamese diacritics with their non-diacritic counterparts
 * @param str - The string to be processed.
 * @returns a string with all the Vietnamese tones removed.
 */
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

function openFormAddResource() {
// document.getElementById("form-add-resource-container").style.display = "block";
document.getElementById("cls_bmtu_form_add_title").innerHTML = translate_btn_create;
document.getElementById("btn_add_new_resource_buttton").value = translate_btn_create
document.getElementById("resource_id").value = "";
document.getElementById("resource_url").value = "";
document.getElementById("resource_url").addEventListener("keyup", function() {getTextToASCII()} );
document.getElementById("resource_scode").value = "";

document.getElementById("resource_scode").addEventListener("change", function () {  
console.log(true);
let oScode = document.getElementById("resource_scode").value;
jQuery.ajax({
    data: {scode: oScode},
        type: 'GET',
        url: url_resource_required_path,
        success: function (result) {
        console.log(true);
        if (result.result_scode == false ) {
            var err = document.getElementById('resource_scode');  
            error_label.innerHTML = translate_error_scode_1;
            error_label.style.display = "block";
            err.style.border = "1px solid red"; 
            document.getElementById("btn_add_new_resource_buttton").disabled = true; 
            return;
        } else {
        console.log(false); 
            var err = document.getElementById('resource_scode');   
            error_label.style.display = "none";
            err.style.border = "1px solid #ced4da"; 
            document.getElementById("btn_add_new_resource_buttton").disabled = false; 
        }
        }
    });
});
}

// A function that is called when the user clicks on the "Close" button in the form.
function closeFormAddResource() {
document.getElementById("form-add-resource-container").style.display = "none";
document.getElementById("resource_id").value = "";
document.getElementById("resource_url").value = "";
document.getElementById("resource_scode").value = "";
document.getElementById("resource_url").style.border = "1px solid #ced4da";
document.getElementById("resource_scode").style.border = "1px solid #ced4da";
document.getElementById('erro_labble_content').style.display = "none";
}

// Opening a form to update a resource.
function openFormUpdateResource(id, url, scode, app, status) {
// document.getElementById("form-add-resource-container").style.display = "block";
document.getElementById("cls_bmtu_form_add_title").innerHTML = translate_btn_update;
document.getElementById("btn_add_new_resource_buttton").value = translate_btn_update;
document.getElementById("resource_id").value = id;
document.getElementById("resource_url").value = url;
document.getElementById("resource_scode").value = scode;
document.getElementById("resource_app").value = app;
document.getElementById("resource_url").addEventListener("keyup", function() {} );
if(status == "ACTIVE"){
    document.getElementById("resource_status_active").checked = true;
}
else {
    document.getElementById("resource_status_inactive").checked = true;
}

}

// Adding an event listener to the resource_url input field. When the input field changes, the error_label is hidden and the border of the input field is changed.
document.getElementById("resource_url").addEventListener("change", function () { 
var err = document.getElementById('resource_url'); 
error_label.style.display = "none";
err.style.border = "1px solid #ced4da";
});

// Adding an event listener to the resource_app element. When the resource_app element changes, the error_label element is hidden and the resource_app element's border is changed.
document.getElementById("resource_app").addEventListener("change", function () {
var err = document.getElementById('resource_app');
error_label.style.display = "none";
err.style.border = "1px solid #ced4da";
});

// Checking if the input fields are empty or not. If they are empty, it will show an error message. If they are not empty, it will submit the form.
document.getElementById('btn_add_new_resource_buttton').onclick = function () {
var error_label = document.getElementById('erro_labble_content');
var url = document.getElementById('resource_url').value;
var url_erro = document.getElementById('resource_url');
var scode = document.getElementById('resource_scode').value;
var scode_erro = document.getElementById('resource_scode');

if (url == "") {
    error_label.innerHTML = translate_error1;
    error_label.style.display = "block";
    url_erro.style.border = "1px solid red";
    return;
} else if (scode == "") {
    error_label.innerHTML = translate_error3;
    error_label.style.display = "block";
    scode_erro.style.border = "1px solid red";
    url_erro.style.border = "1px solid #ced4da";
    return;
} else {
        scode_erro.style.border = "1px solid #ced4da";
        error_label.style.display = "none";
        document.getElementById("btn_add_new_resource_buttton").style.display = "none";
    document.getElementById("loading_button_resource").style.display = "block";
        document.getElementById("btn_add_new_resource_buttton").type = "submit";
}

}

$('#myModal').on('shown.bs.modal', function () {
$('#myInput').trigger('focus')
})

// Preventing the enter key from submitting the form
$('#search').bind('keypress keydown keyup', function(e){
if(e.keyCode == 13) { e.preventDefault(); }
});
