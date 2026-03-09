// drag-drop
const grapDrop = new GrapDrop();
let idJobPos = "";
var id_task;

//  grapDrop.updateDropEffect("list-department");
grapDrop.addEventListener('ondrop', (data) => {
    let elements = data.graps;
    let target = data.target;
    let tasksDOM = "";

    let direct = target.getAttribute("data-panel");
    // make items DOM
    elements.forEach(element => {
        let id = element.id;
        let name = element.getAttribute("data-name");

        if (name != null && id != "") {
            tasksDOM += addItemDOM(id,name,direct);
        }
    });

    // only drop from other contanter
    if(elements[0].getAttribute("data-panel") == direct){
        grapDrop.clearSelectItems();
        uncheckAll();
        return;
    }

    // add task: add dom, hide item left
    if (target.id == 'right_panel') {
        elements.forEach(element=>{       
            $('#list_all_task').find('#'+element.id).css('display' , 'none');
            arr_SelectedTasks.push(element.id);
        });
        document.getElementById("list_select_task").innerHTML += tasksDOM;

    // remove selected: remove dom, show item left
    }else{
        elements.forEach(element=>{
            let id = element.id;
            element.remove();
            $('#list_all_task').find('#'+id).css('display' , 'unset');
            for (let j = 0; j < arr_SelectedTasks.length; j++) {
                if (id == arr_SelectedTasks[j]) {
                    arr_SelectedTasks.splice(j,1); 
                }
            }
        });
    }
    uncheckAll();
    grapDrop.clearSelectItems();
});

function clickButtonMove(direct){
   let selectItemsLeft =  $(direct == "left" ? "#list_all_task" : "#list_select_task").find('.custom-control-input:checkbox:checked');
//    move task left to right
   if (direct =="left") {

        for (let i = 0; i < selectItemsLeft.length; i++) {
            let item = selectItemsLeft[i];

            document.getElementById(`${item.value}`).style.display =  "none";
            // add
            document.getElementById("list_select_task").innerHTML += `
            <li class="item list-group-item item-tasks" can-grap="true" data-panel="right" data-hl="true" data-name="${item.name}" id="${item.value}" style="cursor: grab;">
                    <input type="checkbox" onchange="onTaskSelect(this)"  class="custom-control-input" id="${item.name}right" value="${item.value}" name="${item.name}">
                    <label class="form-check-label"  for="${item.name}right">${item.name}</label>
                    <span onclick="removeTaskDOM(this)" class="fa fa-trash text-danger item-trash"></span>
            </li>
            `;
            // push array
            arr_SelectedTasks.push(`${item.value}`);
            uncheckAll();
            grapDrop.clearSelectItems();
        }   
// move task right to left 
   }else{
   let selectItemsRight =  $(direct == "right" ? "#list_select_task" : "#list_select_task").find('.custom-control-input:checkbox:checked');
    for (let i = 0; i < selectItemsRight.length; i++) {
        let item = selectItemsRight[i];
        // remove task
        $('#list_select_task').find('#'+`${item.value}`).remove(); 
        //show task
        $('#list_all_task').find('#'+`${item.value}`).css('display' , 'unset');
        //remove task in array
        for (let j = 0; j < arr_SelectedTasks.length; j++) {
            if (item.value == arr_SelectedTasks[j]) {
                arr_SelectedTasks.splice(j,1); 
            }
        }
        grapDrop.clearSelectItems();
        uncheckAll();
    }
   }
   
}

/**
 * Create item task as string
 * @param {Number} id 
 * @param {String} name 
 */
function addItemDOM(id,name,direct){
    //add task
return `
    <li class="item list-group-item item-tasks" can-grap="true" data-panel="${direct}" data-hl="true" data-name="${name}" id="${id}" >
            <input type="checkbox" onchange="onTaskSelect(this)" class="custom-control-input" id="${id}right" value="${id}" name="${name}">
            <label class="form-check-label"  for="${id}right">${name}</label>
        <span onclick="removeTaskDOM(this)" class="fa fa-trash text-danger item-trash"></span>
    </li>`;
}


