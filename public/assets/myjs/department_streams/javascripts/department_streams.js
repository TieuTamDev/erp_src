/* Author: Đinh Hoàng Vũ */
$( document ).ready(function(){
    $("#diagram-select").prop('disabled', false);
    $(".diagram-button-add").prop('disabled', false);
});
// Resize panel
ResizePanel("gutter","left-panel","diagram-containter",250,500,'x');
// Grap dorp
const grapDrop = new GrapDrop();
// Diagram
const diagram = new Diagram("diagram");

// Grap drop
grapDrop.addEventListener('ondrop',(data)=>{
    let elements = data.graps;
    let target = data.target;
    if(target.id == diagram.getContainerId()){
        elements.forEach(element=>{
            let id = element.id;
            let name = element.getAttribute("data-name");
            let pos = diagram.getMousePos();
            if(name != null && id != ""){
                diagram.addNode (id,name,pos.x,pos.y,null,null,null,false,true);
            }
        });
    }
});
grapDrop.updateDropEffect("list-department");

// diagram Zoom
document.getElementById("zoom-button").addEventListener('click',()=>{
    diagram.resetZoom();
    document.getElementById("zoom-button").innerHTML = "100%";
});
diagram.addEventListener('onzoom',(value)=>{
    document.getElementById("zoom-button").innerHTML = diagram.getZoomPercent()+ "%";
});
diagram.addEventListener('ctrl+s',(data)=>{
    if(data.id != null && data.nodes.length != 0 && data.connects.length != 0){
        clickSave();
    }
});

// diagram change forcus
diagram.addEventListener('onchangeforcus',(color)=>{
    document.getElementById("control-pick-color").value = color;
})

// Arrow controls
/**
 * 
 * @param {HTMLElement} element 
 * @param {Boolean} toggle
 */
function toggleActivate(element){
    element.classList.toggle("diagram-button-active",true);
    let parent = element.parentElement;
    let childs = parent.children;
    for (let i = 0; i < childs.length; i++) {
        const child = childs[i];
        if(child != element){
            child.classList.toggle("diagram-button-active",false);
        }
    }
}
/**
 * toggle markend arrow
 * @param {HTMLElement} element 
 * @param {Boolean} toggle 
 */
function toggleDrawEnd(element,toggle){
    diagram.setArrowEndMark(toggle);
    toggleActivate(element);
}

/**
 * change arrow solid
 * @param {HTMLElement} element 
 * @param {Boolean} toggle 
 */
function toggleArrowType(element,toggle){
    diagram.setArrowSolid(toggle);
    toggleActivate(element);
}

/**
 * Change arrow color
 * @param {HTMLElement} element 
 */
function onSelectColor(element){
    diagram.setColor(element.value);
    if(!diagram.isSelectNode()){
        $('#diagram-inner-controls').find('.arrow-controls').css('color',element.value);
        $('#diagram-inner-controls').find('#arrow-controls').css('border-color',element.value);
    }
}

/**
 * toggle grid visible
 * @param {HTMLElement} element 
 */
function toggleGrid(element){
    let toggle = element.getAttribute("data-grid") == "true";
    toggle = !toggle;
    element.classList.toggle("diagram-button-active",toggle);
    element.setAttribute("data-grid",toggle);
    diagram.toggleGridLine(toggle);
}

/**
 * 
 * @param {HTMLElement} element 
 */
function onChangeStatus(element){
    let parent = element.parentElement;
    let label = parent.getElementsByTagName('label')[0];
    if(label){
        setStatusStyle(label,element.checked);
    }
}

/**
 * Set label style by checkbox or load data
 * @param {HTMLElement} label 
 * @param {Boolean} bActive 
 */
function setStatusStyle(label,bActive){
    label.style.color = bActive? 'var(--falcon-success)': 'var(--falcon-secondary)';
    label.style.fontStyle = bActive ? 'unset' : 'italic';
    label.innerText = bActive? "ACTIVE": "INACTIVE"
}

