var citis = document.getElementById("txt_province_user_add");
var districts = document.getElementById("txt_district_user_add");
var wards = document.getElementById("txt_ward_user_add");
var Parameter = {
    url: link_address_json, 
    method: "GET", 
    responseType: "application/json", 
};
var locationData = null;

axios(Parameter).then(function (result) {
    locationData = result.data;
    renderSelectData("txt_province_user_add",locationData);
});

function clickCollapseMainInfo(element){
    document.getElementById('collapse-main-icon-info').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}

function clickCollapseInfo(element){
    document.getElementById('collapse-icon-info').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}

function clickCollapseSocialInfo(element){
    document.getElementById('collapse-social-icon-info').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}


function setSelectValue(id, value){
    $('#'+ id).val(value)
    $('#' +id ).trigger('select2:select');
}

function renderSelectData(selectId,data) {
    $("#"+selectId).find('option').remove();
    let selectData = data.map(item => {
        return {
        id: item.Name,
        text: item.Name
    }});

    $("#"+selectId).select2({data: selectData}).trigger('change');
}




var error_label_user = document.getElementById('erro_labble_content_usser_info');
var sid_error_user = document.getElementById('user_sid');
var userName_error_user = document.getElementById('user_username');
var email_error_user = document.getElementById('user_email');   

function checkGmail(value) {
        if (/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(value)) {
        return true
        } else {
        return false
        }
}     

document.getElementById("user_first_name_add").addEventListener("change", function () { 
        var first_name_erro = document.getElementById('user_first_name_add');
        error_label_user.style.display = "none";
        first_name_erro.style.border = "1px solid #ced4da";
        document.getElementById("btn_add_new_user").disabled = false;
});

// document.getElementById("user_last_name_add").addEventListener("change", function () {
    
//     var firstname = document.getElementById("user_first_name_add").value.toLowerCase().trim();	
//     var eng_first_name = removeAccents(firstname);    
//     var lastname = document.getElementById("user_last_name_add").value;
//     var eng_last_name = removeAccents(lastname).toLowerCase().split(" ");
//     var user_sid = document.getElementById("user_sid").value
//     var final = "";
//     for (let i = 0; i < eng_last_name.length; i++) {        
//     var a = eng_last_name[i].charAt(0);
//     final += a ;   
//     document.getElementById("user_email").value = eng_first_name + final + "@bmtuvietnam.com";
//     }
// });

