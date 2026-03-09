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
                    <span onclick="removeTaskDOM(this)" class="far fa-trash-alt span-trash-item item-trash"></span>
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
                console.log(arr_SelectedTasks);
            }
        }
        console.log(arr_SelectedTasks);
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
        <span onclick="removeTaskDOM(this)" class="far fa-trash-alt span-trash-item item-trash"></span>
    </li>`;
}


function removeTaskDOM(icon){
    let taskDOM = icon.parentElement;
    console.log(taskDOM);
    let id = taskDOM.id;
// remove task in array
    for (let i = 0; i < arr_SelectedTasks.length; i++) {
        if (`${id}` == arr_SelectedTasks[i]) {
            arr_SelectedTasks.splice(i,1); 
            taskDOM.remove();
            console.log(arr_SelectedTasks + "button");
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
