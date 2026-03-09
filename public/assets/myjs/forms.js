function delete_loading_form(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
  }


  function openFormAddform() {
    // document.getElementById("form-add-form-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = createform;
    document.getElementById("btn_add_new_form_buttton").value = createform;
    document.getElementById("form_add_form").reset();  
    document.getElementById("form_name_add").addEventListener("keyup", function() {getTextToASCII()} );
  }

  function closeFormAddform() {
    document.getElementById("form-add-form-container").style.display = "none";
    document.getElementById("form_add_form").reset();        
  }

  function openFormUpdateform(id, name, scode,app,note, contents, status) {
    // document.getElementById("form-add-form-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = updateform;
    document.getElementById("btn_add_new_form_buttton").value = updateform;
    document.getElementById("form_id_add").value = id;
    document.getElementById("form_scode_add").value = scode;
    document.getElementById("form_name_add").value = name;
    document.getElementById("form_app_add").value = app;
    document.getElementById("form_note_add").value = note;
    document.getElementById("form_content_add").value = contents;
    document.getElementById("form_name_add").addEventListener("keyup", function() {} );
    if(status == "ACTIVE"){
      document.getElementById("form_status_active").checked = true;
    }
    else {
      document.getElementById("form_status_inactive").checked = true;
    }

  }

  function getTextToASCII() {
    var value_name = document.getElementById("form_name_add").value;
    var value_scode = document.getElementById("form_scode_add");
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

  $('#myModal').on('shown.bs.modal', function () {
    $('#myInput').trigger('focus')
  })
    $('#search').bind('keypress keydown keyup', function(e){
      if(e.keyCode == 13) { e.preventDefault(); }
    });

    document.getElementById("btn_add_new_form_buttton").addEventListener("click", function() {
      document.getElementById("btn_add_new_form_buttton").style.display = "none";
      document.getElementById("loading_button_form").style.display = "block";
  });