document.getElementById("user_sid").addEventListener("change", function () {
    var error_label_user = document.getElementById('erro_labble_content_usser_info');
    var sid_ussre = document.getElementById('user_sid').value;
    var sid_error_user = document.getElementById('user_sid');
    if (sid_ussre != id_user_details) {
        jQuery.ajax({
        data: { check_id: sid_ussre},
            type: 'GET',
            url: link_user_check_unique_sid_path,
            success: function (result) { 
                if ( result.result_sid == false ){
                error_label_user.innerHTML = translate_error_sid_user;
                sid_error_user.style.border= "1px solid red";
                error_label_user.style.display="block";
                sid_error_user.focus(); 
                document.getElementById("btn_add_new_user").disabled = true;
                return;
                }else {
                    

                }
            }
        });
    }
    error_label_user.style.display = "none";
    sid_error_user.style.border = "1px solid #ced4da";
    document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_username").addEventListener("change", function () {
    var userName_error_user = document.getElementById('user_username');
    var userName = document.getElementById('user_username').value;
    if (userName != username_user_details) {
        jQuery.ajax({
        data: { check_username: userName},
            type: 'GET',
            url: link_user_check_unique_username_path,
            success: function (result) {
            if (result.result_usn == false ) {
                error_label_user.innerHTML = translate_error_username_user;
                error_label_user.style.display = "block";
                userName_error_user.style.border = "1px solid red";
                userName_error_user.focus();
                document.getElementById("btn_add_new_user").disabled = true; 
                return;
            }
            }
        });
    }
    error_label_user.style.display = "none";
    userName_error_user.style.border = "1px solid #ced4da";
    document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_email").addEventListener("change", function () {
    var email_error_user = document.getElementById('user_email');
    var email = document.getElementById('user_email').value;
    if (email != email_user_details) {
        jQuery.ajax({
        data: { check_email: email},
            type: 'GET',
            url: link_user_check_unique_email_path,
            success: function (result) {
                if (result == false ) {
                error_label_user.innerHTML = translate_error_Email_already_exists;
                email_error_user.style.border= "1px solid red";
                error_label_user.style.display="block";    
                email_error_user.focus();
                document.getElementById("btn_add_new_user").disabled = true; 
                return;                                         
                }
            }
        });
    }
    if (checkGmail(email) == false) {
    error_label_user.innerHTML = translate_error_Please_enter_the_correct_email_address;
    error_label_user.style.display = "block";
    email_error_user.style.border = "1px solid red";
    email_error_user.focus();
    document.getElementById("btn_add_new_user").disabled = true;
    return;
    }

    error_label_user.style.display = "none";
    email_error_user.style.border = "1px solid #ced4da";
    document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById('btn_add_new_user').onclick = function () {                  

    var error_label_user = document.getElementById('erro_labble_content_usser_info');
    var id = document.getElementById("user_id").value;

    var first_name = document.getElementById('user_first_name_add').value;
    var first_name_erro = document.getElementById('user_first_name_add');

    var last_name = document.getElementById('user_last_name_add').value;
    var last_name_erro = document.getElementById('user_last_name_add');  

    var sid = document.getElementById('user_sid').value;
    var sid_error_user = document.getElementById('user_sid');

    var userName = document.getElementById('user_username').value;
    var userName_error_user = document.getElementById('user_username');

    var email = document.getElementById('user_email').value;
    var email_error_user = document.getElementById('user_email'); 

    if (first_name == "") {
    error_label_user.innerHTML = translate_error_Firts_name;
    error_label_user.style.display = "block";
    first_name_erro.style.border = "1px solid red"; 
    first_name_erro.focus();                    
    } else if (last_name == "") {
    error_label_user.innerHTML = translate_error_Last_Name;
    error_label_user.style.display = "block";
    last_name_erro.style.border = "1px solid red";
    first_name_erro.style.border = "1px solid #ced4da";
    last_name_erro.focus();
    } else if (sid == "") {
    error_label_user.innerHTML = translate_error_Employee_code;
    error_label_user.style.display = "block";
    sid_error_user.style.border = "1px solid red";
    last_name_erro.style.border = "1px solid #ced4da";
    sid_error_user.focus();
    } 
    else if (email == "") {
    error_label_user.innerHTML = translate_error_User_Email;
    error_label_user.style.display = "block";
    email_error_user.style.border = "1px solid red";
    sid_error_user.style.border = "1px solid #ced4da";
    email_error_user.focus();
    }
    else if (userName == "") {
    error_label_user.innerHTML = translate_error_UserName;
    error_label_user.style.display = "block";
    userName_error_user.style.border = "1px solid red";
    email_error_user.style.border = "1px solid #ced4da";
    userName_error_user.focus();
    } else {  
    document.getElementById("loading_info").classList.remove("d-none"); 
    error_label_user.style.display = "none";     
    document.getElementById("btn_add_new_user").type= "submit";
    }
} 


function loading(name) {
    if (name == 'tax') {
        document.getElementById("loading_tax").classList.remove("d-none");
    }
    if (name == 'info_other') {
        document.getElementById("loading_info_other").classList.remove("d-none");
    }
    if (name == 'address_user') {
        document.getElementById("loading_address_user").classList.remove("d-none");
    } 
    if (name == 'social') {
        if (document.getElementById("social_add_name").value != "" && document.getElementById("slink_add").value != "") {
            document.getElementById("loading_social").classList.remove("d-none"); 
        }
    } 
}
function show_feild_checked(data, list) {
   
    let show_feild = document.getElementById("show_feild");
    let show_feild_forensic_information = document.getElementById("show_feild_forensic_information");
    let show_feild_information_others_information = document.getElementById("show_feild_information_others_information");
    let show_feild_address_information_others = document.getElementById("show_feild_address_information_others");
    let show_feild_identity_information_others = document.getElementById("show_feild_identity_information_others");
    if (data == "info") {
        if (show_feild) {
        if (!show_feild.checked) { 
            let checkboxs = $("#select_add_organization_bd input")
            for (let i = 0; i < checkboxs.length; i++) {
            const element = checkboxs[i]; 
            element.checked = String(list).includes(element.value);
            }
            document.getElementById("lable_lastname_user").classList.add('d-none');
            document.getElementById("lable_scode_user_details").classList.add('d-none');
            document.getElementById("lable_ngay_sinh_user").classList.add('d-none');
            document.getElementById("lable_stype_hr_user").classList.add('d-none');
            document.getElementById("lable_religion_user").classList.add('d-none');
            document.getElementById("lable_first_name_user").classList.add('d-none');
            document.getElementById("lable_gender_user").classList.add('d-none');
            document.getElementById("lable_email_user").classList.add('d-none');
            document.getElementById("lable_academic_rank_user").classList.add('d-none');
            document.getElementById("lable_username_details").classList.add('d-none');
            document.getElementById("lable_status_user").classList.add('d-none');
            document.getElementById("lable_Education_user").classList.add('d-none');
            document.getElementById("lable_dan_toc_user").classList.add('d-none');
            document.getElementById("lable_nationality_user").classList.add('d-none');
            document.getElementById("lable_note_details").classList.add('d-none');
            document.getElementById("lable_marriage_user").classList.add('d-none');
            document.getElementById("lable_edit_info").classList.add('d-none');
            document.getElementById("lable_phone_user").classList.add('d-none');
            document.getElementById("lable_stype_organization_user").classList.add('d-none');
            document.getElementById("lable_tbuserstatus").classList.add('d-none');
            $("#lable_termination_date").addClass("d-none");
            document.getElementById("lable_tbusertype").classList.add('d-none');
            document.getElementById("lable_benefit_type_user").classList.add('d-none');
            document.getElementById("open_form_infor").classList.add('capp-form-bg');

            document.getElementById("lable_cancel_edit_info").classList.remove('d-none');
            document.getElementById("btn_add_new_user").classList.remove('d-none');
            document.getElementById("feild_lastname_user").classList.remove('d-none');
            document.getElementById("feild_stype_organization_user").classList.remove('d-none');
            document.getElementById("feild_scode_user_details").classList.remove('d-none');
            document.getElementById("feild_ngay_sinh_user").classList.remove('d-none');
            document.getElementById("feild_stype_hr_user").classList.remove('d-none');
            document.getElementById("feild_religion_user").classList.remove('d-none');
            document.getElementById("feild_first_name_user").classList.remove('d-none');
            document.getElementById("feild_gender_user").classList.remove('d-none');
            document.getElementById("feild_email_user").classList.remove('d-none');
            document.getElementById("feild_academic_rank_user").classList.remove('d-none');
            document.getElementById("feild_username_details").classList.remove('d-none');
            document.getElementById("feild_status_user").classList.remove('d-none');
            document.getElementById("feild_Education_user").classList.remove('d-none');
            document.getElementById("feild_dan_toc_user").classList.remove('d-none');
            document.getElementById("feild_nationality_user").classList.remove('d-none');
            document.getElementById("feild_note_details").classList.remove('d-none');
            document.getElementById("feild_marriage_user").classList.remove('d-none');
            document.getElementById("feild_phone_user").classList.remove('d-none');
            document.getElementById("feild_tbusertype").classList.remove('d-none');
            document.getElementById("feild_tbuserstatus").classList.remove('d-none');
            $("#feild_termination_date").removeClass("d-none");
            document.getElementById("feild_benefit_type_user").classList.remove('d-none');

        } else {   
            document.getElementById("open_form_infor").classList.remove('capp-form-bg');
            document.getElementById("feild_lastname_user").classList.add('d-none');
            document.getElementById("feild_scode_user_details").classList.add('d-none');
            document.getElementById("feild_ngay_sinh_user").classList.add('d-none');
            document.getElementById("feild_stype_hr_user").classList.add('d-none');
            document.getElementById("feild_religion_user").classList.add('d-none');
            document.getElementById("feild_first_name_user").classList.add('d-none');
            document.getElementById("feild_gender_user").classList.add('d-none');
            document.getElementById("feild_email_user").classList.add('d-none');
            document.getElementById("feild_academic_rank_user").classList.add('d-none');
            document.getElementById("feild_username_details").classList.add('d-none');
            document.getElementById("feild_status_user").classList.add('d-none');
            document.getElementById("feild_Education_user").classList.add('d-none');
            document.getElementById("feild_dan_toc_user").classList.add('d-none');
            document.getElementById("feild_nationality_user").classList.add('d-none');
            document.getElementById("feild_note_details").classList.add('d-none');
            document.getElementById("feild_phone_user").classList.add('d-none');
            document.getElementById("feild_marriage_user").classList.add('d-none');
            document.getElementById("feild_stype_organization_user").classList.add('d-none');
            document.getElementById("feild_tbuserstatus").classList.add('d-none');
            document.getElementById("feild_tbusertype").classList.add('d-none');
            document.getElementById("feild_benefit_type_user").classList.add('d-none');
            document.getElementById("btn_add_new_user").classList.add('d-none');
            document.getElementById("lable_cancel_edit_info").classList.add('d-none'); 

            document.getElementById("lable_edit_info").classList.remove('d-none');
            document.getElementById("lable_lastname_user").classList.remove('d-none');
            document.getElementById("lable_stype_organization_user").classList.remove('d-none');
            document.getElementById("lable_scode_user_details").classList.remove('d-none');
            document.getElementById("lable_ngay_sinh_user").classList.remove('d-none');
            document.getElementById("lable_stype_hr_user").classList.remove('d-none');
            document.getElementById("lable_religion_user").classList.remove('d-none');
            document.getElementById("lable_first_name_user").classList.remove('d-none');
            document.getElementById("lable_gender_user").classList.remove('d-none');
            document.getElementById("lable_email_user").classList.remove('d-none');
            document.getElementById("lable_academic_rank_user").classList.remove('d-none');
            document.getElementById("lable_username_details").classList.remove('d-none');
            document.getElementById("lable_status_user").classList.remove('d-none');
            document.getElementById("lable_Education_user").classList.remove('d-none');
            document.getElementById("lable_dan_toc_user").classList.remove('d-none');
            document.getElementById("lable_nationality_user").classList.remove('d-none');
            document.getElementById("lable_note_details").classList.remove('d-none');
            document.getElementById("lable_marriage_user").classList.remove('d-none');
            document.getElementById("lable_phone_user").classList.remove('d-none');
            document.getElementById("lable_tbuserstatus").classList.remove('d-none');
            document.getElementById("lable_tbusertype").classList.remove('d-none');
            document.getElementById("lable_benefit_type_user").classList.remove('d-none');
        }
        }
    } 
    if (data == "forensic"){
        if (show_feild_forensic_information) {
        if (!show_feild_forensic_information.checked) {  
            document.getElementById("lable_forensic_information").classList.add('d-none');
            document.getElementById("lable_bhxh_user").classList.add('d-none');  
            document.getElementById("lable_tax_user").classList.add('d-none');  
            document.getElementById("lable_place_insurance_user").classList.add('d-none');  
            document.getElementById("open_bao_hiem").classList.add('capp-form-bg');

            document.getElementById("lable_cancel_forensic_information").classList.remove('d-none');
            document.getElementById("btn_add_new_forensic_information").classList.remove('d-none');
            document.getElementById("feild_bhxh_user").classList.remove('d-none');  
            document.getElementById("feild_tax_user").classList.remove('d-none');  
            document.getElementById("feild_place_insurance_user").classList.remove('d-none');  
        } else {   
            document.getElementById("lable_forensic_information").classList.remove('d-none');
            document.getElementById("lable_bhxh_user").classList.remove('d-none');  
            document.getElementById("lable_tax_user").classList.remove('d-none');  
            document.getElementById("lable_place_insurance_user").classList.remove('d-none');  
            document.getElementById("open_bao_hiem").classList.remove('capp-form-bg');

            document.getElementById("btn_add_new_forensic_information").classList.add('d-none');
            document.getElementById("lable_cancel_forensic_information").classList.add('d-none');
            document.getElementById("feild_bhxh_user").classList.add('d-none');  
            document.getElementById("feild_tax_user").classList.add('d-none');  
            document.getElementById("feild_place_insurance_user").classList.add('d-none');  
        }
        }
    }
    if (data == "information_others"){
        if (show_feild_information_others_information) {
        if (!show_feild_information_others_information.checked) {  
            document.getElementById("lable_information_others_information").classList.add('d-none');
            document.getElementById("open_form_info_other").classList.add('capp-form-bg');
            document.getElementById("lable_address_information_others_information").classList.add('d-none');
            document.getElementById("lable_nationality_user_other").classList.add('d-none');     
            document.getElementById("lable_place_of_birth_user").classList.add('d-none');     
            document.getElementById("lable_m_place_of_birth_user").classList.add('d-none');     
            document.getElementById("lable_email1_user").classList.add('d-none');     
            document.getElementById("lable_btn_address_information_user").classList.add('d-none');
            document.getElementById("btn_add_new_information_others_information").classList.remove('d-none');
            document.getElementById("lable_cancel_information_others_information").classList.remove('d-none');
            document.getElementById("lable_cancel_address_others_information").classList.add('d-none');
            document.getElementById("feild_nationality_user_other").classList.remove('d-none');   
            document.getElementById("feild_place_of_birth_user").classList.remove('d-none');   
            document.getElementById("feild_m_place_of_birth_user").classList.remove('d-none');   
            document.getElementById("feild_email1_user").classList.remove('d-none');   
        } else {   
            document.getElementById("open_form_info_other").classList.remove('capp-form-bg');
            document.getElementById("lable_information_others_information").classList.remove('d-none'); 
            document.getElementById("lable_address_information_others_information").classList.remove('d-none');
            document.getElementById("lable_nationality_user_other").classList.remove('d-none');   
            document.getElementById("lable_place_of_birth_user").classList.remove('d-none');   
            document.getElementById("lable_m_place_of_birth_user").classList.remove('d-none');   
            document.getElementById("lable_email1_user").classList.remove('d-none');    
            document.getElementById("lable_btn_address_information_user").classList.add('d-none');
            document.getElementById("btn_add_new_information_others_information").classList.add('d-none');               
            document.getElementById("lable_cancel_information_others_information").classList.add('d-none');
            document.getElementById("lable_cancel_address_others_information").classList.add('d-none');
            document.getElementById("feild_nationality_user_other").classList.add('d-none');   
            document.getElementById("feild_place_of_birth_user").classList.add('d-none');   
            document.getElementById("feild_m_place_of_birth_user").classList.add('d-none');   
            document.getElementById("feild_email1_user").classList.add('d-none');   
        }
        }
    }
    if (data == "address_information_others"){
        if (show_feild_address_information_others) {
        if (!show_feild_address_information_others.checked) {
            if (value_province_user == ""){
                document.getElementById("txt_country_user").value = "Việt Nam"
                initSelectEvent();   
                setSelectValue("txt_province_user_add", "Tỉnh Đắk Lắk");
                setSelectValue("txt_district_user_add", "Thành phố Buôn Ma Thuột");
                document.getElementById("select2-txt_province_user_add-container").innerHTML = "Tỉnh Đắk Lắk";   
                document.getElementById("select2-txt_district_user_add-container").innerHTML = "Thành phố Buôn Ma Thuột"; 
                document.getElementById("txt_ward_user_add").value = "Phường Tân Lập"; 
                document.getElementById("select2-txt_ward_user_add-container").innerHTML = "Phường Tân Lập"; 
            }else {
                initSelectEvent();   
                setSelectValue("txt_province_user_add", value_province_user);                
                setSelectValue("txt_district_user_add", value_district_user);
                document.getElementById("select2-txt_district_user_add-container").innerHTML = value_district_user; 
                document.getElementById("txt_ward_user_add").value = value_ward_user; 
                document.getElementById("select2-txt_ward_user_add-container").innerHTML = value_ward_user; 
                document.getElementById("select2-txt_province_user_add-container").innerHTML = value_province_user;
            }  
            
                    
            document.getElementById("lable_information_others_information").classList.add('d-none');
            document.getElementById("open_form_address_other").classList.add('capp-form-bg');
            document.getElementById("lable_address_information_others_information").classList.add('d-none');
            document.getElementById("lable_address_user").classList.add('d-none');     
            document.getElementById("lable_btn_address_information_user").classList.remove('d-none');
            document.getElementById("btn_add_new_information_others_information").classList.add('d-none');
            document.getElementById("lable_cancel_information_others_information").classList.add('d-none');
            document.getElementById("lable_cancel_address_others_information").classList.remove('d-none');
            document.getElementById("feild_address_user").classList.remove('d-none');
            


         

        } else {   
            document.getElementById("lable_information_others_information").classList.remove('d-none');
            document.getElementById("open_form_address_other").classList.remove('capp-form-bg');

            document.getElementById("lable_address_information_others_information").classList.remove('d-none');
            document.getElementById("lable_address_user").classList.remove('d-none');   
            document.getElementById("lable_btn_address_information_user").classList.add('d-none');
            document.getElementById("btn_add_new_information_others_information").classList.add('d-none'); 
            document.getElementById("lable_cancel_information_others_information").classList.add('d-none');
            document.getElementById("lable_cancel_address_others_information").classList.add('d-none');
            document.getElementById("feild_address_user").classList.add('d-none');   
        }
        }
    }
    showTerminationDate();
} 



function editSocial() {
    document.getElementById("form_add_social_user").reset();
    document.getElementById("lable_cancel_edit_social").classList.remove('d-none'); 
    document.getElementById("lable_edit_social").classList.add('d-none');
}
function cancelEditSocial() {
    document.getElementById("form_add_social_user").reset();
    document.getElementById("lable_cancel_edit_social").classList.add('d-none');
    document.getElementById("open_form_info_other").style.background = "none"; 
    document.getElementById("lable_edit_social").classList.remove('d-none');
}
//script cua dat // 
function openFormUpdateSocial(id,user_id,name,slink,note,status){
    document.getElementById("lable_cancel_edit_social").classList.remove('d-none');
    document.getElementById("lable_edit_social").classList.add('d-none');

    document.getElementById("btn_add_social").classList.remove('d-none'); 
    setTimeout(() => {
    document.getElementById("form_add_social").classList.add('show');
    }, 700);
    var social_id = document.getElementById("social_add_id");
    var user_id_social = document.getElementById("user_id_social");
    var social_name = document.getElementById("social_add_name");
    var social_slink = document.getElementById("slink_add");
    var social_note = document.getElementById("note_add_social"); 
    var social_status_ACTIVE = document.getElementById("social_add_ACTIVE");
    var social_status_INACTIVE = document.getElementById("social_add_INACTIVE");

    social_id.value = id;
    user_id_social.value = user_id;
    social_name.value = name;
    social_slink.value = slink;
    social_note.value = note;  

    if(status == "ACTIVE"){
        social_status_ACTIVE.checked = true;
    }
    else {
        social_status_INACTIVE.checked = true;
    }

    document.getElementById("txt_social_title").scrollIntoView();

}
document.getElementById("user_password_add").value = "123456";
document.getElementById("user_ethnic_add").value = value_ethnic_user_details;
document.getElementById("user_tbuserstatus_add").value = value_tbuserstatus_user_details;
document.getElementById("user_tbusertype_add").value = value_tbusertype_user_details;
document.getElementById("user_education_add").value = value_education_user_details;
document.getElementById("user_academic_add").value = value_academic_rank_user_details;
if (value_gender_user_details == "0") {
    document.getElementById("user_gender_0").checked = true;
} else if (value_gender_user_details == "1") {
    document.getElementById("user_gender_1").checked = true;
} else {
    document.getElementById("user_gender_2").checked = true;
}
if (value_marriage_user_details == "Married") {
    document.getElementById("user_Marriage_Married").checked = true;
}
else {
    document.getElementById("user_Marriage_Single").checked = true;
}
if (value_status_user_details == "ACTIVE") {
    document.getElementById("user_status_ACTIVE").checked = true;
}
else {
    document.getElementById("user_status_INACTIVE").checked = true;
}
if (value_stype_user == "MEMBER") {
    document.getElementById("user_style_member").checked = true;
}
else {
    document.getElementById("user_style_applyer").checked = true;
}
if (value_benefit_type_user_details == "1") {
    document.getElementById("user_benefit_type_0").checked = true;
} else if (value_benefit_type_user_details == "2") {
    document.getElementById("user_benefit_type_1").checked = true;
} else {
    document.getElementById("user_benefit_type_2").checked = true;
}
document.getElementById("user_nationality_add_details").value = value_nationality_user_details;
document.getElementById("user_religion_add_details").value = value_religion_user_details;  
function is_phonenumber(phonenumber) {
    var phoneno = /(84|0[3|5|7|8|9])+([0-9]{8})\b/g;
    if(phonenumber.match(phoneno)) {return true;}  
    else {return false; }
}
function removeAccents(str) {
    var AccentsMap = [
        "aàảãáạăằẳẵắặâầẩẫấậ",
        "AÀẢÃÁẠĂẰẲẴẮẶÂẦẨẪẤẬ",
        "dđ", "DĐ",
        "eèẻẽéẹêềểễếệ",
        "EÈẺẼÉẸÊỀỂỄẾỆ",
        "iìỉĩíị",
        "IÌỈĨÍỊ",
        "oòỏõóọôồổỗốộơờởỡớợ",
        "OÒỎÕÓỌÔỒỔỖỐỘƠỜỞỠỚỢ",
        "uùủũúụưừửữứự",
        "UÙỦŨÚỤƯỪỬỮỨỰ",
        "yỳỷỹýỵ",
        "YỲỶỸÝỴ"    
        ];
        for (var i=0; i<AccentsMap.length; i++) {
        var re = new RegExp('[' + AccentsMap[i].substr(1) + ']', 'g');
        var char = AccentsMap[i][0];
        str = str.replace(re, char);
        }
        return str;
}
document.getElementById("user_mobile_add_user").addEventListener("change", function () {
    var mobile_erro = document.getElementById('user_mobile_add_user');
    var mobile = document.getElementById('user_mobile_add_user').value;
    if (is_phonenumber(mobile) == false) {
    error_label_user.innerHTML = translate_error_Vietnam_mobile_validation;
    error_label_user.style.display = "block";
    mobile_erro.style.border = "1px solid red";
    mobile_erro.focus();
    document.getElementById("btn_add_new_user").disabled = true;
    return;
    }
    error_label_user.style.display = "none";
    mobile_erro.style.border = "1px solid #ced4da";
    document.getElementById("btn_add_new_user").disabled = false;
});


function clickDeleteSocial(id,name,user_id){
    let href = linkDeleteSocial;
    href += `?id=${id}&uid=${user_id}`;

    let html = deleteMessageSocial +" "+ `<span style="font-weight: bold; color: red">${name}</span>?`
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href,'delete')
      }
    });

  }

  
  initSelectEvent();
  function initSelectEvent() {

    
      $("#txt_province_user_add").on('select2:select', function (e) {  
          let provinceId = $("#txt_province_user_add").val();
          let provinceData = locationData.find(function(item) { return item.Name === provinceId; });
          renderSelectData("txt_district_user_add",provinceData.Districts);
          // clear Wards Selection       
          $(wards).select2({data: []});
          $(wards).find('option').remove();
          setSelectValue("txt_district_user_add", provinceData.Districts[0].Name);
          document.getElementById('txt_district_user_add').nextSibling.classList.add("select2-container--bootstrap-5");       
          document.getElementById('txt_district_user_add').nextSibling.classList.remove("select2-container--default");       
          document.getElementById('txt_ward_user_add').nextSibling.classList.add("select2-container--bootstrap-5");       
          document.getElementById('txt_ward_user_add').nextSibling.classList.remove("select2-container--default");
      });
  
      $("#txt_district_user_add").on('select2:select', function (e) {
          let districtId = $("#txt_district_user_add").val();
          let provinceData = locationData.find(function(item) { return item.Name === citis.value; });        
          let districtsData = provinceData.Districts        
          let wardsData = districtsData.find(function(item) { return item.Name === districtId; });
          renderSelectData("txt_ward_user_add",wardsData.Wards);
          document.getElementById('txt_ward_user_add').nextSibling.classList.add("select2-container--bootstrap-5");       
          document.getElementById('txt_ward_user_add').nextSibling.classList.remove("select2-container--default");    
      });
      
  }

