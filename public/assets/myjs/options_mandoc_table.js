var arr_show_col = window.localStorage.getItem('list_options_table_mandocs');
if (arr_show_col == null) {localStorage.setItem('list_options_table_mandocs', ['TIEPNHAN', 'XULY', 'DEBIET', 'PHOIHOPXL'])}
arr_show_col = window.localStorage.getItem('list_options_table_mandocs');
if (Array.isArray(arr_show_col.split(","))) {
    $('input[name="select_view_schedule"]').prop('disabled', false);
    $('input[name="select_view_schedule"]').prop('checked', false);
    $(`[data-show="TIEPNHAN"]`).addClass("hide-responsive-mobile");
    $(`[data-show="XULY"]`).addClass("hide-responsive-mobile");
    $(`[data-show="DEBIET"]`).addClass("hide-responsive-mobile");
    $(`[data-show="PHOIHOPXL"]`).addClass("hide-responsive-mobile");
    arr_show_col.split(",").forEach(item => {
        $(`input[id="${item}"]`).prop("checked", true);
        $(`[data-show="${item}"]`).removeClass("hide-responsive-mobile");
    });
}

$("a#onclick_customs_table").on('click', function() {
    setTimeout(() => { 
        $('.popover.bs-popover-auto .popover-body').html(`
        <ul class="list-group">
            <li class="list-group-item">
                <div class="form-check m-0">
                    <input class="form-check-input" name="select_view_schedule" id="TIEPNHAN" type="checkbox" value="TIEPNHAN" />
                    <label class="form-check-label m-0" for="TIEPNHAN">Tiếp nhận/Soạn thảo</label>
                </div>
            </li>
            <li class="list-group-item">
                <div class="form-check m-0">
                    <input class="form-check-input" name="select_view_schedule" id="XULY" type="checkbox" value="XULY" />
                    <label class="form-check-label m-0" for="XULY">Xử lý</label>
                </div>
            </li>
            <li class="list-group-item">
                <div class="form-check m-0">
                    <input class="form-check-input" name="select_view_schedule" id="DEBIET" type="checkbox" value="DEBIET" />
                    <label class="form-check-label m-0" for="DEBIET">Để biết</label>
                </div>
            </li>
            <li class="list-group-item">
                <div class="form-check m-0">
                    <input class="form-check-input" name="select_view_schedule" id="PHOIHOPXL" type="checkbox" value="PHOIHOPXL" />
                    <label class="form-check-label m-0" for="PHOIHOPXL">Phối hợp</label>
                </div>
            </li>
        </ul>
        `);

        $(document).ready(function () {
            var maxAllowed = 4;
            var arr_show_col = window.localStorage.getItem('list_options_table_mandocs');
            if (arr_show_col == null) {localStorage.setItem('list_options_table_mandocs', ['TIEPNHAN', 'XULY', 'DEBIET', 'PHOIHOPXL'])}
            arr_show_col = window.localStorage.getItem('list_options_table_mandocs');
            if (Array.isArray(arr_show_col.split(","))) {
                $('input[name="select_view_schedule"]').prop('disabled', false);
                $('input[name="select_view_schedule"]').prop('checked', false);
                $(`[data-show="TIEPNHAN"]`).addClass("hide-responsive-mobile");
                $(`[data-show="XULY"]`).addClass("hide-responsive-mobile");
                $(`[data-show="DEBIET"]`).addClass("hide-responsive-mobile");
                $(`[data-show="PHOIHOPXL"]`).addClass("hide-responsive-mobile");
                arr_show_col.split(",").forEach(item => {
                    $(`input[id="${item}"]`).prop("checked", true);
                    $(`[data-show="${item}"]`).removeClass("hide-responsive-mobile");
                });
            }
            var checkedInputs = $('input[name="select_view_schedule"]:checked');
            if (checkedInputs.length >= maxAllowed) {
                $('input[name="select_view_schedule"]:not(:checked)').prop('disabled', true);
            } else {
                $('input[name="select_view_schedule"]:not(:checked)').prop('disabled', false);
            }

            $('input[name="select_view_schedule"]').change(function () {
              var checkedInputsChecked = $('input[name="select_view_schedule"]:checked');
              if ($(this).is(':checked')) {
                $(`[data-show="${$(this).val()}"]`).removeClass("hide-responsive-mobile");
              } else {
                $(`[data-show="${$(this).val()}"]`).addClass("hide-responsive-mobile");
              }
              window.localStorage.removeItem('list_options_table_mandocs')
              var arrChecked = [];
              if (checkedInputsChecked.length > 0) {
                    checkedInputsChecked.each(function() {
                        arrChecked.push($(this).val());
                    });
                }
                localStorage.setItem('list_options_table_mandocs', arrChecked)

              if (checkedInputsChecked.length >= maxAllowed) {
                $('input[name="select_view_schedule"]:not(:checked)').prop('disabled', true);
              } else {
                $('input[name="select_view_schedule"]:not(:checked)').prop('disabled', false);
              }
            });
          });
    }, 50);

});