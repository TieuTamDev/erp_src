// Mở modal và nạp form
$(document).on('click', '.btn-edit-holtype', function (e) {
  e.preventDefault();
  const url = $(this).attr('href');

  $('#holtypeModal .modal-content').load(url, function () {
    $('#holtypeModal').modal('show');

    // Nếu là “Thêm mới” thì reset mặc định
    if (url.match(/\/new$/)) {
      const $form = $('#holtypeModal').find('form');
      $form[0].reset();
      $('#holtype_status_ACTIVE').prop('checked', true);
    }

    /** ----------------------------------------------------------------
     *  GẮN VALIDATION  – dùng delegation để luôn bắt được form mới load
     * ---------------------------------------------------------------- */
    $(document)
      .off('submit', '#holtype_form')          // tránh gắn trùng nhiều lần
      .on('submit', '#holtype_form', function (e) {
        let errors = [];

        const name = $('#holtype_name').val().trim();
        if (!name) errors.push('Tên loại phép không được để trống.');

        if (errors.length) {
          e.preventDefault();
          e.stopImmediatePropagation();

          alert(errors.join('\n'));

          $(this)
            .find('[type="submit"][disabled]')
            .prop('disabled', false)
            .removeAttr('data-disable-with');
        }
      });

    /** ----------------------------------------------------------------
     *  GIỚI HẠN KÝ TỰ – dùng jQuery xử lý khi nhập
     * ---------------------------------------------------------------- */
    $('#holtype_name').on('input', function () {
      if ($(this).val().length > 50) {
        $(this).val($(this).val().substring(0, 50));
      }
    });

    $('#holtype_note').on('input', function () {
      if ($(this).val().length > 255) {
        $(this).val($(this).val().substring(0, 255));
      }
    });
  });
});