function showTerminationDate() {
  var status = $("#user_tbuserstatus_add").val();
  if(status == "Nghỉ việc"){
    $("#feild_termination_date").removeClass("d-none");
    $("#user_status_INACTIVE").prop("checked", true);
  }else {
    $("#feild_termination_date").addClass("d-none");
    $("#user_status_ACTIVE").prop("checked", true); 
  }  
  
}

//UPLOAD IMAGE USER
let editMode      = false;
let selectedFile  = null;
let originalBG    = '';

const btnMain   = $('#update_image');
btnMain.addClass('btn-update-orange')
    .on('click', toggleEditMode);

function clickSelectImage() { if (editMode) $('#user-image-edit').click(); }

// change input file
function onSelectImage(input) {
    const file = input.files[0];
    if (!file) return;
    selectedFile = file;
    showPreviewImage(file);
}

/* ---------------- toggle edit ---------------- */
function toggleEditMode() {
    editMode = !editMode;

    const hintText  = $('#upload-user-image').find('.user-image-container div:last-child');
    const actionBox = $('#image-action-btn');
    const preview   = $('#user-image-preview');

    if (editMode) {
        if (!originalBG) originalBG = preview.css('background-image') || '';
        btnMain.text('Huỷ cập nhật hình ảnh')
            .removeClass('btn-update-orange');
        hintText.removeClass('d-none');
        actionBox.removeClass('d-none');
    } else {
        preview.css('background-image', originalBG);
        selectedFile = null;
        $('#user-image-edit').val('');

        btnMain.text('Cập nhật hình ảnh')
            .addClass('btn-update-orange');
        hintText.addClass('d-none');
        actionBox.addClass('d-none');
    }
}