function removeTaskDOM(icon){
    let taskDOM = icon.parentElement;
    let id = taskDOM.id;
// remove task in array
    for (let i = 0; i < arr_SelectedTasks.length; i++) {
        if (`${id}` == arr_SelectedTasks[i]) {
            arr_SelectedTasks.splice(i,1); 
            taskDOM.remove();
            $('#list_all_task').find('#'+ id).css('display','unset'); 
            grapDrop.clearSelectItems();
        }
    }
}

//checkbox
/**
 * 
 * @param {HTMLElement} checkbox 
 */
 function onTaskSelect(checkbox){
    let taskDOMCheckbox = checkbox.parentElement;
    let selectItems = grapDrop.getSelectItems();
    if(checkbox.checked){
        // only select with same list contanter
        if(selectItems.length > 0 && selectItems[0].getAttribute('data-panel') != taskDOMCheckbox.getAttribute('data-panel')){
            checkbox.checked = false;
        }else{
            checkbox.checked = true;
            grapDrop.addGrapItem(taskDOMCheckbox);
        }
    }else{
        grapDrop.removeGrapItem(taskDOMCheckbox);
    }
}

function uncheckAll(){
    // unchecked checkbox
    document.querySelectorAll('input[type=checkbox]').forEach(item => {
        item.checked = false;
    })
}

function checkNospacePwd(value) {
    if (value != "  " && value.indexOf("  ") < 0) {
        return true;
    } else {
        return false;
    }
}

function containsSpecialChars(str) {
    const specialChars = /[`!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~]/;
    return specialChars.test(str);
}

function closeFormAddPositionJobs() {
    document.getElementById('modal-form-create-position-job').style.display = "none"
    document.getElementById('txt_id_pj').value = ""
    document.getElementById('txt_name_pj').value = ""
    document.getElementById('txt_scode_pj').value = ""
    document.getElementById('txt_desc_pj').value = ""
    // document.getElementById('txt_department_id_pj').value = ""
    // document.getElementById('txt_create_by_pj').value = ""
}


/**
 * 
 * @param {HTMLElement} element 
 */
 function clickCollapse(element){
    document.getElementById('collapse-icon').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";

}


function getTextToASCII() {
    var value_name = document.getElementById("txt_name_update_pj").value;
    var value_scode = document.getElementById("txt_scode_update_pj");
    if (value_name) {
    var content = removeVietnameseTones(value_name).replace(/ /g, '-');
        if (value_scode) {
            value_scode.value = content.toUpperCase()
        }
    }
}
function removeVietnameseTones(str) {
    str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g,"a"); 
    str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g,"e"); 
    str = str.replace(/ì|í|ị|ỉ|ĩ/g,"i"); 
    str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g,"o"); 
    str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g,"u"); 
    str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g,"y"); 
    str = str.replace(/đ/g,"d");
    str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
    str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
    str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
    str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
    str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
    str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
    str = str.replace(/Đ/g, "D");
    // Some system encode vietnamese combining accent as individual utf-8 characters
    // Một vài bộ encode coi các dấu mũ, dấu chữ như một kí tự riêng biệt nên thêm hai dòng này
    str = str.replace(/\u0300|\u0301|\u0303|\u0309|\u0323/g, ""); // ̀ ́ ̃ ̉ ̣  huyền, sắc, ngã, hỏi, nặng
    str = str.replace(/\u02C6|\u0306|\u031B/g, ""); // ˆ ̆ ̛  Â, Ê, Ă, Ơ, Ư
    // Remove extra spaces
    // Bỏ các khoảng trắng liền nhau
    str = str.replace(/ + /g," ");
    str = str.trim();
    // Remove punctuations
    // Bỏ dấu câu, kí tự đặc biệt
    str = str.replace(/!|@|%|\^|\*|\(|\)|\+|\=|\<|\>|\?|\/|,|\.|\:|\;|\'|\"|\&|\#|\[|\]|~|\$|_|`|-|{|}|\||\\/g," ");
    return str;
}

document.addEventListener('readystatechange', event => { 
    if (event.target.readyState === "interactive") { 
        var user = document.getElementById("tab1");
        if (user) {
          user.checked = "checked"
        }
    }
});

