function delete_loading_mandoctype(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
  }

  function openFormAddMandoctype() {
    // document.getElementById("form-add-mandoctype-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = createMandoctype;
    document.getElementById("btn_add_new_mandoctype_buttton").value = createMandoctype;
    document.getElementById("mandoctype_id_add").value = "";
    document.getElementById("mandoctype_scode_add").value = "";
    document.getElementById("mandoctype_name_add").value = "";    
    document.getElementById("mandoctype_note_add").value = "";    
    document.getElementById("mandoctype_name_add").addEventListener("keyup", function() {getTextToASCII()} );
    document.getElementById("mandoctype_scode_add").style.border = "1px solid #ced4da";
    document.getElementById("mandoctype_name_add").style.border = "1px solid #ced4da";
    document.getElementById('erro_labble_content').style.display = "none";
    $("#erro_labble_content").css("display","none"); 

  }

  function closeFormAddMandoctype() {
    // document.getElementById("form-add-mandoctype-container").style.display = "none";
    document.getElementById("mandoctype_id_add").value = "";
    document.getElementById("mandoctype_name_add").value = "";
    document.getElementById("mandoctype_note_add").value = "";    
    document.getElementById("mandoctype_scode_add").value = "";
      document.getElementById("mandoctype_scode_add").style.border = "1px solid #ced4da";
      document.getElementById("mandoctype_name_add").style.border = "1px solid #ced4da";
      document.getElementById('erro_labble_content').style.display = "none";
      
  }

  function openFormUpdateMandoctype(id, name, scode, note, status) {
    // document.getElementById("form-add-mandoctype-container").style.display = "block";
    document.getElementById("cls_bmtu_form_add_title").innerHTML = updateMandoctype;
    document.getElementById("btn_add_new_mandoctype_buttton").value = updateMandoctype;
    document.getElementById("mandoctype_id_add").value = id;
    document.getElementById("mandoctype_scode_add").value = scode;
    document.getElementById("mandoctype_name_add").value = name;
    document.getElementById("mandoctype_note_add").value = note;    

    document.getElementById("mandoctype_name_add").addEventListener("keyup", function() {} );
    if(status == "ACTIVE"){
      document.getElementById("mandoctype_status_active").checked = true;
    }
    else {
      document.getElementById("mandoctype_status_inactive").checked = true;
    }
    $("#erro_labble_content").css("display","none"); 

  }

  function getTextToASCII() {
    var value_name = document.getElementById("mandoctype_name_add").value;
    var value_scode = document.getElementById("mandoctype_scode_add");
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

    document.getElementById("btn_add_new_mandoctype_buttton").addEventListener("click", function() {
      var id_check = $("#mandoctype_id_add").val();
      var name_check = $("#mandoctype_name_add").val();
      var scode_check = $("#mandoctype_scode_add").val();
      $("#id_check").val(id_check);
      $("#name_check").val(name_check);
      $("#scode_check").val(scode_check);
      $("#check_duplicate").submit();    
  });