function clickAddnew(){
    let diagramData = diagram.getDiagramData();
    if(diagramData.nodes.length > 0 || diagramData.connects.length > 0 || diagramData.id != null){
        openConfirmDialog("Công việc hiện tại có thể chưa được lưu! Bạn muốn tạo mới?",(bConfirm)=>{
            if(bConfirm){
                prepareAddNew();
            }
        });
    }else{
        prepareAddNew();
    }

}

function clickCancel(){
    clearData();
    toggleLayoutVisible(false);
    $('#diagram-select').val("0");
    if(document.getElementById("form-diagram-info").className.includes('show')){
        document.getElementById('collapse-icon').style.rotate = "unset";
    }
}

function prepareAddNew(){
    // clear data
    clearData();
    toggleLayoutVisible(true);
    if(!document.getElementById("form-diagram-info").className.includes('show')){
        $('#form-diagram-info').collapse('show');
        document.getElementById('collapse-icon').style.rotate = "90deg";
    }
}


function clearData(){
    diagram.newDiagram();
    $('#form-diagram-info').trigger("reset");
}

/**
 * On select diagram
 * @param {Event} element 
 */
function onSelectDiagram(e){
    let stream_id = e.value;
    if(stream_id == "0"){
        toggleLayoutVisible(false);
        if(document.getElementById("form-diagram-info").className.includes('show')){
            $('#form-diagram-info').collapse('hide');
            document.getElementById('collapse-icon').style.rotate = "unset";
        }
        clearData();
        return;
    }

    toggleLoading(true);
    document.querySelector('input[name="authenticity_token"]').value = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    $('#streams_edit_form').find('#input-data').attr("value", stream_id);
    $('#streams_edit_form').submit();
}

function clickSave(){
    
    // check validate
    let formValid = document.getElementById("form-diagram-info");
    if(!formValid.checkValidity()){
        toggleFormValidate('form-diagram-info',true);
        return;
    }
    toggleFormValidate('form-diagram-info',false);
    
    let diagramData = diagram.getDiagramData();
    let name = $('#diagram-name').val();
    let note = $('#diagram-note').val();
    let scode = $('#diagram-scode').val();
    let status = document.getElementById("checkbox-active").checked ? "ACTIVE" : "INACTIVE";
    let connects = diagramData.connects.map(connect=>{
        return {
            path:           connect.path,
            nend:           connect.end_id,
            nbegin :        connect.start_id,
            pend:           connect.end_direct,
            pbegin :        connect.start_direct,
            linetype:       connect.connect_type,
            endlinetype:    connect.mark_end,
            color:          connect.color,
            status:         "ACTIVE"
        }
    })
    let nodes = diagramData.nodes.map(node=>{
        return {
            department_id   : node.id,
            status          : "ACTIVE",
            px              : node.pos.x,
            py              : node.pos.y,
            color           : node.color,
            width           : node.size.width,
            height          : node.size.height,
            height          : node.size.height,
            nfirst          : node.nfirst,
        }
    });
    let data = {
        name: name, // string
        note: note, // array
        nodes: nodes, // array
        scode: scode, // string
        status: status, // string
        connects: connects, // array
        id: diagram.getDiagramId()
    }

    if (checkDataChange(data)){
        openConfirmDialog("Thay đổi sơ đồ có thể ảnh hưởng đến hoạt động của các chức năng khác!<br>Bạn có muốn lưu thay đổi?",(confirm)=>{
            if(confirm){
                // effect
                toggleLoading(true,'button-save');
                document.querySelector('input[name="authenticity_token"]').value = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
                $('#streams_update_form').find('#input-data').attr("value", JSON.stringify(data));
                // Call remote form
                $('#streams_update_form').submit();
            }
        });
    }

    
}