let arr_SelectedTasks = [];
let itemSelect=$('#sel1').children('option'); 
$(document).ready(function() {
    $('#sel1').next().prop('style','width:60% !important');
    if (localStorage.getItem('valueSelect') == "null") {
        if (positionjob_id == "") {
            getValueSel($('#sel1')[0])
        }else{
            $("#sel1").val(positionjob_id);
            $("#sel1").trigger('change');
        }
    }else{
    
        $("#sel1").val(localStorage.getItem('valueSelect'));
        $("#sel1").trigger('change');
        $("#loading_positionjob").css("display", "flex"); 
        $('#list_all_task').children('li').css('display','unset'); 
    }
});

/**
 * 
 * @param {HTMLElement} element 
 */
function getValueSel(element) {
    idJobPos = element.value
    arr_SelectedTasks = [];
    //reset when data change
    document.getElementById('list_select_task').innerHTML = "";
    $("#loading_positionjob").css("display", "flex");  
    if (element.value != "") {
        // show all task before load job's task
        $('#list_all_task').children('li').css('display','unset'); 
        localStorage.setItem('valueSelect', element.value);
        $.ajax({
            type: "GET",
            url: update_responsible_path,
            data: { idJobPos: idJobPos },
            dataType: "JSON",
            success: function (response) {
                document.getElementById('name_assign').innerHTML = response.info_job.name;

                // openform
                document.getElementById('form-tab1').style.display = "block"
                document.getElementById('update-positionjob').style.display = "block"
                var btn_delete = document.getElementById('btn-delete-positionjob') 
                if (btn_delete) {
                    btn_delete.value= response.info_job.id
                    btn_delete.name= response.info_job.name
                    btn_delete.style.display="block"
                }
                // document.getElementById('href-del').style.display = "block"
                //SET value to update form
                document.getElementById('txt_id_update_pj').value = response.info_job.id;
                document.getElementById('txt_name_update_pj').value = response.info_job.name;
                document.getElementById('txt_scode_update_pj').value = response.info_job.scode;
                document.getElementById('txt_desc_update_pj').value = response.info_job.note;
                $('#txt_department_id_update_pj').val(response.info_job.department_id);
                $('#txt_department_id_update_pj').trigger('change');

                $('#txt_create_by_update_pj').val(response.info_job.created_by);
                $('#txt_create_by_update_pj').trigger('change');

                document.getElementById("txt_name_update_pj").addEventListener("keyup", function() {} );

                if( response.info_job.status == "ACTIVE"){
                    document.getElementById("sel_status_update_pjA").checked = true;
                    }
                    else {
                    document.getElementById("sel_status_update_pjI").checked = true;
                }

                //show responsible
                document.getElementById('responsible-main').style.display = "block"
                for (let i = 0; i < response.arr_tasks.length; i++) {
                    // load data from controller
                    document.getElementById('list_select_task').innerHTML +=
                    `<li class="listtasks list-group-item item-tasks" can-grap="true" data-panel="right" data-hl="true" data-name="${response.arr_tasks[i].name}" id="${response.arr_tasks[i].id}">
                        <input type="checkbox" onchange="onTaskSelect(this)" class="custom-control-input" id="${response.arr_tasks[i].id}right" value="${response.arr_tasks[i].id}" name="${response.arr_tasks[i].name}"> 
                        <label class="form-check-label" for="${response.arr_tasks[i].id}right" > ${response.arr_tasks[i].name}</label>
                        <span onclick="removeTaskDOM(this)" class="fa fa-trash text-danger item-trash"></span>
                    </li>`;

                    // hidden task duplication
                    $('#list_all_task').find('#'+ response.arr_tasks[i].id).css('display','none'); 
                    arr_SelectedTasks.push(`${response.arr_tasks[i].id}`);
                }
                $("#loading_positionjob").css("display", "none"); 
            }
            
        });
    } else {
        // reset when select null
        document.getElementById('responsible-main').style.display = "none";
        document.getElementById('form-tab1').style.display = "none";
        $('#list_select_task').children('li').remove(); 
        localStorage.setItem('valueSelect', "null");
        $("#loading_positionjob").css("display", "none"); 

    }
}

