function delete_loading_gsurvey(element) {
  element.style.display = "none";
  element.previousElementSibling.style.display = "none";
  element.nextElementSibling.style.display = "block";
}

function openFormAddGsurvey() {
  document.getElementById("cls_bmtu_form_add_title").innerHTML = create_translate;
  document.getElementById("btn_add_new_gsurvey_buttton").value = create_translate;
  document.getElementById("form_add_gsurvey").reset();  
  document.getElementById("gsurvey_name_add").addEventListener("keyup", function() { getTextToASCII(); });
}

function openFormUpdateform(id, name, scode, iorder, note, status) {
  document.getElementById("cls_bmtu_form_add_title").innerHTML = update_translate;
  document.getElementById("btn_add_new_gsurvey_buttton").value = update_translate;
  document.getElementById("gsurvey_id_add").value = id;
  document.getElementById("gsurvey_code_add").value = scode;
  document.getElementById("gsurvey_name_add").value = name;
  document.getElementById("gsurvey_iorder_add").value = iorder;
  document.getElementById("gsurvey_note_add").value = note;
  document.getElementById("gsurvey_name_add").addEventListener("keyup", function() {}); // Reset event listener
  if (status == "ACTIVE") {
    document.getElementById("gsurvey_status_active").checked = true;
  } else {
    document.getElementById("gsurvey_status_inactive").checked = true;
  }
}

function getTextToASCII() {
  var value_name = document.getElementById("gsurvey_name_add").value;
  var value_scode = document.getElementById("gsurvey_code_add");
  if (value_name) {
    var content = removeVietnameseTones(value_name).replace(/ /g, '-');
    if (value_scode) {
      value_scode.value = content.toUpperCase();
    }
  }
}

function removeVietnameseTones(str) {
  str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a");
  str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e");
  str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i");
  str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o");
  str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u");
  str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y");
  str = str.replace(/đ/g, "d");
  str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
  str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
  str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
  str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
  str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
  str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
  str = str.replace(/Đ/g, "D");
  str = str.replace(/\u0300|\u0301|\u0303|\u0309|\u0323/g, ""); // ̀ ́ ̃ ̉ ̣
  str = str.replace(/\u02C6|\u0306|\u031B/g, ""); // ˆ ̆ ̛
  str = str.replace(/ + /g, " ");
  str = str.trim();
  str = str.replace(/!|@|%|\^|\*|\(|\)|\+|\=|\<|\>|\?|\/|,|\.|\:|\;|\'|\"|\&|\#|\[|\]|~|\$|_|`|-|{|}|\||\\/g, " ");
  return str;
}

$('#myModal').on('shown.bs.modal', function () {
  $('#myInput').trigger('focus');
});

$('#search').bind('keypress keydown keyup', function(e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});

document.getElementById("btn_add_new_gsurvey_buttton").addEventListener("click", function(event) {
  event.preventDefault(); // Ngăn submit ngay lập tức

  // Lấy các phần tử
  const submitButton = document.getElementById('btn_add_new_gsurvey_buttton');
  const loadingButton = document.getElementById('loading_button_gsurvey');
  const errorLabel = document.getElementById('erro_labble_content');
  const form = document.getElementById('form_add_gsurvey');
  const gsurveyNameInput = document.getElementById('gsurvey_name_add');
  const gsurveyIorderInput = document.getElementById('gsurvey_iorder_add');

  // Reset thông báo lỗi và border đỏ
  errorLabel.style.display = 'none';
  errorLabel.innerHTML = ''; // Sử dụng innerHTML để hỗ trợ <br>
  gsurveyNameInput.style.border = ''; // Xóa border đỏ
  gsurveyIorderInput.style.border = ''; // Xóa border đỏ

  // Lấy giá trị các field
  const gsurveyName = gsurveyNameInput.value.trim();
  const gsurveyIorder = gsurveyIorderInput.value;

  // Kiểm tra validation
  let errors = [];

  // Kiểm tra tên nhóm khảo sát (bắt buộc nhập)
  if (!gsurveyName) {
    errors.push('Tên nhóm khảo sát không được để trống.');
    gsurveyNameInput.style.border = '2px solid red'; // Thêm border đỏ cho input bị lỗi
  }

  // Kiểm tra độ ưu tiên (phải >= 1)
  const iorderValue = parseInt(gsurveyIorder, 10);
  if (isNaN(iorderValue) || iorderValue < 1) {
    errors.push('Độ ưu tiên phải là số nguyên dương lớn hơn hoặc bằng 1.');
    gsurveyIorderInput.style.border = '2px solid red'; // Thêm border đỏ cho input bị lỗi
  }

  // Nếu có lỗi, hiển thị thông báo trên 2 dòng và dừng submit
  if (errors.length > 0) {
    errorLabel.innerHTML = errors.join('<br>'); // Sử dụng <br> để ngắt dòng
    errorLabel.style.display = 'block';
    return;
  }

  // Nếu không có lỗi, hiển thị loading và submit form
  submitButton.style.display = 'none';
  loadingButton.style.display = 'block';
  form.submit();
});
// Hàm ngăn nhập số thập phân và ký tự không phải số
function restrictDecimal(event) {
  const charCode = event.charCode || event.keyCode;
  if (charCode === 46 || !/^\d$/.test(String.fromCharCode(charCode))) { // Chặn dấu chấm (.) và ký tự không phải số
    event.preventDefault();
  }
}