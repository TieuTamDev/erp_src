// Start flatpick datepicker
let options = {
    locale: datepick_local,
    dateFormat: "d/m/Y",
    onChange: function(selectedDates, dateStr, instance) {
        onDateChange(dateStr,instance.element);
    }
}

document.addEventListener("DOMContentLoaded", () => {
    // SEARCH
    let date = new Date();
    date.setFullYear(date.getFullYear() - 3)
    // startdate
    let dt_from = flatpickr('[name="dt_from"]', {...options,...{
        maxDate: new Date(),
        defaultDate: date
    }});
    // end date
    let dt_to = flatpickr('[name="dt_to"]', {...options,...{
        maxDate: new Date(),
        defaultDate: "today"
    }});

    let date_expire = flatpickr('#date_expire_picker', {
        dateFormat: "d/m/Y",
        maxDate: new Date(),
        defaultDate: "today",
        onChange: function(selectedDates, dateStr, instance) {
            let date = selectedDates[0];
            let id = instance.element.id;
            $(`[data-display="${id}"]`).html(dateStr);
            $('#form-un-effect-mandoc #date_expire').val(moment(date).format('YYYY-MM-DD'));
        }
    });
    let today = new Date();
    $('#form-un-effect-mandoc #date_expire').val(`${today.getFullYear()}-${today.getMonth()}-${today.getDay()}`);

    $('[data-display="dt_from"]').html(dt_from.element.value);
    $('[data-display="dt_to"]').html(dt_to.element.value);
    $('[data-display="date_expire_picker"]').html(date_expire.element.value);
    $('#filter-efect').on('change',(e)=>{
        let checked = e.target.checked;
        let label = $('[for="filter-efect"]');
        let labelText = checked ? js_translate('Still_validated') : js_translate('Expire');
        label.html(labelText);
    })

    // SELECT MANDOC
    $('#form-un-effect-mandoc [name="dchild"]').select2({
        placeholder: 'Chọn văn bản...',
        theme: 'bootstrap-5',
        dropdownParent: $("#modal-un-mandoc"),
        translations:{
            searching: ()=>{
                return $(`<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> <span>${js_translate("Loading_more")}<span>`);
            }
        },
        ajax:{
            url: search_ajax_path,
            delay: 250,
            dataType: 'json',
            method:'get',
            data: function (params) {
                var query = {
                  search: params.term,
                  page: params.page || 1,
                  item_page:5
                }
                return query;
            },
        },
        templateResult: renderOptions,
        templateSelection: getSelectValue
    });

    $('[name="select_dchild"]').on('change',(e)=>{
        let checked = $(e.currentTarget).prop('checked');
        $('#dchild_wrap').collapse(checked ? 'show' : 'hide');
        if(!checked){
            $('#dchild-select').val(null).trigger('change');
        }
    })

    // load data for first time
    clickSearch();
});



/**
 * Call when select date change value
 * 
 * @param {string} dateStr 
 * @param {Element} element 
 */
function onDateChange(dateStr,element){
    let id = element.id;
    $(`[data-display="${id}"]`).html(dateStr);

    // change min
    if(id == "dt_from"){
        changePickerOption("dt_to","minDate",dateStr);
    }else{
        changePickerOption("dt_from","maxDate",dateStr);
    }
    
}

function changePickerOption(id,option,value){
    const picker = document.querySelector("#"+id)._flatpickr;
    picker.set(option, value);
}

function clickSubmitUnEffect(){
    $("#form-un-effect-mandoc").submit();
    submitLoadding('#btn-submit-un-effect',true);
}

function clickSearch(){
    $("#form-search-mandoc").submit();
    submitLoadding('#btn-submit-search',true);
}

/**
 * Load result from search controller
 * @param {[]} result 
 */
function loadSearchResult(datas){
    submitLoadding('#btn-submit-search',false);
    // pagin render
    $("#form-search-mandoc #pagin-wrap").html(datas.pagin_items);
    initPageButton();
    // item render
    let tableBody = $("#table_mandoc_search .list");
    let start_index = datas.start_index;
    tableBody.html("");
    let trans_view = js_translate("View_document");
    let trans_download = js_translate("Download");
    let trans_in_effect = js_translate("Still_validated");
    let trans_expire = js_translate("Expire");
    let trans_ngay_ban_hanh = js_translate("Ngay_ban_hanh");
    let trans_effective_date = js_translate("Effective_date");
    let trans_replace = js_translate('Is_replaced_by');
    datas.results.forEach(mandoc => {
        let showFile = mandoc.file_path != null || mandoc.file_path == '';
        let status_class = mandoc.on_work ? "badge bg-success" : "badge badge-soft-danger";
        let status_text = mandoc.on_work ? trans_in_effect : trans_expire;
        let status_attr = "";
        let status_btn_icon = "";
        let status_event = `onclick="clickStatus(${mandoc.id})"`;
        if(datas.can_edit && mandoc.on_work){
            status_class += " edit-effect";
            status_attr = 'data-bs-toggle="modal" data-bs-target="#modal-un-mandoc"';
            status_btn_icon = '<span class="far fa-edit"></span>';
        }
        let dchild_msg = '';
        if(mandoc.dchild){
            dchild_msg = `<br><span>${trans_replace}: ${mandoc.dchild}</span>`;
        }
        let status_btn = `<span ${status_event} class="${status_class}" ${status_attr} style="font-size: 0.8em;padding: 7px 12px;">${status_btn_icon} ${status_text}</span>`;
        let imcoming = mandoc.sfrom != null;
        let sno_label = imcoming ? "VB đến số" : "VB đi số";
        let content = imcoming ? mandoc.contents : mandoc.notes
        tableBody.append(`
            <tr id="${mandoc.id}">
                <td style="text-align: center;">${start_index}</td>
                <td>
                    <span>
                        <span class="fas fa-book"></span>
                        <span>${sno_label}: </span>
                        <span style="font-weight: 600;"></span>${mandoc.sno}
                    </span><br>
                    <span>
                        <span class="far fa-calendar-alt"></span>
                        <span>${trans_ngay_ban_hanh}: </span>
                        <span style="font-weight: 600;">${mandoc.received_at}</span>
                    </span> <br>
                    <span>
                        <span class="far fa-calendar-alt"></span>
                        <span>${trans_effective_date}: </span>
                        <span style="font-weight: 600;">${mandoc.effective_date}</span>
                    </span>
                </td>
                <td style="white-space: unset;">
                    ${content}
                </td>
                <td data-mandoc-status="${mandoc.id}" style="text-align: center;vertical-align: middle;">
                    ${status_btn + dchild_msg}
                </td>
                <td style="text-align: center;vertical-align: middle;">
                    ${ showFile ? `
                        <a href="${mandoc.file_path}" target="_blank" rel="noopener noreferrer" >
                            <span class="far fa-eye me-3 preview-mandoc" style="cursor: pointer;" data-id="" data-toggle="tooltip" data-placement="top" title="${trans_view}"></span>
                        </a>
                        <a href="${mandoc.file_path}" download>
                            <span class="fas fa-download download-mandoc" onclick="clickDownload('${mandoc.file_path}')" style="cursor: pointer;" data-toggle="tooltip" title="${trans_download}"></span>
                        </a>` : ''}
                </td>
            </tr>`);
        start_index += 1;
    });
    showLoadding(false);
}

