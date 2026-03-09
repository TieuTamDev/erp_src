$(function () {		
    $( ".datepicker" ).datetimepicker({
      format: 'DD/MM/YYYY'
    });
});

$(function () {
    // Select all text inputs in the form
    const textInputs = $('#form_add_user input[type="text"]');
    const maxLength = 255;
    const errorLabel = $('#erro_labble_content');

    // Function to get clean label text (excluding <span> content)
    function getCleanLabelText(input) {
        const label = input.prev('label');
        if (label.length) {
            // Get the text node directly from the label's contents
            let text = '';
            label.contents().each(function () {
                // Only process text nodes (nodeType 3) and stop at the first span
                if (this.nodeType === 3) { // Text node
                    text += $(this).text().trim();
                } else if (this.nodeName.toLowerCase() === 'span') {
                    return false; // Stop processing at span
                }
            });
            return text.trim() || ''; // Return trimmed text or fallback
        }
        return ''; // Fallback if no label is found
    }

    // Add input event listener to all text inputs
    textInputs.on('input', function () {
        const input = $(this);
        const value = input.val();

        // Check if input exceeds 255 characters
        if (value.length > maxLength) {
            // Highlight input border in red
            input.css('border', '1px solid red');
            // Show error message with clean label text
            errorLabel.text(`Trường nhập thông tin ${getCleanLabelText(input)} không được vượt quá ${maxLength} ký tự.`);
            errorLabel.show();
            // Disable submit button
            $('#btn_add_new_user').prop('disabled', true);
        } else {
            // Reset border if within limit
            input.css('border', '1px solid #ced4da');
            // Clear error message if no other inputs are invalid
            if (textInputs.filter(function () { return $(this).val().length > maxLength; }).length === 0) {
                errorLabel.hide();
                $('#btn_add_new_user').prop('disabled', false);
            }
        }
    });

    // Validate all text inputs on form submission
    $('#btn_add_new_user').on('click', function () {
        let hasError = false;
        textInputs.each(function () {
            const input = $(this);
            if (input.val().length > maxLength) {
                input.css('border', '1px solid red');
                errorLabel.text(`Trường nhập thông tin ${getCleanLabelText(input)} không được vượt quá ${maxLength} ký tự.`);
                errorLabel.show();
                hasError = true;
            }
        });

        if (hasError) {
            $('#btn_add_new_user').prop('disabled', true);
            return false; // Prevent form submission if there are errors
        }
    });

    // Reset borders and error message when opening the form
    function resetTextInputs() {
        textInputs.each(function () {
            $(this).css('border', '1px solid #ced4da');
        });
        errorLabel.hide();
        $('#btn_add_new_user').prop('disabled', false);
    }

    // Call reset when opening add or update form
    const originalOpenFormAddUser = openFormAddUser;
    openFormAddUser = function () {
        originalOpenFormAddUser();
        resetTextInputs();
    };

    const originalOpenFormUpdateUser = openFormUpdateUser;
    openFormUpdateUser = function (...args) {
        originalOpenFormUpdateUser(...args);
        resetTextInputs();
    };
});