/* Huỷ */
$('#cancel-image').on('click', e => { e.preventDefault(); toggleEditMode(); });

/* Lưu */
$('#save-image').on('click', async e => {
    e.preventDefault();
    if (!selectedFile) { alert('Vui lòng chọn ảnh trước khi lưu!'); return; }

    const form = new FormData();
    const params = new URLSearchParams(window.location.search);
    const userId = params.get('id');
    form.append('file', selectedFile);
    form.append('user_id', userId);

    if (currentDocId) form.append('doc_id', currentDocId);

    try {
        $('#save-image').prop('disabled', true).text('Đang lưu…');

        const res = await fetch(user_upload_image_path, {
            method:'POST',
            headers:{ 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
            body: form
        });
        const json = await res.json();
        if (json.success) {
            showAlert('Cập nhật ảnh thành công!','success');
            currentDocId = json.doc_id;
            originalBG = $('#user-image-preview').css('background-image');
            toggleEditMode();
        } else {
            showAlert(json.msg || 'Lưu ảnh thất bại!', 'danger');
        }
    } catch (err) {
        console.error(err);
        showAlert('Lưu ảnh thất bại!','danger');
    } finally {
        $('#save-image').prop('disabled', false).text('Lưu');
    }
});

/* ----- validate & preview ----- */
function showPreviewImage(file) {
    const mb = (file.size / 1024 / 1024).toFixed(1);
    const msg = $('#valid-message');
    if (mb > 3) {
        msg.html(`Ảnh quá lớn (${mb} MB).<br>Dung lượng cho phép: dưới 3 MB.`).show();
        return;
    }
    msg.hide();

    const rd = new FileReader();
    rd.onload = () => $('#user-image-preview').css('background-image', `url(${rd.result})`);
    rd.readAsDataURL(file);
}

function clickCollapseImage(element){
    document.getElementById('collapse-icon-image').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}