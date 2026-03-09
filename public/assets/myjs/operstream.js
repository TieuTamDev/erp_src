$(document).ready(function() {
    $('#close_form').on('click', function() {
        $('#valid_to_error').hide();
        $('#update_operstream').prop('disabled', false);
    });
    // Set default value for organization select box
    $('#organization_id').html('<option value="" disabled selected>Chọn Organization</option>');
    
    // Set default value for stream select box
    $('#stream_id').html('<option value="" disabled selected>Chọn Stream</option>');
    $('#add_operstream').hide();
    $("#function_id").val(currrent_function_id).trigger("change");
    //  check unique
    $('#organization_id, #stream_id, #valid_to').on('change', function() {
        var function_id = $('#function_id').val();
        var organization_id = $('#organization_id').val();
        var stream_id = $('#stream_id').val();
        var valid_to = $('#valid_to').val();
        if (function_id && organization_id && stream_id && valid_to) {
            $.ajax({
            url: check_operstream_exists_path,
            method: 'POST',
            data: {
                function_id: function_id,
                organization_id: organization_id,
                stream_id: stream_id,
                valid_to: valid_to
            },
            success: function(response) {
                if (response.exists) {
                $("#error-modal-operstream").modal('show');
                $('#add_operstream').hide();
                } else {
                $('#add_operstream').show();
                }
            }
            });
        } else {
            $('#add_operstream').hide();
        }
     });


    // $('#form_operstream').submit(function(e) {
    //     e.preventDefault();
    //     var function_id = $('#function_id').val();
    //     var organization_id = $('#organization_id').val();
    //     var stream_id = $('#stream_id').val();
    //     var valid_to = $('#valid_to').val();
    //     $("#loading_operstream").css("display", "flex");
    //     $.ajax({
    //         url: check_operstream_exists_path,
    //         method: 'POST',
    //         data: {
    //             function_id: function_id,
    //             organization_id: organization_id,
    //             stream_id: stream_id,
    //             valid_to: valid_to
    //         },
    //         success: function(response) {
    //             if (response.exists) {
    //                 $('#add_operstream').hide();
    //             } else {
    //                 $('#add_operstream').trigger('change');
    //                 $('#add_operstream').show();
    //                 $('#form_operstream').unbind('submit').submit();
    //             }
    //         }
    //     });
    // });
    // Store the original values when the form is loaded

    $('#function_id_update, #organization_id_update, #stream_id_update, #valid_to_update').on('change', function() {
        var function_id = $('#function_id_update').val();
        var organization_id = $('#organization_id_update').val();
        var stream_id = $('#stream_id_update').val();
        var valid_to = $('#valid_to_update').val();
        var valid_to_error = $('#valid_to_error');
        valid_to_error.hide();
        
        // Compare with the original values
        if ((function_id === originalValues.function_id) &&(organization_id === originalValues.organization_id) && (stream_id === originalValues.stream_id) && (valid_to === originalValues.valid_to)) {
            // If the values are the same, allow saving and hide the error message
            $('#update_operstream').prop('disabled', false);
            valid_to_error.hide();
        } else {
            // Otherwise, make an AJAX call to check if the record exists
            $.ajax({
                url: check_operstream_exists_path,
                method: 'POST',
                data: {
                    function_id: function_id,
                    organization_id: organization_id,
                    stream_id: stream_id,
                    valid_to: valid_to
                },
                success: function(response) {
                    if (response.exists) {
                        $('#update_operstream').prop('disabled', true);
                        valid_to_error.show();
                    } else {
                        $('#update_operstream').prop('disabled', false);
                        valid_to_error.hide();
                    }
                }
            });
        }
    });

    // $('#form_operstream_update').submit(function(e) {
    //     e.preventDefault();
    //     var function_id = $('#function_id_update').val();
    //     var organization_id = $('#organization_id_update').val();
    //     var stream_id = $('#stream_id_update').val();
    //     var valid_to = $('#valid_to_update').val();
    //     $("#loading_operstream").css("display", "flex");
    //     $.ajax({
    //         url: check_operstream_exists_path,
    //         method: 'POST',
    //         data: {
    //             function_id: function_id,
    //             organization_id: organization_id,
    //             stream_id: stream_id,
    //             valid_to: valid_to
    //         },
    //         success: function(response) {
    //             if (response.exists) {
    //                 $('#update_operstream').hide();
    //             } else {
    //                 $('#update_operstream').trigger('change');
    //                 $('#update_operstream').show();
    //                 $('#form_operstream_update').unbind('submit').submit();
    //             }
    //         }
    //     });
    // });

});