function openFormAddPositionJobs() {
    localStorage.setItem('valueSelect', "null");

    // open form
    document.getElementById('form-tab1').style.display = "block"
    document.getElementById('update-positionjob').style.display = "block"
    document.getElementById('responsible-main').style.display = "none"
    // document.getElementById('btn-delete-positionjob').style.display="none"

    // document.getElementById('href-del').style.display = "none"
    $('#btn-delete-positionjob').css('display','none'); 
    $('#sel1').find('option[value=""]').remove();
    $('#sel1').prepend(`<option id="select" name="" value="">${Select_Position_Job}</option>`)
    $('#sel1').val('');
    $('select option[value=""]').attr("selected",true);
    $('#list_select_task').children('li').remove(); 
    $('#list_all_task').children('li').css('display','unset'); 
    document.getElementById('work').classList.add("show");
    
    // set data in form add position job
    document.getElementById('txt_id_update_pj').value = ""
    document.getElementById('txt_name_update_pj').value = ""
    document.getElementById("txt_name_update_pj").addEventListener("keyup", function() {getTextToASCII()} );
    document.getElementById('txt_scode_update_pj').value = ""
    document.getElementById('txt_desc_update_pj').value = ""
    document.getElementById('txt_department_id_update_pj').value = ""
    $("#txt_department_id_update_pj").prop("selectedIndex", 0).val();
    $('#txt_department_id_update_pj').trigger('change');
    $('#txt_create_by_update_pj').trigger('change');
    $("#txt_create_by_update_pj").prop("selectedIndex", 0).val();

    document.getElementById('sel_status_update_pjA').checked=true;
    
}
function openFormUpdatePositionJobs(id, name, scode, note, department_id, created_by, status) {
    document.getElementById('update-positionjob').style.display = "block"
    document.getElementById('txt_id_update_pj').value = id
    document.getElementById('txt_name_update_pj').value = name
    document.getElementById('txt_scode_update_pj').value = scode
    document.getElementById('txt_desc_update_pj').value = note
    document.getElementById('txt_department_id_update_pj').value = department_id
    document.getElementById('txt_create_by_update_pj').value = created_by
    document.getElementById("txt_name_update_pj").addEventListener("keyup", function() {} );
    if( status == "ACTIVE"){
        document.getElementById("sel_status_update_pjA").checked = true;
        }
        else {
        document.getElementById("sel_status_update_pjI").checked = true;
    }
        
}
$( "#btn_deletes_pjs" ).click(function() {
    document.getElementById('btn_deletes_pjs').style.display='none';
    document.getElementById('loading_button_pjs').style.display='block';
});
$( "#btn-deletes-positionjob" ).click(function() {
    document.getElementById('btn-deletes-positionjob').style.display='none';
    document.getElementById('loading_button_deletes_position_jobs').style.display='block';
    
});

/**
 * 
 * @param {HTMLElement} element 
 */
function delete_item(id_item){

    href_positionjob += `?id=${id_item.value}}`;

    let html = `${mess_del_positionjob}  <span style="font-weight: bold; color: red">${id_item.name}</span>?`
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href_positionjob,'get')
        localStorage.setItem('valueSelect', "null");
      }
    });
}
function del_val_name(){
    $('#Name_wantto_delete').html("");
}

function delete_loading_positionjob(element){
    element.style.display = "none"
    element.previousElementSibling.style.display = "none"
    element.nextElementSibling.style.display = "block"
}


