tinymce.init({
    selector: '#contents',
    plugins: 'lists advlist anchor autolink autosave autoresize charmap code codesample directionality emoticons fullscreen help image importcss insertdatetime link lists media nonbreaking pagebreak preview quickbars save searchreplace table template visualblocks visualchars wordcount',
    toolbar: 'blocks fontfamily fontsize align lineheight bold italic underline forecolor checklist numlist bullist mergetags spellcheckdialog a11ycheck typography indent outdent undo redo',

    // Cấu hình thêm các tuỳ chọn khác của TinyMCE
});
$('.modal').on('show.bs.modal', function () {
    $(this).find("#cls_bmtu_form_add_title").text(title_create);
	$('#id').val('');
	$('#app').val('');
	$('#meta').val('');
    var editor = tinymce.get('contents');
    editor.setContent('');
	originalValues = {
        app: $('#app').val()
    };
	$("#valid_scode").hide();
    $("#app").css('box-shadow', 'none');
	$(".tox-statusbar__branding").hide();
});

$('a[data-update]').click(function() {   
	var data = JSON.parse(new TextDecoder("utf-8").decode(Uint8Array.from(atob($(this).data('update')), c => c.charCodeAt(0))));
	$('#cls_bmtu_form_add_title').text(title_update);
	$('#id').val(data.id);
	$('#app').val(data.app);
	$('#meta').val(data.meta);
	$('#contents').val(data.contents);
    var editor = tinymce.get('contents');
    editor.setContent(data.contents);
	originalValues = {
        app: $('#app').val()
    };
	$("#valid_scode").hide();
    $("#app").css('box-shadow', 'none');
	$("#btn_save").prop('disabled', false);
	$(".tox-statusbar__branding").hide();
});

$('#btn_save').on('click', function () {
	var data_app = $('#app').val();
	if (data_app != "") {
		$('#form_add_documents').submit();
	} else{
		$("#app").css('box-shadow', '0 0 5px red');
		$("#valid_scode").show();
		$("#valid_scode").html("Không được để trống");
	}
})

function openViewContents(content) {
	$("#view_content").html(content);
}
$('#app').on('input', function() {
	// kiểm tra originalValues
	if (originalValues === "") {
	  scodeCurrent = "";
	} else {
	  scodeCurrent = originalValues.app;
	}
  
	var scodeSubject = $(this).val().trim();

	// Chuyển đổi toàn bộ giá trị thành chữ hoa
	scodeSubject = scodeSubject.toUpperCase();

	$("#check_app_input").val(scodeSubject);
  
	// kiểm tra điều kiện của cả scodeSubject và scodeCurrent
	if (scodeSubject === "" && scodeCurrent === "") {
	  // nếu cả 2 giá trị đều rỗng ẩn button thêm
	  $("#valid_scode").hide();
	  $("#app").css('box-shadow', 'none');
	  $("#btn_save").prop('disabled', true);
	} else if (scodeCurrent == scodeSubject) {
	  // nếu giá trị nhập vào bằng giá trị ban đầu hiển thị nút sửa(dành cho update mmodule)
	  $("#valid_scode").hide();
	  $("#app").css('box-shadow', 'none');
	  $("#btn_save").prop('disabled', false);
	} else {
	  // nếu các điều kiện trên không thỏa mãn hiển thị nút và cho phép submit
	  $("#btn_save").prop('disabled', false);
	  $("#check_app").submit();
	}
});
  
function toUpperCaseScode() {
	document.getElementById("app").value = document.getElementById("app").value.toUpperCase();
}