function clickStatus(mandoc_id){
    $('#dchild_wrap').collapse('hide');
    $('#dchild-select').val(null).trigger('change');
    $('#form-un-effect-mandoc').trigger('reset');
    $('#form-un-effect-mandoc #date_expire').val(moment().format('YYYY-MM-DD'));
    $('#form-un-effect-mandoc #valid-msg').html('');
    $('#form-un-effect-mandoc [name="mandoc_id"]').val(mandoc_id);
    let input = $('#form-un-effect-mandoc [name="dchild"]');
    input.val('');
}



function onUnEffectMandoc(result){
    if(result.status){
        let dchild_msg = '';
        if(result.dchild != ''){
            dchild_msg = `<br><span>Thay thế bởi: ${result.dchild}</span>`;
        }
        let html_result = `<span class="badge badge-soft-danger" style="font-size: 0.8em;padding: 7px 12px;">${js_translate("Expire")}</span>`;
        $(`#table_mandoc_search [data-mandoc-status="${result.mandoc_id}"]`).html(html_result + dchild_msg);
        showAlert(result.msg);
    }else{
        $('#form-un-effect-mandoc #valid-msg').html(result.msg);
        submitLoadding('#btn-submit-un-effect',false);
        return;
    }

    submitLoadding('#btn-submit-un-effect',false);
    $("#modal-un-mandoc").modal('hide');
}

function initPageButton(){
    $("#form-search-mandoc [data-page]").removeAttr("href");
    $("#form-search-mandoc [data-limit]").removeAttr("href");
    $("#form-search-mandoc .page-item").css("cursor","pointer");
    $("#form-search-mandoc .page-item").css("user-select","none");
    $("#form-search-mandoc [data-page]").on('click',(e)=>{
        let page = $(e.target).attr("data-page");
        clickPage(page);
    })
    $("#form-search-mandoc [data-limit]").on('click',(e)=>{
        let limit = $(e.target).attr("data-limit");
        clickLimit(limit);
    })
}

function clickPage(page){
    $('#form-search-mandoc [name="page"]').val(page);
    $('#form-search-mandoc').submit();
    showLoadding(true);
}

function clickLimit(limit){
    $('#form-search-mandoc [name="page"]').val(1); // back to page 1
    $('#form-search-mandoc [name="per_page"]').val(limit);
    $('#form-search-mandoc').submit();
    showLoadding(true);
}

//btn-submit-search
function submitLoadding(query,bLoadding){
    let button = $(query);
    if(bLoadding){
        button.attr('disabled','disabled');
        button.find(".submit-text").hide();
        button.find(".submit-loadding").show();
    }else{
        button.removeAttr('disabled');
        button.find(".submit-text").show();
        button.find(".submit-loadding").hide();
    }
}

/**
 * Call when search controller get error
 */
function onSearchError(error){
    console.error(error);
    submitLoadding('#btn-submit-search',false);
}

// SELECT 2 ajax funtion
/**
 * Render select item fom ajax response
 * @param {any} item 
 * @returns 
 */
function renderOptions (response) {
    if (response.loading) {
      return $(`<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> <span>${js_translate("Loading")}<span>`);
    }
    let imcoming = response.sfrom != null;
    let sno_label =  imcoming ? "VB đến số" : "VB đi số";
    let content = imcoming ? response.contents : response.notes;
    var container = $(`
        <div style="font-size:0.9em">
            <span><span class="fas fa-book"></span> ${sno_label}:  ${response.sno}</span><br>
            <span><span class="fa-solid fa-file-lines"></span> Nội dung: ${content}</span>
        </div>
    `);
    return container;
}

function getSelectValue(item) {
    if(item.sno){
        let imcoming = item.sfrom != null;
        let sno_label =  imcoming ? "VB đến số: " : "VB đi số: ";
        return sno_label + item.sno;
    }
    return js_translate('Choose_document');
}