// get data
$(document).on('change', '#function_id', function() {
$("#loading_operstream").css("display", "flex");        

var function_id = $(this).val();
    if (function_id == "") {
        $('#organization_id').children().hide();
        $('#stream_id').children().hide();
        $('#organization_id').html('<option value="" disabled selected>Chọn Organization</option>');
        $('#stream_id').html('<option value="" disabled selected>Chọn Stream</option>');
    } else{
        $('#add_operstream').hide();

        $('#organization_id').empty();
        $.ajax({
            url: organizations_path,
            data: { function_id: function_id },
            dataType: 'json',
            success: function(data) {
            $('#organization_id').html('<option value="" disabled selected>Chọn Organization</option>');
            $.each(data, function(key, value) {
                $('#organization_id').append($('<option>', {
                value: value.id,
                text: value.name
                }));
            });
            }
        });
        $('#stream_id').empty();
        $.ajax({
            url: streams_path,
            data: { function_id: function_id },
            dataType: 'json',
            success: function(data) {
            $('#stream_id').html('<option value="" disabled selected>Chọn Stream</option>');
            $.each(data, function(key, value) {
                $('#stream_id').append($('<option>', {
                    value: value.id,
                    text: value.name
                }));
            });
            }
        });

    }
   
    $('#form_submit_oper_list').attr('action', `${operstream_get_operlist_path}?function_id=${function_id}`);
    $("#form_submit_oper_list").submit(); 
    
});

function update_operstream(operstream_id,function_id,organization_id,stream_id,valid_to){
    $("#loading_operstream").css("display", "flex");        
    $('#form_submit_oper_list').attr('action', `${operstream_get_operlist_path}?operstream_id=${operstream_id}`);
    $("#form_submit_oper_list").submit(); 
    originalValues = {
        function_id: function_id,
        organization_id: organization_id,
        stream_id: stream_id,
        valid_to: valid_to
    };
}

function calculateValidTo() {
    var validFromValue = document.getElementById("valid_from").value;
    
    var validFromParts = validFromValue.split("/"); 
    var validFromDate = new Date(validFromParts[2] + "-" + validFromParts[1] + "-" + validFromParts[0]);
  
    var validToDate = new Date(validFromDate);
    validToDate.setFullYear(validFromDate.getFullYear() + 50);
  
    var validToInput = document.getElementById("valid_to");
    validToInput.value = validFromDate.getDate().toString().padStart(2, "0")+ "/" + (validFromDate.getMonth() + 1).toString().padStart(2, "0") + "/" + validToDate.getFullYear();
  }
/**
 * Submit remote form
 * @param {string} formId 
 * @param {Element} button 
 */
function clickRefreshOption(button,formId){
let icon = $(button);
icon.toggleClass("fa-spin",true);
icon.css("pointer-events","none");
icon.css("animation-duration","0.9s");
icon.css("opacity",0.7);

$('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr('content'));
$("#"+formId).submit();
}

/**
 * Get data from remote form submit
 * @param {Array} datas_function 
 */
function reloadFunction(datas_function){
    let button = $("#functions-reload-btn");
    button.toggleClass("fa-spin",false);
    button.css({"pointer-events":"","opacity":'',"animation-duration":"0.9s"});
    if (datas_function.length > 0){
      let option = $("#function_id");
      option.find("option").remove();
      $('#function_id').html('<option value="" disabled selected>Chọn Function</option>');
      datas_function.forEach(item=>{
        option.append(`<option value="${item.id}">${item.sname}</option>`);
      })
    }
  }
  /**
 * Get data from remote form submit
 * @param {Array} datas_organization 
 */
function reloadOrganization(datas_organization){
    let button = $("#organizations-reload-btn");
    button.toggleClass("fa-spin",false);
    button.css({"pointer-events":"","opacity":'',"animation-duration":"0.9s"});
    if (datas_organization.length > 0){
      let option = $("#organization_id");
      option.find("option").remove();
      $('#organization_id').html('<option value="" disabled selected>Chọn Organization</option>');
      datas_organization.forEach(item=>{
        option.append(`<option value="${item.id}">${item.name}</option>`);
      })
    }
  }
  /**
 * Get data from remote form submit
 * @param {Array} datas_stream 
 */
function reloadStream(datas_stream){
    let button = $("#streams-reload-btn");
    button.toggleClass("fa-spin",false);
    button.css({"pointer-events":"","opacity":'',"animation-duration":"0.9s"});
    if (datas_stream.length > 0){
      let option = $("#stream_id");
      option.find("option").remove();
      $('#stream_id').html('<option value="" disabled selected>Chọn Stream</option>');
      datas_stream.forEach(item=>{
        option.append(`<option value="${item.id}">${item.name}</option>`);
      })
    }
  }
  