tinymce.init({
    selector: '#scontent',
    content_style: "p {margin: 0}",
    elementpath: false,
    paste_as_text: false,
    visual: true,
    language:tiny_lang,
    setup : function(ed) {
        ed.on('init', function (ed) {
            ed.target.editorCommands.execCommand("fontName", false, "Times New Roman");
        });
    },
    fontsize_formats: "8pt 10pt 12pt 13pt 14pt 18pt 20pt 22pt 24pt 36pt",
    table_default_attributes: {
        border: '0'
    },
    plugins: [
        'advlist', 'lists', 'preview', 'table', 'token'
    ],
    content_css: 'writer',
    toolbar1:'fontselect fontsizeselect| lineheight | bullist numlist | table | preview',
    toolbar2:'undo redo | bold italic underline strikethrough | forecolor backcolor removeformat| alignleft  aligncenter  alignright  alignjustify indent outdent | token',
    height : "710",
    default_tokens:default_tokens
  });

document.getElementById("temp-contract-form").addEventListener('submit',(e)=>{
    e.preventDefault();
    var content = tinymce.get('scontent').getContent();
    $('#scontent').val(content);
    document.getElementById("temp-contract-form").submit();
})

function clickEditTmp(temp_id,temp_name) {
    //  load data
    let remoteForm = $('#temp-edit-form');
    remoteForm.find('#temp_id_form').val(temp_id);
    remoteForm.find('#temp_name_form').val(temp_name);
    remoteForm.find('#copy').val(false);
    remoteForm.submit();

    // loadding effect
    $('#loading-screen').show();
    $('.form-button').toggleClass("disabled",true);
}

function clickCopy(temp_id){
    let remoteForm = $('#temp-edit-form');
    remoteForm.find('#temp_id_form').val(temp_id);
    remoteForm.find('#copy').val(true);
    remoteForm.submit();
}

//   Remote callback
function loadTempdata(temp) {
    let form_edit = $("#temp-contract-form");
    form_edit.find('#temp_id').val(temp.id);
    form_edit.find('#temp_name').val(temp.name);
    // loadding effect
    $('#loading-screen').hide();
    $('.form-button').toggleClass("disabled",false);
    let scontent = "";
    if(temp){
      scontent = temp.scontent;
    }
    tinymce.get('scontent').setContent(scontent);
    $('#collapse-editer').collapse('show');
    $("#template-name").html(temp.name);
}

function doCopy(temp){
    if (temp == null){
        copyToClipboard("");
        return;
    }
    let scontent = temp.scontent;
    tinymce.get('scontent').setContent(scontent);
    let data = tinymce.get('scontent').getContent({ format: 'text' });
    copyToClipboard(data);
}

function copyToClipboard(data) {
    var $temp = $("<input>");
    $("body").append($temp);
    $temp.val(data).select();
    document.execCommand("copy");
    $temp.remove();
    alert("Đã copy!");
}