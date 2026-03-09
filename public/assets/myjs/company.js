function updateCompanyWorkHistory(id, name, position, period, leader, comments, status, working_part ){
    $('#open_form_add_up_work_history').addClass('show');
    $("#title_company").html(update_work_history);

    $('#title_company').css({"display": "none"});

    $('#id_cancel_company').css({"display": "block"});
    
    $("#text_field_id_of_company").val(id);
    $("#text_field_name").val(name);
    $("#text_field_position").val(position);
    $("#text_field_period").val(period);
    $("#text_field_leader").val(leader);
    $("#text_field_comments").val(comments);
    $("#text_field_working_part").val(working_part);
    if(status == "ACTIVE"){
      $('#company_status_ACTIVE' ).prop('checked',true);
    }
    else {
      $('#company_status_INACTIVE' ).prop('checked',true);
    };

    document.getElementById("txt_work_history_title").scrollIntoView();
  }
  function delete_loading_company(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
  }

  
  $("#button_add_up_company").click(function() {

    var name = $('#text_field_name').val();
    var err_name = $('#text_field_name');

    var position = $('#text_field_position').val();
    var err_position = $('#text_field_position');

    var period = $('#text_field_period').val();
    var err_period = $('#text_field_period');

    var leader = $('#text_field_leader').val();
    var err_leader = $('#text_field_leader');

    var working_part = $('#text_field_working_part').val();
    var err_working_part = $('#text_field_working_part');

    var comments = $('#text_field_comments').val();
    var err_comments = $('#text_field_comments');

    var err= $('#erro_company');

    if (name == "") {
        err_name.css({"border": "1px solid red"});
        err.css({"display": "block"});
        err.html(err_blank_name_company);
    }else if(position ==""){
        err_name.css({"border": "1px solid var(--falcon-input-border-color)"});
        err_position.css({"border": "1px solid red"});
        err.css({"display": "block"});
        err.html(err_blank_position_com);
    }else if(period==""){
        err_position.css({"border": "1px solid var(--falcon-input-border-color)"});
        err_period.css({"border": "1px solid red"});
        err.css({"display": "block"});
        err.html(err_blank_period);
    }else{
        err_working_part.css({"border": "1px solid var(--falcon-input-border-color)"})
        err.css({"display": "none"});
        $("#spinner-loading").removeClass("d-none");
        $("#form_add_up_company").submit();
    }
  });

  $( "#text_field_name" ).change(function() {
    var name = $('#text_field_name').val();
    var err_name = $('#text_field_name');
    var err= $('#erro_company');

    if (name == "") {
      err_name.css({"border": "1px solid red"});
      err.css({"display": "block"});
      err.html(err_blank_name_company);
    }else{
      err_name.css({"border": "1px solid var(--falcon-input-border-color)"});
      err.css({"display": "none"});
    }
  });

  $( "#text_field_position" ).change(function() {
    var position = $('#text_field_position').val();
    var err_position = $('#text_field_position');
    var err= $('#erro_company');

    if (position == "") {
      err_position.css({"border": "1px solid red"});
      err.css({"display": "block"});
      err.html(err_blank_position_com);
    }else{
      err_position.css({"border": "1px solid var(--falcon-input-border-color)"});
      err.css({"display": "none"});
    }
  });

  $( "#text_field_period" ).change(function() {
    var period = $('#text_field_period').val();
    var err_period = $('#text_field_period');
    var err= $('#erro_company');

    if (period == "") {
      err_period.css({"border": "1px solid red"});
      err.css({"display": "block"});
      err.html(err_blank_period);
    }else{
      err_period.css({"border": "1px solid var(--falcon-input-border-color)"});
      err.css({"display": "none"});
    }
  });


  $("#title_company").html(add_work_history);

  function addWorkHistory() {
    $('#text_field_name').val("");

    $('#text_field_position').val("");

    $("#text_field_id_of_company").val("");

    $('#text_field_period').val("");

    $('#text_field_leader').val("");

    $('#text_field_working_part').val("");

    $('#text_field_comments').val("");

    $('#company_status_ACTIVE' ).prop('checked',true);

    $("#title_company").html(add_work_history);

    $('#title_company').css({"display": "none"});

    $('#id_cancel_company').css({"display": "block"});
  }

  $('#id_cancel_company').click(function(){
    $("#title_company").html(add_work_history);

    $('#title_company').css({"display": "block"});

    $('#id_cancel_company').css({"display": "none"});
  });

  function clickDeleteWorkHistory(id,name,user_id){
    href_company += `?id=${id}&uid=${user_id}`;

    let html = `${mess_del_company} <span style="font-weight: bold; color: red"> ${name} </span>?`
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href_company,'delete')
      }
    });

  }
  function clickCollapseWorkHistory(element){
    document.getElementById('collapse-icon-work-history').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
  }