$(function () {
    $(".datepicker").on('keydown', function (e) {
        IsNumeric(this, e.keyCode);
    });
    var isShift = false;
    var seperator = "/";
    function IsNumeric(input, keyCode) {
        if (keyCode == 16) {
            isShift = true;
        }
        //Allow only Numeric Keys.
        if (((keyCode >= 48 && keyCode <= 57) || keyCode == 8 || keyCode <= 37 || keyCode <= 39 || (keyCode >= 96 && keyCode <= 105)) && isShift == false) {
            if ((input.value.length == 2 || input.value.length == 5) && keyCode != 8) {
                input.value += seperator;
            }
            return true;
        }
        else {
            return false;
        }
    };
    $(".datepicker").keyup(function(e) {
      var datecheck = /^(?:(?:31(\/|-|\.)(?:0?[13578]|1[02]|(?:Jan|Mar|May|Jul|Aug|Oct|Dec)))\1|(?:(?:29|30)(\/|-|\.)(?:0?[1,3-9]|1[0-2]|(?:Jan|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))\2))(?:(?:1[6-9]|[2-9]\d)?\d{2})$|^(?:29(\/|-|\.)(?:0?2|(?:Feb))\3(?:(?:(?:1[6-9]|[2-9]\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\d|2[0-8])(\/|-|\.)(?:(?:0?[1-9]|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep))|(?:1[0-2]|(?:Oct|Nov|Dec)))\4(?:(?:1[6-9]|[2-9]\d)?\d{2})$/g;
      var textcheck = /[A-Za-z]/g;
      var special = /[!"`'#%&.,:;<>=@{}~\$\(\)\*\+\-\\\?\[\]\^\|]+/;
      var unikey = /^[a-zA-Z_ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪễệỉịọỏốồổỗộớờởỡợụủứừỬỮỰỲỴÝỶỸửữựỳỵỷỹ]+$/;
        if (!datecheck.test(this.value))
          {
            this.value = this.value.replace(textcheck, '');
            this.value = this.value.replace(special, '');
            this.value = this.value.replace(unikey, '');
          }
          else {
            
          }
    });       

});

const Menubutton = document.querySelector("#nav-tab-bar");
const Tabsbar = document.querySelector("#pill-myTab");
var tabs_bar_menu = document.getElementById("pill-myTab");
function  close_nav_menu_bar_resposive() {

const tab_class = Tabsbar.getAttribute("class");

let width = window.innerWidth;  
  if (width <= 992) {
    if (tab_class.includes("show_menu_bar")) {
      tabs_bar_menu.classList.add("hide_menu_bar");
      tabs_bar_menu.classList.remove("show_menu_bar"); 
      } else {
      tabs_bar_menu.classList.remove("hide_menu_bar");
      tabs_bar_menu.classList.add("show_menu_bar");
    }
  }else {
    return false;
  }
  
}  

function nextpage() {   
document.getElementById("tab5").style.display= "block";
document.getElementById("tab6").style.display= "block";
document.getElementById("tab1").style.display= "none";
document.getElementById("tab2").style.display= "none";
document.getElementById("tab3").style.display= "none";
document.getElementById("tab4").style.display= "none";   
document.getElementById("previous-page-usertab").style.display= "block";    
document.getElementById("next-page-usertab").style.display= "none";  
};

function firstpage() {   
document.getElementById("tab5").style.display= "none";
document.getElementById("tab6").style.display= "none";
document.getElementById("tab1").style.display= "block";
document.getElementById("tab2").style.display= "block";
document.getElementById("tab3").style.display= "block";
document.getElementById("tab4").style.display= "block";    
document.getElementById("previous-page-usertab").style.display= "none";    
document.getElementById("next-page-usertab").style.display= "block";    
};

function delete_loading_user_list(element){
  element.style.display = "none"
  element.previousElementSibling.style.display = "none"
  element.nextElementSibling.style.display = "block"
}              

function onCheckboxOrhid(scode) {

    if (document.getElementById("user_id").value == ""){
        let prefix = "BMTU";
        let scode_arr = []
    
        let checkboxs = $('#select_add_organization_bd').find('input:checkbox:checked');
        if (checkboxs.length == 1){
            prefix = scode;
        }else{
            return;
        }
    
        let checkbox_list = $('#select_add_organization_bd').find('input:checkbox');
        checkbox_list.each((i,element)=>{
            scode_arr.push(element.getAttribute("data-scode"));
        });
        
        let user_code = $('#user_sid');
        let code_val = $('#user_sid').val();
        scode_arr.forEach(scode=>{
            if(code_val.includes(scode)){
                code_val = code_val.replace(scode,prefix);
                user_code.val(code_val);
            }
        })
    }


}




const passwordField = document.querySelector("#user_password_add");
const eyeIcon = document.querySelector("#show_pwd");
eyeIcon.addEventListener("click", function () {
const type = passwordField.getAttribute("type") === "password" ? "text" : "password";
passwordField.setAttribute("type", type);

var pwdtype = document.getElementById("user_password_add").getAttribute("type");


var eye1 = document.getElementById('eye1');



if (pwdtype == "text") {
  eye1.classList.remove("fa-eye-slash");
  eye1.classList.add("fa-eye");
} else {
  eye1.classList.add("fa-eye-slash");
  eye1.classList.remove("fa-eye");
}
})

const rePasswordField = document.querySelector("#user_re_password_digest_add");
const eyeIcon2 = document.querySelector("#show_re_pwd");
eyeIcon2.addEventListener("click", function () {
const type = rePasswordField.getAttribute("type") === "password" ? "text" : "password";
rePasswordField.setAttribute("type", type);

var pwdtype = document.getElementById("user_re_password_digest_add").getAttribute("type");


var eye2 = document.getElementById('eye2');



if (pwdtype == "text") {
  eye2.classList.remove("fa-eye-slash");
  eye2.classList.add("fa-eye");
} else {
  eye2.classList.add("fa-eye-slash");
  eye2.classList.remove("fa-eye");
}
})

var error_label = document.getElementById('erro_labble_content');
var sid_erro = document.getElementById('user_sid');
var userName_erro = document.getElementById('user_username');
var email_erro = document.getElementById('user_email');
var pwd_erro = document.getElementById('user_password_add');
var rePwd_erro = document.getElementById('user_re_password_digest_add');       

function openFormAddUser() {
// 
$("#termination_date_group").hide();
let checkboxs = $("#select_add_organization_bd input")
for (let i = 0; i < checkboxs.length; i++) {
  const element = checkboxs[i]; 
  element.checked = !element.value;
}
document.getElementById("btn_add_new_user").disabled = false;
var sid_erro = document.getElementById('user_sid');
var userName_erro = document.getElementById('user_username');
var email_erro = document.getElementById('user_email');
var pwd_erro = document.getElementById('user_password_add');
var rePwd_erro = document.getElementById('user_re_password_digest_add');
var first_name_erro = document.getElementById('user_first_name_add');
var last_name_erro = document.getElementById('user_last_name_add');
var error_label = document.getElementById('erro_labble_content');

// document.getElementById("form-add-user-container").style.display = "none";
document.getElementById("user_sid").value = "";    
error_label.style.display = "none";
sid_erro.style.border = "1px solid #ced4da";
userName_erro.style.border = "1px solid #ced4da";
email_erro.style.border = "1px solid #ced4da";
pwd_erro.style.border = "1px solid #ced4da";
rePwd_erro.style.border = "1px solid #ced4da";
first_name_erro.style.border = "1px solid #ced4da";
last_name_erro.style.border = "1px solid #ced4da";
document.getElementById("user_first_name_add").value = "";
document.getElementById("user_last_name_add").value = "";
document.getElementById("user_id").value = "";
document.getElementById("user_sid").value = "";
document.getElementById("user_username").value = "";
document.getElementById("user_email").value = "";
document.getElementById("user_insurance_no").value = "";
document.getElementById("user_password_add").value = "";
document.getElementById("user_re_password_digest_add").value = "";
document.getElementById("user_email_2_add").value = "";
document.getElementById("user_phone_add").value = "";
document.getElementById("user_mobile_add").value = "";
document.getElementById("user_place_of_birth_add").value = "";
document.getElementById("user_m_place_of_birth_add").value = "";
document.getElementById("user_taxid_add").value = "";    
document.getElementById("user_note_add").value = "";
document.getElementById("user_insurance_placed_add").value = "";

// 
document.getElementById("user_re_password_digest_add").removeEventListener("click", function(){clearRePwd()});
document.getElementById("user_password_add").removeEventListener("click", function(){clearPwd()});

jQuery.ajax({
  url: show,
  dataType: 'json',
  success: function(response) {
    $("#user_academic_add").find("option").remove()
    $.each(response.academicrank, function(index, academicrank) {
      $("#user_academic_add").append("<option value='" + academicrank.name + "'>" + academicrank.name + "</option>");
    });
    $("#user_ethnic_add").find("option").remove()
    $.each(response.ethnic, function(index, ethnic) {
      $("#user_ethnic_add").append("<option value='" + ethnic.name + "'>" + ethnic.name + "</option>");
    });
    $("#user_education_add").find("option").remove()
    $.each(response.education, function(index, education) {
      $("#user_education_add").append("<option value='" + education.name + "'>" + education.name + "</option>");
    });
    $("#user_religion_add_details").find("option").remove()
    $.each(response.religion, function(index, religion) {
      $("#user_religion_add_details").append("<option value='" + religion.name + "'>" + religion.name + "</option>");
    });
    $("#user_nationality_add_details").find("option").remove()
    $.each(response.nationality, function(index, nationality) {
      $("#user_nationality_add_details").append("<option value='" + nationality.name + "'>" + nationality.name + "</option>"); 
    });
    $("#user_tbusertype_add_details").find("option").remove()
    $.each(response.tbusertype, function(index, tbusertype) {
      $("#user_tbusertype_add_details").append("<option value='" + tbusertype.name + "'>" + tbusertype.name + "</option>");
    });
    $("#user_tbuserstatus_add_details").find("option").remove()
    $.each(response.tbuserstatus, function(index, tbuserstatus) {
      $("#user_tbuserstatus_add_details").append("<option value='" + tbuserstatus.name + "'>" + tbuserstatus.name + "</option>");
    });

    $("#user_insurance_placed_add").find("option").remove()
    $.each(response.tbhospital, function(index, tbhospital) {
      $("#user_insurance_placed_add").append("<option value='" + tbhospital.name + "'>" + tbhospital.name + "</option>");
    });
  }
});

var sid_erro = document.getElementById('user_sid');
var userName_erro = document.getElementById('user_username');
var email_erro = document.getElementById('user_email');
var pwd_erro = document.getElementById('user_password_add');
var rePwd_erro = document.getElementById('user_re_password_digest_add');
var error_label = document.getElementById('erro_labble_content');

document.getElementById("user_password_add").value = randomPwdFinal;
document.getElementById("user_re_password_digest_add").value = randomPwdFinal;

var employee_code;
var idNumber = +parseInt(lastUserSid) + 1;
if (lastUserSid < 10){
  employee_code = "BU000" + idNumber;
}else {
  employee_code = "BU00" +  idNumber;
}

document.getElementById("user_sid").value = employee_code;
document.getElementById("user_username").value = null;
document.getElementById("user_email").value = null;

error_label.style.display = "none";
sid_erro.style.border = "1px solid #ced4da";
userName_erro.style.border = "1px solid #ced4da";
email_erro.style.border = "1px solid #ced4da";
pwd_erro.style.border = "1px solid #ced4da";
rePwd_erro.style.border = "1px solid #ced4da";

document.getElementById("cls_bmtu_form_add_title").innerHTML = strAddUser ;
document.getElementById("btn_add_new_user").value = strAddUser;

document.getElementById("show_pwd").style.display = "block";
document.getElementById("show_re_pwd").style.display = "block";
// document.getElementById("form-add-user-container").style.display = "block";

var checked_unit = document.getElementById(strUserOrgid);


if (checked_unit != ""){
  if (checked_unit.value == strUserOrgid ){ 
    checked_unit.checked = true;    
  }
} 

}

function closeFormAdd() {
  let checkboxs = $("#select_add_organization_bd input")
  for (let i = 0; i < checkboxs.length; i++) {
    const element = checkboxs[i]; 
    element.checked = !element.value;
  }
  document.getElementById("btn_add_new_user").disabled = false;
  var sid_erro = document.getElementById('user_sid');
  var userName_erro = document.getElementById('user_username');
  var email_erro = document.getElementById('user_email');
  var pwd_erro = document.getElementById('user_password_add');
  var rePwd_erro = document.getElementById('user_re_password_digest_add');
  var first_name_erro = document.getElementById('user_first_name_add');
  var last_name_erro = document.getElementById('user_last_name_add');
  // document.getElementById("form-add-user-container").style.display = "none";
  document.getElementById("user_sid").value = "";    
  error_label.style.display = "none";
  sid_erro.style.border = "1px solid #ced4da";
  userName_erro.style.border = "1px solid #ced4da";
  email_erro.style.border = "1px solid #ced4da";
  pwd_erro.style.border = "1px solid #ced4da";
  rePwd_erro.style.border = "1px solid #ced4da";
  first_name_erro.style.border = "1px solid #ced4da";
  last_name_erro.style.border = "1px solid #ced4da";
  document.getElementById("user_first_name_add").value = "";
  document.getElementById("user_last_name_add").value = "";
  document.getElementById("user_id").value = "";
  document.getElementById("user_sid").value = "";
  document.getElementById("user_username").value = "";
  document.getElementById("user_email").value = "";
  document.getElementById("user_insurance_no").value = "";
  document.getElementById("user_password_add").value = "";
  document.getElementById("user_re_password_digest_add").value = "";
  document.getElementById("user_email_2_add").value = "";
  document.getElementById("user_phone_add").value = "";
  document.getElementById("user_mobile_add").value = "";
  document.getElementById("user_place_of_birth_add").value = "";
  document.getElementById("user_m_place_of_birth_add").value = "";
  document.getElementById("user_taxid_add").value = "";
  document.getElementById("user_insurance_placed_add").value = "";
  document.getElementById("user_note_add").value = "";
}

function openFormUpdateUser(id, sid, username, email, gender, nationalityup,
      ethnicup, religionup, marriage, insurance_no, educationup,
      academic_rank, status, stype, note, first_name, last_name,birthday,
      taxid, strIsuranceplace, place_of_birth, m_place_of_birth, email1, phone, mobile,staff_type,staff_status,benefittype,list, twofa, twofa_exam, ignore_attend, termination_date) {   
      let checkboxs = $("#select_add_organization_bd input")
      for (let i = 0; i < checkboxs.length; i++) {
      const element = checkboxs[i]; 
      element.checked = String(list).includes(element.value);
    }
    document.getElementById("user_first_name_add").value = first_name.trim();
    document.getElementById("user_last_name_add").value = last_name.trim();
    document.getElementById("user_tbusertype_add_details").value = staff_type; 
    document.getElementById("user_tbuserstatus_add_details").value = staff_status; 
    document.getElementById("user_password_add").value = " ";
    document.getElementById("user_re_password_digest_add").value = " ";
    document.getElementById("user_password_add").innerHTML = null;
    document.getElementById("user_re_password_digest_add").innerHTML = null;
    document.getElementById("user_birthday_add").value = birthday;   
    document.getElementById("user_email_2_add").value = email1;
    document.getElementById("user_phone_add").value = phone;
    document.getElementById("user_mobile_add").value = mobile;
    document.getElementById("user_place_of_birth_add").value = place_of_birth;
    document.getElementById("user_m_place_of_birth_add").value = m_place_of_birth;
    document.getElementById("user_taxid_add").value = taxid;
    document.getElementById("user_insurance_placed_add").value = strIsuranceplace;    
    document.getElementById("user_nationality_add_details").value = nationalityup;    
    document.getElementById("user_religion_add_details").value = religionup;   
    document.getElementById("user_ethnic_add").value = ethnicup;
    document.getElementById("user_insurance_no").value = insurance_no;
    document.getElementById("user_education_add").value = educationup;
    document.getElementById("user_academic_add").value = academic_rank;
    document.getElementById("user_note_add").value = note;

    if(staff_status == "Nghỉ việc"){
     $("#termination_date_group").show();
    }else {
      $("#termination_date_group").hide();
    }  

    jQuery.ajax({
      url: show,
      dataType: 'json',
      success: function(response) {
        $("#user_academic_add").find("option").remove()
        $.each(response.academicrank, function(index, academicrank) {
            $("#user_academic_add").append("<option value='" + academicrank.name + `' ${academic_rank == academicrank.name ? 'selected': ''}>` + academicrank.name + "</option>");
        });
        $("#user_ethnic_add").find("option").remove()
        $.each(response.ethnic, function(index, ethnic) {
            $("#user_ethnic_add").append("<option value='" + ethnic.name + `' ${ethnicup == ethnic.name ? 'selected': ''}>` + ethnic.name + "</option>");
        });
        $("#user_education_add").find("option").remove()
        $.each(response.education, function(index, education) {
            $("#user_education_add").append("<option value='" + education.name + `' ${educationup == education.name ? 'selected': ''}>` + education.name + "</option>");
        });
        $("#user_religion_add_details").find("option").remove()
        $.each(response.religion, function(index, religion) {
            $("#user_religion_add_details").append("<option value='" + religion.name + `' ${religionup == religion.name ? 'selected': ''}>` + religion.name + "</option>");
        });
        $("#user_nationality_add_details").find("option").remove()
        $.each(response.nationality, function(index, nationality) {
            $("#user_nationality_add_details").append("<option value='" + nationality.name + `' ${nationalityup == nationality.name ? 'selected': ''}>` + nationality.name + "</option>");
        });
        $("#user_tbusertype_add_details").find("option").remove()
        $.each(response.tbusertype, function(index, tbusertype) {
            $("#user_tbusertype_add_details").append("<option value='" + tbusertype.name + `' ${staff_type == tbusertype.name ? 'selected': ''}>` + tbusertype.name + "</option>");
        });
        $("#user_tbuserstatus_add_details").find("option").remove()
        $.each(response.tbuserstatus, function(index, tbuserstatus) {
            $("#user_tbuserstatus_add_details").append("<option value='" + tbuserstatus.name + `' ${staff_status == tbuserstatus.name ? 'selected': ''}>` + tbuserstatus.name + "</option>");
        });
        $("#user_insurance_placed_add").find("option").remove()
        $.each(response.tbhospital, function(index, tbhospital) {
            $("#user_insurance_placed_add").append("<option value='" + tbhospital.name + `' ${strIsuranceplace == tbhospital.name ? 'selected': ''}>` + tbhospital.name + "</option>");
        });
      }
    });


                    
    document.getElementById("user_re_password_digest_add").addEventListener("click", function() {clearRePwd()} );
    document.getElementById("user_password_add").addEventListener("click", function() {clearPwd()} );

    document.getElementById("cls_bmtu_form_add_title").innerHTML = strUpdateUser;
    document.getElementById("btn_add_new_user").value = strUpdateUser;


    document.getElementById("user_id").value = id ;
    document.getElementById("user_sid").value = sid;
    document.getElementById("user_username").value = username;
    document.getElementById("user_email").value = email;

    if(benefittype == "1"){
      document.getElementById("user_benefit_type_0").checked = true;
    }else if (benefittype == "2") {
      document.getElementById("user_benefit_type_1").checked = true;
    }else {
      document.getElementById("user_benefit_type_2").checked = true;
    }

    if(gender == "0"){
      document.getElementById("user_gender_0").checked = true;
    }else if (gender == "1") {
      document.getElementById("user_gender_1").checked = true;
    }else {
      document.getElementById("user_gender_2").checked = true;
    }

    if(marriage == "Married"){
      document.getElementById("user_Marriage_Married").checked = true;
    }
    else {
      document.getElementById("user_Marriage_Single").checked = true;
    }

    if(status == "ACTIVE"){
      document.getElementById("user_status_ACTIVE").checked = true;
    }
    else {
      document.getElementById("user_status_INACTIVE").checked = true;
    }

    if(stype == "MEMBER"){
      document.getElementById("user_style_member").checked = true;
    }
    else {
      document.getElementById("user_style_applyer").checked = true;
    }
    var twofaCheckbox = document.getElementById("checkbox-active");
    if (twofa === "YES") {
        twofaCheckbox.checked = true;
        twofaCheckbox.value = "on";
        $(twofaCheckbox).next().html("Bật").css("color", "green");
    } else {
        twofaCheckbox.checked = false;
        twofaCheckbox.value = "off";
        $(twofaCheckbox).next().html("Tắt").css("color", "red");
    }
    var twofaCheckboxExam = document.getElementById("checkbox-active-exam");
    if (twofa_exam === "YES") {
        twofaCheckboxExam.checked = true;
        twofaCheckboxExam.value = "on";
        $(twofaCheckboxExam).next().html("Bật").css("color", "green");
    } else {
        twofaCheckboxExam.checked = false;
        twofaCheckboxExam.value = "off";
        $(twofaCheckboxExam).next().html("Tắt").css("color", "red");
    }
    var twofaCheckboxIn = document.getElementById("checkbox-active-checkin");
    if (ignore_attend === "TRUE") {
        twofaCheckboxIn.checked = true;
        twofaCheckboxIn.value = "TRUE";
        $(twofaCheckboxIn).next().html("Bật").css("color", "green");
    } else {
        twofaCheckboxIn.checked = false;
        twofaCheckboxIn.value = "FALSE";
        $(twofaCheckboxIn).next().html("Tắt").css("color", "red");
    }

    document.getElementById("show_pwd").style.display = "none";
    document.getElementById("show_re_pwd").style.display = "none";
    // document.getElementById("form-add-user-container").style.display = "block";
    document.getElementById("termination_date").value = termination_date;


}

function showTerminationDate() {
  var status = $("#user_tbuserstatus_add_details").val();
  if(status == "Nghỉ việc"){
    $("#termination_date_group").show();
    $("#user_status_INACTIVE").prop("checked", true);
  }else {
    $("#termination_date_group").hide();
    $("#user_status_ACTIVE").prop("checked", true); 
  }  
  
}

function checkNospacePwd(value){
if ( value != " "  &&  value.indexOf(" ") < 0 ){
  return true;
}else{
  return false;
}
}

function checkGmail(value) {
if (/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(value)) {
  return true
} else {
  return false
}
}     

document.getElementById("user_first_name_add").addEventListener("change", function () {
var first_name = document.getElementById('user_first_name_add').value;
var first_name_erro = document.getElementById('user_first_name_add');


error_label.style.display = "none";
first_name_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;


});

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

document.getElementById("user_last_name_add").addEventListener("change", function () {
var last_name = document.getElementById('user_last_name_add').value;
var last_name_erro = document.getElementById('user_last_name_add');  


error_label.style.display = "none";
last_name_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;
var firstname = document.getElementById("user_first_name_add").value.toLowerCase().trim();	
var eng_first_name = removeAccents(firstname);    
var lastname = document.getElementById("user_last_name_add").value;
var eng_last_name = removeAccents(lastname).toLowerCase().split(" ");
// var staff_type = document.getElementById("user_staff_type_add").value;
// var user_sid = document.getElementById("user_sid").value
// var final = "";
// for (let i = 0; i < eng_last_name.length; i++) {        
//   var a = eng_last_name[i].charAt(0);
//   final += a ;   
//   document.getElementById("user_email").value = eng_first_name + final + "@bmtuvietnam.com";
//   if (staff_type == 2) {
//     document.getElementById("user_username").value = eng_first_name + final + "bmtu";  
//     document.getElementById("user_sid").value = user_sid.replace("BUH", "BMTU");
//   }else {
//     document.getElementById("user_username").value = eng_first_name + final + "buh";  
//     document.getElementById("user_sid").value = user_sid.replace("BMTU", "BUH");
//   }
    
// }




});

function is_phonenumber(phonenumber) {
var phoneno = /(84|0[3|5|7|8|9])+([0-9]{8})\b/g;
if(phonenumber.match(phoneno)) {return true;}  
else {return false; }
}

document.getElementById("user_sid").addEventListener("change", function () {


var error_label = document.getElementById('erro_labble_content');
var sid = document.getElementById('user_sid').value;
var sid_erro = document.getElementById('user_sid');

jQuery.ajax({
  data: { check_id: sid},
      type: 'GET',
      url: urlSid,
      success: function (result) {
        if ( result.result_sid == false ){
          error_label.innerHTML = strSidValid1;
          sid_erro.style.border= "1px solid red";
          error_label.style.display="block";
          sid_erro.focus(); 
          document.getElementById("btn_add_new_user").disabled = true;
          return;
        }else {
            

        }
      }
  });



if (checkNospacePwd(sid) == false) {
  error_label.innerHTML = strSidValid2;
  error_label.style.display = "block";
  sid_erro.style.border = "1px solid red";
  sid_erro.focus(); 
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}


if (sid.length < 6) {
  error_label.innerHTML = strSidValid3;
  error_label.style.display = "block";
  sid_erro.style.border = "1px solid red";
  sid_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}



error_label.style.display = "none";
sid_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_username").addEventListener("change", function () {

var userName_erro = document.getElementById('user_username');
var userName = document.getElementById('user_username').value;

jQuery.ajax({
  data: { check_username: userName},
    type: 'GET',
    url: urlUsername,
    success: function (result) {
      if (result.result_usn == false ) {
        error_label.innerHTML = strUsernameVaild1;
        error_label.style.display = "block";
        userName_erro.style.border = "1px solid red";
        userName_erro.focus();
        document.getElementById("btn_add_new_user").disabled = true; 
        return;
      }
    }
  });

  if (checkNospacePwd(userName) == false) {
  error_label.innerHTML = strUsernameVaild2;
  error_label.style.display = "block";
  userName_erro.style.border = "1px solid red";
  userName_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}

if (userName.length < 6) {
  error_label.innerHTML = strUsernameVaild3;
  error_label.style.display = "block";
  userName_erro.style.border = "1px solid red";
  userName_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}  

error_label.style.display = "none";
userName_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_email").addEventListener("change", function () {

var email_erro = document.getElementById('user_email');

var email = document.getElementById('user_email').value;

jQuery.ajax({
  data: { check_email: email},
      type: 'GET',
      url: urlEmail,
      success: function (result) {
        if (result == false ) {
          error_label.innerHTML = strEmailVaild1;
          email_erro.style.border= "1px solid red";
          error_label.style.display="block";    
          email_erro.focus();
          document.getElementById("btn_add_new_user").disabled = true; 
          return;                                         
        }
      }
});

if (checkGmail(email) == false) {
  error_label.innerHTML = strEmailVaild2;
  error_label.style.display = "block";
  email_erro.style.border = "1px solid red";
  email_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}

error_label.style.display = "none";
email_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_password_add").addEventListener("change", function () {

var pwd_erro = document.getElementById('user_password_add');
var pwd = document.getElementById('user_password_add').value;

  if (pwd.length < 8) {
  error_label.innerHTML = strPwdVaild1;
  error_label.style.display = "block";
  pwd_erro.style.border = "1px solid red";
  pwd_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}
if (checkNospacePwd(pwd) == false) {
  error_label.innerHTML = strPwdVaild2;
  error_label.style.display = "block";
  pwd_erro.style.border = "1px solid red";
  pwd_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
} 
if (CheckPassword(pwd) == false) {
  error_label.innerHTML = pwd_vaild_rule;
  error_label.style.display = "block";
  pwd_erro.style.border = "1px solid red";
  pwd_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}

error_label.style.display = "none";
pwd_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_re_password_digest_add").addEventListener("change", function () {

var rePwd_erro = document.getElementById('user_re_password_digest_add');
var rePwd = document.getElementById('user_re_password_digest_add').value;
var pwd = document.getElementById('user_password_add').value;



  if (rePwd != pwd) {
  error_label.innerHTML = strPwdVaild3;
  error_label.style.display = "block";
  rePwd_erro.style.border = "1px solid red";
  rePwd_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}


error_label.style.display = "none";
rePwd_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;
});

document.getElementById("user_mobile_add").addEventListener("change", function () {
var mobile_erro = document.getElementById('user_mobile_add');
var mobile = document.getElementById('user_mobile_add').value;



if (mobile.length <10 ) {
  error_label.innerHTML = strMobileVaild1;
  error_label.style.display = "block";
  mobile_erro.style.border = "1px solid red";
  mobile_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}
if (is_phonenumber(mobile) == false) {
  error_label.innerHTML = strMobileVaild2;
  error_label.style.display = "block";
  mobile_erro.style.border = "1px solid red";
  mobile_erro.focus();
  document.getElementById("btn_add_new_user").disabled = true;
  return;
}



error_label.style.display = "none";
mobile_erro.style.border = "1px solid #ced4da";
document.getElementById("btn_add_new_user").disabled = false;

});

// document.getElementById("user_staff_type_add").addEventListener("change", function () {
//   var staff_type = document.getElementById("user_staff_type_add").value;
//   var user_username = document.getElementById("user_username").value;
//   var user_sid = document.getElementById("user_sid").value;
  
//   if (staff_type == 2) {
//     document.getElementById("user_username").value = user_username.replace("buh", "bmtu");
//     document.getElementById("user_sid").value = user_sid.replace("BUH", "BMTU");
//   }else {
//     document.getElementById("user_username").value = user_username.replace("bmtu", "buh");  
//     document.getElementById("user_sid").value = user_sid.replace("BMTU", "BUH");
//   }
// });

function containsSpecialChars(str) {
const specialChars =/[`!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~]/;
return specialChars.test(str);
}

function clearPwd() {
document.getElementById('user_password_add').value= "";
}

function clearRePwd() {
document.getElementById('user_re_password_digest_add').value= "";
}

document.getElementById('btn_add_new_user').onclick = function () {                  

  var error_label = document.getElementById('erro_labble_content');
  var id = document.getElementById("user_id").value;

  var first_name = document.getElementById('user_first_name_add').value;
  var first_name_erro = document.getElementById('user_first_name_add');

  var last_name = document.getElementById('user_last_name_add').value;
  var last_name_erro = document.getElementById('user_last_name_add');  

  var sid = document.getElementById('user_sid').value;
  var sid_erro = document.getElementById('user_sid');

  var userName = document.getElementById('user_username').value;
  var userName_erro = document.getElementById('user_username');

  var email = document.getElementById('user_email').value;
  var email_erro = document.getElementById('user_email');

  var pwd = document.getElementById('user_password_add').value;
  var pwd_erro = document.getElementById('user_password_add');

  var rePwd = document.getElementById('user_re_password_digest_add').value;
  var rePwd_erro = document.getElementById('user_re_password_digest_add');

  var mobile = document.getElementById('user_mobile_add').value;
  var mobile_erro = document.getElementById('user_mobile_add');

  if (first_name == "") {
    error_label.innerHTML = strFname;
    error_label.style.display = "block";
    first_name_erro.style.border = "1px solid red"; 
    first_name_erro.focus();                    
  } else if (last_name == "") {
    error_label.innerHTML = strLname;
    error_label.style.display = "block";
    last_name_erro.style.border = "1px solid red";
    first_name_erro.style.border = "1px solid #ced4da";
    last_name_erro.focus();
  } else if (sid == "") {
    error_label.innerHTML = strSid;
    error_label.style.display = "block";
    sid_erro.style.border = "1px solid red";
    last_name_erro.style.border = "1px solid #ced4da";
    sid_erro.focus();
  } 
    else if (email == "") {
    error_label.innerHTML = strEmail;
    error_label.style.display = "block";
    email_erro.style.border = "1px solid red";
    sid_erro.style.border = "1px solid #ced4da";
    email_erro.focus();
  }
    else if (userName == "") {
    error_label.innerHTML = strUsername;
    error_label.style.display = "block";
    userName_erro.style.border = "1px solid red";
    email_erro.style.border = "1px solid #ced4da";
    userName_erro.focus();
  } else if (pwd == "") {
    error_label.innerHTML = strPwd;
    error_label.style.display = "block";
    pwd_erro.style.border = "1px solid red";
    userName_erro.style.border = "1px solid #ced4da";
    pwd_erro.focus();
  } else if (rePwd == "") {
    error_label.innerHTML = strRePwd;
    error_label.style.display = "block";
    rePwd_erro.style.border = "1px solid red";
    pwd_erro.style.border = "1px solid #ced4da";
    rePwd_erro.focus();
  }else if (rePwd != pwd) {
    error_label.innerHTML = strPwdVaild3;
    error_label.style.display = "block";
    rePwd_erro.style.border = "1px solid red";
    pwd_erro.style.border = "1px solid #ced4da";
    rePwd_erro.focus();
  }
  else if  (mobile == "") {
    error_label.innerHTML = strMobile;
    error_label.style.display = "block";
    mobile_erro.style.border = "1px solid red";
    rePwd_erro.style.border = "1px solid #ced4da";
    mobile_erro.focus();
  }
  
  else {  
      mobile_erro.style.border = "1px solid #ced4da";
      pwd_erro.style.border = "1px solid #ced4da";
      email_erro.style.border = "1px solid #ced4da";
      userName_erro.style.border = "1px solid #ced4da";
      sid_erro.style.border = "1px solid #ced4da";
      last_name_erro.style.border = "1px solid #ced4da";
      first_name_erro.style.border = "1px solid #ced4da";
      rePwd_erro.style.border = "1px solid #ced4da";
      error_label.style.display = "none";     
      document.getElementById("btn_add_new_user").style.display = "none";
      document.getElementById("loading_button").style.display = "block";
      document.getElementById("btn_add_new_user").type= "submit";
      
  }
}

// init import form event
function initImportFile(){
  // On file selected
  $("#file-import-user").on('change',(e)=>{
    let file = $("#file-import-user")[0].files[0];
    if(file != undefined && file != null){
      $("#import-file-containter").show();
      $("#button-upload-file").toggleClass("btn-secondary disabled",false);
      $("#file-process").css("width","0%");
      $("#import-file-size").html(formatBytes(file.size));
      $("#import-file-name").html(file.name);
    }
  })
}
initImportFile();

/**
 * Call when click import file
 */
function clickOpenImport(){
  // clean form
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let reUpload = $("#reupload-button");
  $("#import-file-containter").hide();
  uploadBtn.toggleClass("disabled",true);
  uploadBtn.show();
  selectBtn.toggleClass("disabled",false);
  selectBtn.show();
  reUpload.hide();

  $("#file-import-user").val(null);
  $('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr("content"));
  $('#import-result').collapse("hide");
  uploadBtn.find(".upload-text").show();
  uploadBtn.find(".upload-process").hide();

  $("#update_list").html("");
  $("#error_list").html("");
  $("#import-server-error").hide();
}

/**
 * Click upload file to server
 */
function clickImportFile(){
  let file = $("#file-import-user")[0].files[0];
    if(file != undefined && file != null){
      
      let uploadBtn = $("#button-upload-file");
      let selectBtn = $("#label-select-file");
    
      // disable cancel when on process
      $(".button-cancel-import").toggleClass("disabled",true);

      // process state: 2
      uploadBtn.toggleClass("disabled",true);
      selectBtn.toggleClass("disabled",true);
      selectBtn.toggleClass("btn-secondary disabled",true);
      uploadBtn.find(".upload-text").html(trans_uploading);
      uploadBtn.find(".upload-process").show();

      // send file
      sendImportFile(file);
    }

  
  
}

function clickReupload(){
  let resultShow = $('#import-result');
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let reUpload = $("#reupload-button");

  $("#import-file-containter").hide();
  resultShow.collapse('hide');
  uploadBtn.toggleClass("btn-secondary disabled",true);
  uploadBtn.find(".upload-text").html(trans_upload + `<span class="fas fa-upload ms-1"></span>`);
  reUpload.hide();
  uploadBtn.show();
  selectBtn.show();

  $("#update_list").html("");
  $("#error_list").html("");
  $("#import-server-error").hide();
}


let import_update_list = [];
function renderResult(result){
  import_update_list = result.updates;
  // disable cancel when upload done
  $(".button-cancel-import").toggleClass("disabled",false);
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let resultShow = $('#import-result');
  let reUpload = $("#reupload-button");

  uploadBtn.toggleClass("btn-secondary disabled",true);
  uploadBtn.find(".upload-text").html(trans_upload);
  uploadBtn.find(".upload-process").hide();
  uploadBtn.hide();
  
  selectBtn.toggleClass("disabled",false);
  selectBtn.hide();

  reUpload.show();

  $("#file-import-user").val(null);
  //  load data
  $("#result_total").html(result.result_total);
  $("#success_count").html(result.success_count);
  let valids = result.valids;
  let error_count = $("#error_count");
  error_count.html(valids.length);
  error_count.toggleClass("text-400",valids.length <= 0);

  // update
  let update_count = $("#update_count");
  update_count.html(import_update_list.length);
  update_count.toggleClass("text-400",import_update_list.length <= 0);
  if(import_update_list.length > 0){
    $("#update-all-button").show();
  }else{
    $("#update-all-button").hide();
  }
  let updateContainer = $("#update_list");
  import_update_list.forEach(user=>{
    if (user.avatar_url == null){
      user.avatar_url = no_avatar_url;
    }
    updateContainer.append(`<div id="update-import-${user.id}" class="border rounded-1 p-2 update-import-item" style="display: flex;align-items: center;justify-content: space-between;">
                              <div style="display: flex;">
                                <div class="avatar me-2" style="display: flex;justify-content: center;flex-direction: column;">
                                  <div style="border: 1px solid var(--falcon-badge-soft-secondary-background-color);border-radius: 50%;background-image: url(${user.avatar_url});overflow: hidden;background-repeat: no-repeat;background-size: cover;height: 2.9rem;width: 2.9rem;">
                                  </div>
                                </div>
                                <div>
                                  <p class="m-0" style="font-size: 0.9em;font-weight: 600;color: var(--falcon-badge-soft-dark-color);">${user.origin_name}</p>
                                  <p class="m-0" style="font-size: 0.8em;font-weight: 500;color: var(--falcon-badge-soft-info-color);">${user.origin_email}</p>
                                  <p class="badge badge-soft-danger m-0 error-message" style="font-size: 0.75em;text-align: left;width: fit-content;display:none;"></p>
                                </div>
                              </div>
                              <div>
                                <div class="btn btn-secondary btn-sm btn-action" style="font-size: 0.7em;" onclick="skipUpdate(${user.id})">${trans_skip}</div>
                                <div class="btn btn-primary btn-sm btn-action btn-update" style="font-size: 0.7em;min-width: 65px;" onclick="updateImport(${user.id})">
                                  <span class="text-update" >${trans_update}</span>
                                  <span class="spinner-border spinner-border-sm process-update" role="status" aria-hidden="true" style="display:none;height: 13px;width: 13px;"></span>
                                </div>
                                <span class='fas fa-check text-success me-3 icon-done' style="width:18px; height:18px;display:none;"></span>
                              </div>
                            </siv>`)
  });

  // errors
  let error_list = $("#error_list");
  error_list.html("");
  valids.forEach(valid=>{
    error_list.append(`<p class="m-0">
                        <span class="badge me-1 badge-soft-danger">${valid.line}</span>
                      </p>`);
  })
  resultShow.collapse('show');

}

/**
 * Handle update duplicate import
 * @param {any} userId
 */
function updateImport(userId){
  // get user data
  let user = null
  import_update_list.forEach(item=>{
    if(item.id === userId){
      user = item;
    }
  })

  if(user == null){
    console.log("Not found :",userId)
    return;
  }
  submitUpdateImportForm(`#update-import-${userId}`,[user]);

}

function submitUpdateImportForm(itemId,data){

  let json_string = JSON.stringify(data);
  const blob = new Blob([json_string], { type: 'text/plain' });
  let file = new File([blob], "file.text",{type:"text/plain", lastModified:new Date().getTime()});
  let formdata = new FormData();
  formdata.append("file",file);
  formdata.append("authenticity_token",$('meta[name="csrf-token"]').attr("content"));

  var request = new XMLHttpRequest();
  request.onreadystatechange = function(){
    if(request.readyState == 4){
      if(request.status >= 200 && request.status <= 299){
        let result = JSON.parse(request.responseText);
        resultUpdateImport(result);
      }else{
        showServerError();
      }
    }
  };
  let action = $("#update-import-action").html();
  request.open('POST', action);
  request.send(formdata);

  // upload button effect
  if (itemId != null){
    let itemContainer = $(itemId);
    itemContainer.find(".text-update").hide();
    itemContainer.find(".process-update").show();
  
    // all button effect
    itemContainer.find(".btn-action").toggleClass("disabled",true);
    itemContainer.find(".error-message").hide();
  }else{
    let list_item = $("#update_list");

    list_item.find(".text-update").hide();
    list_item.find(".process-update").show();
    // all button effect
    list_item.find(".btn-action").toggleClass("disabled",true);
    list_item.find(".error-message").hide();
  }
}

/**
 * Handle update all duplicate import
 */
function uploadAllImport(){
  submitUpdateImportForm(null,import_update_list);
}

/**
 * Onclick Skip update
 * @param {any} userId 
 */
function skipUpdate(userId){
  // remove store user
  for (let i = 0; i < import_update_list.length; i++) {
    if(userId == import_update_list[i].id){
      import_update_list.splice(i, 1);
      break;
    }
  }
  // remove element
  $(`#update-import-${userId}`).remove();

  // count
  $("#update_count").html(import_update_list.length);

  if(import_update_list.length > 0){
    $("#update-all-button").show();
  }else{
    $("#update-all-button").hide();
  }
}

/**
 * Call from back end
 */
function resultUpdateImport(result){
  result.updateds.forEach(update=>{

    for (let i = 0; i < import_update_list.length; i++) {
      if(update.id == import_update_list[i].id){
        import_update_list.splice(i, 1);
        break;
      }
    }

    let wrapContainer = $(`#update-import-${update.id}`);
    wrapContainer.find(".icon-done").show();
    wrapContainer.find(".btn-action").remove();
  });

  result.errors.forEach(item=>{
    
    let wrapContainer = $(`#update-import-${item.id}`);
    // update button
    wrapContainer.find(".text-update").show();
    wrapContainer.find(".process-update").hide();
    // all action button
    wrapContainer.find(".btn-action").toggleClass("disabled",false);
    // show error message
    wrapContainer.find(".error-message").show();
    wrapContainer.find(".error-message").html(item.message);
  })
}

/**
 * Send file to backend action
 * @param {File} file 
 */
function sendImportFile(file){

  let processItem = $("#file-process");

  let formdata = new FormData();
  formdata.append("file",file);
  formdata.append("authenticity_token",$('meta[name="csrf-token"]').attr("content"));

  var request = new XMLHttpRequest();
  request.onreadystatechange = function(){
      if(request.readyState == 4 && request.status >= 200 && request.status <= 299){
          try {
            let result = JSON.parse(request.responseText);
            if (result.code >= 400){
              showServerError();
            }else{
              // console.log(result);
              renderResult(result);
            }
          } catch (e){
            console.log(e)
            showServerError();
          }
      }
      else if(request.status >= 400 && request.readyState == 4){
        try{
          let result = JSON.parse(request.responseText);
        }catch(e){
          console.log(e);
        }
        showServerError();
      }
  };

  request.upload.addEventListener('progress', function(e){
      var progress_width = Math.ceil(e.loaded/e.total * 100);
      processItem.css("width",`${progress_width}%`);
      if(progress_width == 100){
        setTimeout(() => {
          $("#import-file-containter").hide();
          processItem.css("width","0%");
          $("#button-upload-file").find(".upload-text").html(trans_processing);
        }, 400);
      }
  }, false);

  let action = $("#import-action").html();
  request.open('POST', action);
  request.send(formdata);
}

function showServerError(){
  $(".button-cancel-import").toggleClass("disabled",false);
  let uploadBtn = $("#button-upload-file");
  let selectBtn = $("#label-select-file");
  let resultShow = $('#import-result');
  let reUpload = $("#reupload-button");


  uploadBtn.toggleClass("btn-secondary disabled",true);
  uploadBtn.find(".upload-text").html(trans_upload);
  uploadBtn.find(".upload-process").hide();
  uploadBtn.hide();
  
  selectBtn.toggleClass("disabled",false);
  selectBtn.hide();

  reUpload.show();

  $("#file-import-user").val(null);
  $("#update_list").html("");
  $("#error_list").html("");
  resultShow.collapse('hide');
  $("#import-server-error").show();
}

/**
 * Fortmat file size
 * @param {*} a Fiel size
 * @param {*} b 
 * @param {*} k 
 * @returns 
 */
function formatBytes(a,b=2,k=1024)
{
    let d=Math.floor(Math.log(a)/Math.log(k));
    return 0 == a ? "0 Bytes" : parseFloat((a/Math.pow(k,d)).toFixed(Math.max(0,b)))+" "+["Bytes","KB","MB","GB","TB","PB","EB","ZB","YB"][d]
}


function CheckPassword(inputtxt){ 
  var decimal=  /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9])(?!.*\s).{8,99}$/;
  if(inputtxt.match(decimal)){     
    return true;
  }
  else{   
  return false;
  }
}  

function isCheckboxChecked() {
  // Return true if at least one checkbox inside the div is checked, otherwise false
  return $('#select_add_organization_bd input[type="checkbox"]:checked').length > 0;
}