//validate form update
$('#btn-update-positionjob').click(function (){ 

var id = document.getElementById('txt_id_update_pj').value;
var err_id = document.getElementById('txt_id_update_pj');
var nameUP = document.getElementById('txt_name_update_pj').value;
var err_name = document.getElementById('txt_name_update_pj');

var scode = document.getElementById('txt_scode_update_pj').value;
var err_scode = document.getElementById('txt_scode_update_pj');

var desc = document.getElementById('txt_desc_update_pj').value;
var err_desc = document.getElementById('txt_desc_update_pj');

var department_id = document.getElementById('txt_department_id_update_pj').value;
var err_department_id = document.getElementById('txt_department_id_update_pj');

var create_by = document.getElementById('txt_create_by_update_pj').value;
var err_create_by = document.getElementById('txt_create_by_update_pj');

var err_create_update=document.getElementById('err_update_positionjob');
    
    if (nameUP == "") {
        err_create_update.innerHTML= err_blank_name;
        err_create_update.style.display = "block";
        err_name.style.border="1px solid red";
    }else if (scode == "") {
        err_name.style.border= "1px solid var(--falcon-input-border-color)";
        err_create_update.innerHTML= err_blank_scode;
        err_create_update.style.display = "block"
        err_scode.style.border="1px solid red"
    }else if (create_by == "") {
        err_scode.style.border="1px solid var(--falcon-input-border-color)";
        err_create_update.innerHTML=err_blank_create_by;
        err_create_update.style.display = "block";
        $("#sel_createby_positionjob").css({"border":"1px solid red" , "border-radius" :"5px"});
    }else{
        $("#sel_createby_positionjob").css({"border":"1px solid var(--falcon-input-border-color)" , "border-radius" :"5px"});

        jQuery.ajax({
            type: "GET",
            url: positonjob_edit_path,
            data: {name: nameUP, scode: scode , id: id, department_id: department_id},
            dataType: "JSON",
            success: function (response) {
                console.log(response);
                if (response.result == 'true' && nameUP == response.name){
                    err_create_update.innerHTML= job_name +response.name+ err_already_in_department + response.department_id;
                    err_create_update.style.display = "block"
                    err_name.style.border="1px solid red"
                }else if (response.result == 'true' && scode == response.scode){
                    err_create_update.innerHTML= scode_name +response.scode+ err_already_in_department + response.department_id;
                    err_create_update.style.display = "block"
                    err_scode.style.border="1px solid red"
                }else if (response.result == 'false'){
                    document.getElementById('btn-update-positionjob').style.display = "none"
                    document.getElementById("loading_button_position_jobs").style.display = "block";
                    // document.getElementById('msg_update_create_pj').style.display="block";
                    // document.getElementById('msg_update_create_pj').innerHTML=mes_update_positionjob;
                    // $('#msg_update_create_pj').show(0).delay(5000).hide(0);
                    // const myTimeout = setTimeout(reloadpage, 500);
                    // localStorage.setItem('valueSelect', response.id);
                    document.getElementById('update-positionjob').submit(); 
                }



                // if (response.msg == 'true' && nameUP == response.name) {
                //     err_create_update.innerHTML= job_name +response.name+ err_already_in_department + response.department_id;
                //     err_create_update.style.display = "block"
                //     err_name.style.border="1px solid red"
                // }else if (response.msg == 'true'  && scode == response.scode){
                //     err_create_update.innerHTML= scode_name +response.scode+ err_already_in_department + response.department_id;
                //     err_create_update.style.display = "block"
                //     err_scode.style.border="1px solid red"
                // }else if (response.results == 'true' && nameUP == response.name){
                //     err_create_update.innerHTML= job_name +response.name+ err_already_in_department + response.department_id;
                //     err_create_update.style.display = "block"
                //     err_name.style.border="1px solid red"
                // }else if (response.results == 'true' && scode == response.scode){
                //     err_create_update.innerHTML= scode_name +response.scode+ err_already_in_department + response.department_id;
                //     err_create_update.style.display = "block"
                //     err_scode.style.border="1px solid red"
                // }else if (response.result == 'false'){
                //     document.getElementById('btn-update-positionjob').style.display = "none"
                //     document.getElementById("loading_button_position_jobs").style.display = "block";
                //     // document.getElementById('msg_update_create_pj').style.display="block";
                //     // document.getElementById('msg_update_create_pj').innerHTML=mes_update_positionjob;
                //     // $('#msg_update_create_pj').show(0).delay(5000).hide(0);
                //     // const myTimeout = setTimeout(reloadpage, 500);

                //     localStorage.setItem('valueSelect', response.id);
                //     document.getElementById('update-positionjob').submit();
                // }else if(response.results == 'false'){
                //     document.getElementById('btn-update-positionjob').style.display = "none"
                //     document.getElementById("loading_button_position_jobs").style.display = "block";
                //     localStorage.setItem('valueSelect', response.id);
                //     document.getElementById('update-positionjob').submit();
                // }else {
                //     document.getElementById('btn-update-positionjob').style.display = "none"
                //     document.getElementById("loading_button_position_jobs").style.display = "block";
                //     localStorage.setItem('valueSelect', positionjob_id);
                //     document.getElementById('update-positionjob').submit();
                // }
            }
        });
    }
})

