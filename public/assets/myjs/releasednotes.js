tinymce.init({
    selector: '#contents',
    plugins: 'lists advlist anchor autolink autosave autoresize charmap code codesample directionality emoticons fullscreen help image importcss insertdatetime link lists media nonbreaking pagebreak preview quickbars save searchreplace table template visualblocks visualchars wordcount',
    toolbar: 'blocks fontfamily fontsize align lineheight bold italic underline forecolor checklist numlist bullist mergetags spellcheckdialog a11ycheck typography indent outdent undo redo',

    // Cấu hình thêm các tuỳ chọn khác của TinyMCE
});

flatpickr(".date_post", {
	dateFormat: "d/m/Y H:i",
	enableTime: true,
	defaultDate: time_now,
	time_24hr: true,
	locale: {
	firstDayOfWeek: 1, // bắt đầu từ thứ 2
	weekdays: {
		shorthand: ["CN", "T2", "T3", "T4", "T5", "T6", "T7"],
		longhand: [
		"Chủ nhật",
		"Thứ hai",
		"Thứ ba",
		"Thứ tư",
		"Thứ năm",
		"Thứ sáu",
		"Thứ bảy",
		],
	},
	months: {
		shorthand: [
		"Thg 1",
		"Thg 2",
		"Thg 3",
		"Thg 4",
		"Thg 5",
		"Thg 6",
		"Thg 7",
		"Thg 8",
		"Thg 9",
		"Thg 10",
		"Thg 11",
		"Thg 12",
		],
		longhand: [
		"Tháng 1",
		"Tháng 2",
		"Tháng 3",
		"Tháng 4",
		"Tháng 5",
		"Tháng 6",
		"Tháng 7",
		"Tháng 8",
		"Tháng 9",
		"Tháng 10",
		"Tháng 11",
		"Tháng 12",
		],
	},
	},
});

$('.modal').on('show.bs.modal', function () {
    $(this).find("#cls_bmtu_form_add_title").text(title_create);
	$('#id').val('');
	$('#name').val('');
	$('#authors').val('');
	$('#dtrelease').val(time_now);
	$('#datetime').val(time_now);
    var editor = tinymce.get('contents');
    editor.setContent('');
});

$('a[data-update]').click(function() {   
	var data = JSON.parse(new TextDecoder("utf-8").decode(Uint8Array.from(atob($(this).data('update')), c => c.charCodeAt(0))));
	$('#cls_bmtu_form_add_title').text(title_update);
	$('#id').val(data.id);
	$('#name').val(data.name);
	var athurs_arr = data.authors.split(' - ');
	$("#authors").val(athurs_arr).trigger("change");
	flatpickr("#dtrelease", {
		dateFormat: "d/m/Y H:i",
		enableTime: true,
		time_24hr: true,
		defaultDate: data.dtrelease,//set selected date
	});
	$('#contents').val(data.contents);
    var editor = tinymce.get('contents');
    editor.setContent(data.contents);
});

$('#btn_save').on('click', function () {
	$('#authors_input').val($('#authors').val().toString().replaceAll(",", " - "));
	$( document ).ready(function() {
		$('#form_add_releasednotes').submit();
	});
})