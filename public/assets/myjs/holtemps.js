$(document).ready(function() {
      $('#holtemp-tbl th').removeClass('sorting sorting_asc sorting_desc');
      $('#holtemp-tbl th').off('click');
});
$(document).on('click', '.btn-edit-holtemp', function(e) {
    e.preventDefault();
    const url   = $(this).attr('href');
    const isNew = url.endsWith('/new');
  
    tinymce.remove();

    $('#holtempModal .modal-content').load(url, function() {

      flatpickr('.flatpickr', { dateFormat: 'd/m/Y', locale: 'vn' });
      $('#holtempModal').modal('show');
      if (isNew) {
        const form = $('#holtempModal').find('form')[0];
        form.reset();
        $('#holtemp_status_ACTIVE').prop('checked', true);
      }
  
      tinymce.init({
        selector: '#holtemp_content',
        height: 300,
        menubar: false,
        plugins: 'link image code lists table',
        toolbar: 'undo redo | formatselect | bold italic underline | alignleft aligncenter alignright | bullist numlist | table | link image | code',
        setup: function(editor) {
          if (isNew) {
            editor.on('init', function() {
              editor.setContent('');
            });
          }
        }
      });
    });
});
$(document).on('click', '.btn-preview-content', function () {
    const html = $(this).data('content');
    $('#previewContent').html(html);
    $('#previewContentModal').modal('show');
});
  
  