/**
 * Remote function
 * Reload Selection list
 * @param {Array} data 
 * @param {String} curr_id 
 */
 function loadDiagramList(data,curr_id){
    let select = document.getElementById('diagram-select');
    let childs = select.children;
    for (let i = childs.length -1 ; i >= 0; i--) {
        let element = childs[i];
        if(element.value != "0"){
            element.remove();
        }
    }

    for (let i = 0; i < data.length; i++) {
        const item = data[i];
        select.innerHTML += `<option value="${item.id}" >${item.name}</option>`;
    }
    $('#diagram-select').val(curr_id);

}

let diagramData = {
    info:null,
    nodes:null,
    connects: null
}
/**
 * Remove function
 * Load diagram data
 * @param {Object} info 
 * @param {Array} nodes 
 * @param {Array} connects
 */
function loadDiagramData(info,nodes,connects){
    toggleLayoutVisible(true);
    toggleLoading(false);
    toggleFormValidate('form-diagram-info',false);
    $('#diagram-name').val(info.name);
    $('#diagram-note').val(info.note);
    $('#diagram-scode').val(info.scode);
    document.getElementById("checkbox-active").checked =  info.status == "ACTIVE";
    onChangeStatus(document.getElementById("checkbox-active"));
    diagram.loadDiagram(info.id,nodes,connects);

    diagramData.info = info;
    diagramData.nodes = nodes;
    diagramData.connects = connects;
}

/**
 * Check data change before save
 * @returns {boolean}
 */
function checkDataChange(newData){
    return newData.id != null;
}

/**
 * Remote function
 */
function onSaveSuccess(streams,curr_id){
    toggleFormValidate('form-diagram-info',false);
    toggleLoading(false,'button-save');
    loadDiagramList(streams,curr_id);
    diagram.setDiagramId(curr_id);


}


function clickHideNodeList(icon){
    let panel = $('#left-panel');
    let onHide = panel.css('display') == 'none';
    icon.style.rotate = !onHide ? "180deg" : "unset";
    panel.toggle();
}

/**
 * Remote function
 */
function onFailed(){
    toggleFormValidate('form-diagram-info',false);
}

/**
 * 
 * @param {HTMLElement} input 
 */
function onNameChange(input){
    if(diagram.getDiagramId() == null){
        $('#diagram-scode').val(removeVietnameseTones(input.value).replace(/\s/g, ' ').trim().replaceAll(' ','-').toUpperCase());
    }
}

/**
 * 
 * @param {Boolean} bShow 
 * @param {String} buttonId 
 */
function toggleLoading(bShow,buttonId = null){
    if(buttonId){
        if(bShow){
            let text = $('#'+ buttonId).text();
            $('#'+buttonId).html(`<div class="spinner-border" role="status" style= "width:20px;height: 20px;border: 3px solid white;border-right-color: rgba(0,0,0,0);"></div> ${text}`);
        }else{
            $('#'+buttonId).find('.spinner-border').remove();
        }
    }
    $('#loading-screen').css('display',bShow ? 'flex' : 'none');
    $('#block-screen').css('display',bShow ? 'unset' : 'none');
}

function toggleFormValidate(id,bShow){
    let formValid = document.getElementById(id);
    formValid.classList.toggle('was-validated',bShow);
}

function toggleLayoutVisible(bShow){
    $('#visible-layout').css("display",bShow ? "unset" :"none")
}

function clickRemove(){
    let id = diagram.getDiagramId();
    if(id == null){
        return;
    }else{
        let name = $('#diagram-name').val();
        openConfirmDialog(`${remove_trans} <span style="color:#e63757">${name}</span> ?`,(bConfirm)=>{
            if(bConfirm){
                toggleLoading(true,'button-delete');
                document.querySelector('input[name="authenticity_token"]').value = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
                $('#streams_delete_form').find('#input-data').attr("value", id);
                $('#streams_delete_form').submit();
                clearData();
            }
        });
    }
}


/**
 * 
 * @param {HTMLElement} element 
 */
function clickCollapse(element){
    document.getElementById('collapse-icon').style.rotate = element.className.includes('collapsed') ? "unset" : "90deg";
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