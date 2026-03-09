function updateSnoticeIsread(id, user_id){
    console.log(id);
    console.log(user_id);
    $('#form_update_isread_snotice #snotice_id').val(id);
    $('#form_update_isread_snotice #user_id').val(user_id);
    if (confirm('Xác nhận đọc thông báo')){
        $('#form_update_isread_snotice').submit();
	}
}

