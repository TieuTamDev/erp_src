    var citis_address = document.getElementById("txt_province");
    var district_address = document.getElementById("txt_district");
    var ward_address = document.getElementById("txt_ward");
    var ParameterAddress = {
      url: image_path, 
      method: "GET", 
      responseType: "application/json", 
    };
    var promise_address = axios(ParameterAddress);
    promise_address.then(function (result) {
      renderCityAddress(result.data);
    });
    
    function renderCityAddress(data) {
      for (const x of data) {
        var opt = document.createElement('option');
         opt.value = x.Name;
         opt.text = x.Name;
         opt.setAttribute('data-id', x.Id);
         citis_address.options.add(opt);
      }
      citis_address.onclick = function () {
        district_address.length = 1;
        ward_address.length = 1;
        if(this.options[this.selectedIndex].dataset.id != ""){
          const result = data.filter(n => n.Id === this.options[this.selectedIndex].dataset.id);
    
          for (const k of result[0].Districts) {
            var opt = document.createElement('option');
             opt.value = k.Name;
             opt.text = k.Name;
             opt.setAttribute('data-id', k.Id);
             district_address.options.add(opt);
          }
        }
      };
      district_address.onclick = function () {
        ward_address.length = 1;
        const dataCityAddress = data.filter((n) => n.Id === citis_address.options[citis_address.selectedIndex].dataset.id);
        if (this.options[this.selectedIndex].dataset.id != "") {
          const dataWardsAddress = dataCityAddress[0].Districts.filter(n => n.Id === this.options[this.selectedIndex].dataset.id)[0].Wards;
    
          for (const w of dataWardsAddress) {
            var opt = document.createElement('option');
             opt.value = w.Name;
             opt.text = w.Name;
             opt.setAttribute('data-id', w.Id);
             ward_address.options.add(opt);
          }
        }
      };
    }

    function clickCollapseAddress(element){
        document.getElementById('colapse-icon-address').style.rotate = element.className.includes('collapsed') ? "unset" : "90deg";
    }  
    function openFormAddAdr() {
      document.getElementById("id_add_address").style.display = "none";
      document.getElementById("id_cancel_add_address").style.display = "block";
      $('#form_add_address').trigger("reset");
      document.getElementById("txt_province").value = "Tỉnh Đắk Lắk";
      document.getElementById("txt_province").click();
      document.getElementById("txt_district").value = "Thành phố Buôn Ma Thuột"; 
      document.getElementById("txt_district").click();
      document.getElementById("txt_ward").value = "Phường Tân An"; 
      document.getElementById("txt_ward").click();
      document.getElementById("cls_bmtu_form_add_adr_title").innerHTML = newAdd;
      document.getElementById("name-btn-address").innerHTML = newAdd;
      document.getElementById("button-address-file").classList.add("d-none");
        document.getElementById("form-list-file-address").classList.add("d-none");
    }

    document.getElementById("id_cancel_add_address").onclick = function() {
      document.getElementById("id_add_address").style.display = "block";
      document.getElementById("id_cancel_add_address").style.display = "none";
    }

    function openFormUpdateAdr (id, address_user_id, name, country, province, district, ward, street, no, stype, status, session_id_address) {
      document.getElementById("collapse_form_add_address").classList.add("show");
      document.getElementById("id_add_address").style.display = "none";
      document.getElementById("id_cancel_add_address").style.display = "block";
      $('#form_add_address').trigger("reset");
      document.getElementById("txt_province").value = province;
      document.getElementById("txt_province").click();
      document.getElementById("txt_district").value = district; 
      document.getElementById("txt_district").click();
      document.getElementById("txt_ward").value = ward; 
      document.getElementById("txt_ward").click();
      $("#list-mediafile-address tr").remove();
      let arraddressFile = [];
      document.getElementById("list-mediafile-address").value = "";
      document.getElementById("form-list-file-address").classList.remove("d-none");
      document.getElementById("button-address-file").classList.remove("d-none");
      document.getElementById('erro_labble_address').style.display = "none";              
      document.getElementById('address_name').style.border = "1px solid #ced4da";              
      document.getElementById("cls_bmtu_form_add_adr_title").innerHTML = upAdd;
      document.getElementById("name-btn-address").innerHTML = upAdd;

      if(stype == "0"){
      document.getElementById("sel_adr_stype_active").checked = true;
      }
      else {
      document.getElementById("sel_adr_stype_inactive").checked = true;
      }
      if(status == "0"){
      document.getElementById("sel_adr_status_active").checked = true;
      }
      else {
      document.getElementById("sel_adr_status_inactive").checked = true;
      }

      document.getElementById("address_id").value = id;
      document.getElementById("address_name").value = name;
      document.getElementById("txt_country").value = country;
      document.getElementById("txt_street").value = street;
      document.getElementById("txt_no").value = no;

      let action_upload_address = media_up_add;
      
      formMediaAddress.setAction(action_upload_address + "?address_id="+ id);
      let idAddress = document.getElementById("id_address_btn").getAttribute("myidAddress");
      // start show filemedia list
          $.ajax({
            type: "GET",
            url: add_user_edit,
            data: { idAddress: session_id_address },
            dataType: "JSON",
            success: function (response) {
                  formMediaAddress.removeTableItemAll();
                  formMediaAddress.tableAddItems(response.docs);
            }
        });
    //end     
        
    }
  // check valid
    var erro_label_adr1 = document.getElementById('erro_labble_address');

    document.getElementById("address_name").addEventListener("change", function () {

    var adr_name = document.getElementById('address_name');
    var erro_label_adr1 = document.getElementById('erro_labble_address');

    erro_label_adr1.style.display = "none";
    adr_name.style.border = "1px solid #ced4da";
    });

    document.getElementById("txt_country").addEventListener("change", function () {

    var adr_country = document.getElementById('txt_country');
    var erro_label_adr1 = document.getElementById('erro_labble_address');

    erro_label_adr1.style.display = "none";
    adr_country.style.border = "1px solid #ced4da";
    });

    document.getElementById("txt_province").addEventListener("change", function () {

    var adr_province = document.getElementById('txt_province');
    var erro_label_adr1 = document.getElementById('erro_labble_address');

    erro_label_adr1.style.display = "none";
    adr_province.style.border = "1px solid #ced4da";
    });

    document.getElementById("txt_district").addEventListener("change", function () {

    var adr_district = document.getElementById('txt_district');
    var erro_label_adr1 = document.getElementById('erro_labble_address');

    erro_label_adr1.style.display = "none";
    adr_district.style.border = "1px solid #ced4da";
    });
    

    document.getElementById('btn_add_new_address').onclick = function () {

    // var adr_name = document.getElementById('address_name').value;
    // var adr_name_erro = document.getElementById('address_name');

    // var adr_country = document.getElementById('txt_country').value;
    // var adr_country_erro = document.getElementById('txt_country');

    // var adr_province = document.getElementById('txt_province').value;
    // var adr_province_erro = document.getElementById('txt_province');

    // var adr_district = document.getElementById('txt_district').value;
    // var adr_district_erro = document.getElementById('txt_district');

    // if (adr_name == ""){
    //     erro_label_adr1.innerHTML = "<%= lib_translate('Please_enter_address_name')  %>";
    //     erro_label_adr1.style.display = "block";
    //     adr_name_erro.style.border = "1px solid red";
    //     return;
    // } else if(adr_country == "") {
    //     erro_label_adr1.innerHTML = "<%= lib_translate('Please_select_Country')  %>";
    //     erro_label_adr1.style.display = "block";
    //     adr_country_erro.style.border = "1px solid red";
    //     return;
    // } else if (adr_province == ""){
    //     erro_label_adr1.innerHTML = "<%= lib_translate('Please_select_Province/City')  %>";
    //     erro_label_adr1.style.display = "block";
    //     adr_province_erro.style.border = "1px solid red";
    //     return;
    // } else if (adr_district == ""){
    //     erro_label_adr1.innerHTML = "<%= lib_translate('Please_select_District')  %>";
    //     erro_label_adr1.style.display = "block";
    //     adr_district_erro.style.border = "1px solid red";
    //     return;
    // } else {
    //     adr_name_erro.style.border = "1px solid #ced4da";
    //     adr_country_erro.style.border = "1px solid #ced4da";
    //     adr_province_erro.style.border = "1px solid #ced4da";
    //     adr_district_erro.style.border = "1px solid #ced4da";
    //     erro_label_adr1.style.display = "none";
    // }
    document.getElementById("btn_add_new_address").type = "submit";
    document.getElementById("name-btn-address").style.display = "none"; 
    document.getElementById("loading_button_address").style.display = "block";
    }
    // ở đây thêm mới
    function clickEditMediaAddress(address_id, user_id){
      
      if($('#file-upload-address-'+address_id).html().length == 0){

        let action_upload = media_up_add;
          var formmedia_edit_doc = new FormMedia("file-upload-address-" + address_id);
          formmedia_edit_doc.setAction(action_upload + "?address_id="+ address_id);
          formmedia_edit_doc.setIconPath('<%= root_path%>assets/image/');
          formmedia_edit_doc.setTranslate(media_trans);
          formmedia_edit_doc.init();
          formmedia_edit_doc.addEventListener("confirmdel",(data)=>{
            deleteAdddoc(data.id, user_id);
          });
              
            $.ajax({
              type: "GET",
              url: add_user_edit,
              data: { idAddress: address_id },
              dataType: "JSON",
              success: function (response) {
                  formmedia_edit_doc.removeTableItemAll();
                  formmedia_edit_doc.tableAddItems(response.docs);
              }
          });
        }else{

        }

    }
    // ở đây thêm mới
    function deleteAdddoc(doc_id,user_id){
      let action = action_check;
      action += `&did=${doc_id}&uid=${user_id}`;
      let link = document.createElement('a');
      link.setAttribute('data-action',"delete");
      link.setAttribute('href',action);
      link.click();
    }
    const formMediaAddress = new FormMedia("upload_file_address");
    formMediaAddress.setIconPath('<%= root_path%>assets/image/');
    formMediaAddress.setTranslate(media_trans);
    formMediaAddress.init();
    formMediaAddress.addEventListener("confirmdel",(data)=>{
        deleteAdddoc(data.id, data.user.user_id);
    });

    function showModalDeleteAddress(element) {
        let href = element.getAttribute("data-action");
        let name = element.getAttribute("data-name");
        $("#address-confirm").find('#button_delete').attr('href',href);
        $("#address-confirm").find('#modal-mesasge-delete-name').text(name);
        // show modal
        $("#address-confirm").modal('show');

    }
    function clickDeleteAddress(id,name,user_id){
      let href = lick_click_del;
      href += `?id=${id}&uid=${user_id}`;

      let html = `confirm_del_add  <span style="font-weight: bold; color: red">${name}</span>?`
      openConfirmDialog(html,(result )=>{
        if(result){
          doClick(href,'delete')
        }
      });

    }
