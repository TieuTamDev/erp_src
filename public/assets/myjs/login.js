$(document).ready(function() {
    $("#show_hide_password a").on('click', function(event) {
        event.preventDefault();
        if($('#show_hide_password input').attr("type") == "text"){
            $('#show_hide_password input').attr('type', 'password');
            $('#icon_eye_capp').addClass( "fa-eye-slash" );
            $('#icon_eye_capp').removeClass( "fa-eye" );
        }else if($('#show_hide_password input').attr("type") == "password"){
            $('#show_hide_password input').attr('type', 'text');
            $('#icon_eye_capp').removeClass("fa-eye-slash");
            $('#icon_eye_capp').addClass("fa-eye");
        }
    });
});
function usernameNotFound(){
    $("#valid-login").text("Tài khoản đăng nhập không chính xác , vui lòng nhập lại.");
    $("#valid-login").removeClass("d-none");
}
function errorPassword(attempts) {
    const maxAttempts = 5;
    const remainingAttempts = maxAttempts - attempts;
    $("#valid-login").text(`Mật khẩu không chính xác, bạn còn ${remainingAttempts} lần nhập.`);
    $("#valid-login").removeClass("d-none");
}
function userInactive() {
    $("#valid-login").text("Tài khoản của bạn đã bị khóa do nhập sai mật khẩu quá nhiều lần.");
    $("#valid-login").removeClass("d-none");
}
function showTwoAuth(id) {
    $("#two-auth-modal").modal("show");
    $("#form-two-factor-auth").attr('action', `/login_two_auth/${id}`);
}
$("#form-two-factor-auth #token").on('click', function(e) {
    $("#valid-two-auth").addClass("d-none");
})

function errorExpired() {
    $("#valid-two-auth").text("Mã xác minh đã quá hạn vui lòng nhập mã mới nhất")
    $("#valid-two-auth").removeClass("d-none");
}

function errorToken(attempts) {
    const maxAttempts = 5;
    const remainingAttempts = maxAttempts - attempts;
    $("#valid-two-auth").text(`Mã xác thực không chính xác, bạn còn ${remainingAttempts} lần nhập.`);
    $("#valid-two-auth").removeClass("d-none");
}

function accountInactive() {
    $("#valid-two-auth").text("Tài khoản của bạn đã bị khóa do nhập sai mã xác minh quá nhiều lần.");
    $("#valid-two-auth").removeClass("d-none");
}
document.getElementById("btn-login-twofa").addEventListener("click", function() {
    if (checkAllInputsFilled()) {
        getConcatenatedString();
    }
});
function handleInput(currentInput, nextInputId, prevInputId) {
    if (currentInput.value.length === currentInput.maxLength) {
        if (nextInputId && nextInputId !== "null") {
            document.getElementById(nextInputId).focus();
        } else if (nextInputId == "null") {
            getConcatenatedString();
        }
    }
}

function handleBackspace(event, prevInputId) {
    if (event.key === 'Backspace' && event.target.value.length === 0 && prevInputId && prevInputId !== "null") {
        document.getElementById(prevInputId).focus();
    }
}

function handlePaste(event) {
    const pasteData = event.clipboardData.getData('text').replace(/\D/g, ''); // Loại bỏ tất cả ký tự không phải số
    const digits = document.querySelectorAll("[id^='digit']");
    let pastedIndex = 0;

    for (let i = 0; i < digits.length && pastedIndex < pasteData.length; i++) {
        digits[i].value = pasteData[pastedIndex];
        pastedIndex++;
    }

    event.preventDefault();
    getConcatenatedString();
}


function checkAllInputsFilled() {
    let digits = document.querySelectorAll("[id^='digit']");
    for (let i = 0; i < digits.length; i++) {
        if (digits[i].value.length !== digits[i].maxLength || !/^\d$/.test(digits[i].value)) {
            return false;
        }
    }
    return true;
}

function getConcatenatedString() {
    if (!checkAllInputsFilled()) {
        return;
    }

    let digits = document.querySelectorAll("[id^='digit']");
    let concatenatedString = "";
    for (let i = 0; i < digits.length; i++) {
        concatenatedString += digits[i].value;
    }
    $("#token").val(concatenatedString);
}
function validateNumberInput(event) {
    const value = event.target.value;
    if (!/^\d*$/.test(value)) {
        event.target.value = value.slice(0, -1);
    }
}