// deleteitem
function clickDeletePositionjob(id,name){
    href_positionjob += `?id=${id}}`;

    let html = `${mess_del_positionjob}  <span style="font-weight: bold; color: red">${name}</span>?`
    openConfirmDialog(html,(result )=>{
      if(result){
        doClick(href_positionjob,'get')
      }
    });

}
// onchange form update
//validate-name
document.getElementById('txt_name_update_pj').onchange= function(){
    var nameUP = document.getElementById('txt_name_update_pj').value;
    var err_name = document.getElementById('txt_name_update_pj');
    var err_scode = document.getElementById('txt_scode_update_pj');
    var err_create_update= document.getElementById('err_update_positionjob');
    if (nameUP == '') {
        err_create_update.innerHTML= err_blank_name;
        err_create_update.style.display = "block";
        err_name.style.border="1px solid red";
    }else{
        err_scode.style.border="1px solid var(--falcon-input-border-color)";
        err_create_update.style.display = "none";
        err_name.style.border="1px solid var(--falcon-input-border-color)"
    }
}
//validate-scode
document.getElementById('txt_scode_update_pj').onchange= function(){
    var scode = document.getElementById('txt_scode_update_pj').value;
    var err_scode = document.getElementById('txt_scode_update_pj');
    var err_create_update= document.getElementById('err_update_positionjob');
    if (scode == '') {
        err_create_update.innerHTML= err_blank_scode;
        err_create_update.style.display = "block";
        err_scode.style.border="1px solid red";
    }else{
        err_create_update.style.display = "none";
        err_scode.style.border="1px solid var(--falcon-input-border-color)";
    }
}

document.getElementById('txt_create_by_update_pj').onchange= function(){
    var create_by = document.getElementById('txt_create_by_update_pj').value;
    var err_create_update= document.getElementById('err_update_positionjob');
    if (create_by == '') {
       
    }else{
        err_create_update.style.display = "none";
        $("#sel_createby_positionjob").css({"border":"1px solid var(--falcon-input-border-color)" , "border-radius" :"5px"});
    }
}

// fun load page   
function reloadpage(){
    location.reload();
}

//save value of tasks- job
function saveValueToResponsible() {
    localStorage.setItem('valueSelect', document.getElementById('sel1').value);
    jQuery.ajax({
        type: "GET",
        url: update_responsible_path,
        data: { namejob: document.getElementById('sel1').value, tasks: arr_SelectedTasks },
        dataType: "JSON",
        success: function (response) {
            if (response.msg == 'true') {
                document.getElementById('btn-save-task-rp').style.display = "none"
                document.getElementById("loading_button_task_pjs").style.display = "block";
                const myTimeout = setTimeout(reloadpage, 500);
                document.getElementById('notifi-responsible').style.display = 'block';
            } else {
                document.getElementById('btn-save-task-rp').style.display = "none"
                document.getElementById("loading_button_task_pjs").style.display = "block";
                const myTimeout = setTimeout(reloadpage, 500);
                document.getElementById('notifi-responsible').style.display = 'block'
            }
        }
    });
}

function myFunction() {
    var input, filter, ul, li, a, i, txtValue;
    input = document.getElementById("myInput");
    filter = input.value.toUpperCase();
    ul = document.getElementById("list_all_task");
    li = ul.getElementsByTagName("li");
        // console.log(li[0].getElementsByTagName('input')[0].name + "li");
    
    for (i = 0; i < li.length; i++) {
        a = li[i].getElementsByTagName('input')[0].name;
        // console.log(a + "item");
        
        // txtValue = a.textContent || a.innerText;
        if (a.toUpperCase().indexOf(filter) > -1) {
            li[i].hidden = false;
        } else {
            li[i].hidden=true;
        }
    }
}