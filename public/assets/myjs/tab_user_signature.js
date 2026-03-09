let current_select_file = null;
let file_versions = [];
let actions = [];
let file_ext = "";
let file_type = "";
let current_index = 0;
let current_action = "";
let range_filler = document.getElementById('range-input');
let container_editer = null;
let canvas = null;
// crop
let cropWrap = null;
let crop = null;
let direct_resize = "";
let mouse_offset = {x:0,y:0};
let crop_offset = {x:0,y:0};

let bClickEdit = false;
let maxRatito = 200;

$(document).ready(function() {
    initInputFile();
    initCropElements();
    InitActions();
});

$("#id_cancel_add_singnature").on("click", function (){
    $("#id_add_singnature").css("display", "block");
    $("#id_cancel_add_singnature").css("display","none");
  })
function openFormAddSignature() {
    bClickEdit = false;
    $("#label-select-sign").show();
    $("#note_singnature").val(""); 
    $("#name_singnature").val(""); 
    $("#render_image").hide();
    $("#form_singnature").attr("action", singnature_create_path);
    $("#render_uploadfile_singnture").show(); 
    $("#singnature_status_active").prop("checked", true);
    $("#isdefault").prop("checked", true);
    $("#label_singnature").html("Thêm chữ ký");
    $("#name-btn-singature").html("Thêm chữ ký");
    $("#id_add_singnature").css("display","none");
    $("#id_cancel_add_singnature").css("display", "block");
  }
  function onClickChangeDefault(id) {
    $("#change_id_signature").val(id);
    $("#form_change_default").submit();
  }

  function openFormUpdateSignature(id,name,url,isdefault,status,note) {
    bClickEdit = true;
    $("html, body").animate({scrollTop: 0}, 100);
    $("#render_uploadfile_singnture").hide();
    $("#form_singnature").attr("action", `${singnature_upload_file_path}/${id}`);
    $("#render_image").show();
    $("#collapse_signature").addClass("show");
    $("#id_add_singnature").css("display","none");
    $("#id_cancel_add_singnature").css("display", "block");
    $("#image_singnature").prop("src", location.origin + "/mdata/hrm/" + url);
    $("#label_singnature").html("Cập nhật chữ ký");
    $("#name-btn-singature").html("Cập nhật chữ ký");
    
    if(status == "ACTIVE"){
        $("#singnature_status_active").prop("checked", true)
    } else { 
        $("#singnature_status_inactive").prop("checked", true)
    } 

    if(isdefault == "true"){
        $("#isdefault").prop("checked", true)
    } else { 
        $("#isdefault").prop("checked", false)
    } 
  
    $("#note_singnature").val(note); 
    $("#name_singnature").val(name);

  }

  function onPreviewLoad(img) {
      if(bClickEdit){
          console.log(img);
          loadImgTagToInput(img);
      }
  }

function initInputFile() {
    $("#filepond_multiple").on('change',(e)=>{
        let file = e.target.files[0];
        onImageFileChange(file);
    });



    $("#label-select-sign").on('dragover', (e) => {
        e.preventDefault();
        e.stopPropagation();
      })
      
      $("#label-select-sign").on('dragleave', (e) => {
        e.preventDefault();
        e.stopPropagation();
      })
      
      document.querySelector("#label-select-sign").addEventListener('drop', (e) => {
        if(e.dataTransfer.files){
            e.preventDefault();
            e.stopPropagation();

            // resize image
            let file = e.dataTransfer.files[0];
            // let datatrans = new DataTransfer(); 
            // datatrans.items.add(file);
            // document.querySelector(`#filepond_multiple`).files = datatrans.files;
            onImageFileChange(file);
        }
      })
}

function onImageFileChange(file) {

    

    const reader = new FileReader();
    reader.onload = function(e) {
        const img = new Image();
        img.onload = function(e) {
            
            let temp_canvas = resizeImage(img,maxRatito);
            let newfile = loadImageToInputForm(temp_canvas,'filepond_multiple');
            temp_canvas.remove();
            if (FileReader && newfile) {
                var fr = new FileReader();
                fr.onload = function () {
                    document.getElementById("image_singnature").src = fr.result;
                    $("#render_image").show();
                    $("#label-select-sign").hide();
                }
                fr.readAsDataURL(newfile);
            }
        };
        img.src = e.target.result;
    };
    reader.readAsDataURL(file);
}

function openEditer() {
    command('load-image','',["filepond_multiple"]);
}

function InitActions() {
    actions.push({name:"load-image",func:LoadImageAction,type:""});
    actions.push({name:"load-file-servion",func:LoadFileVersionAction,type:""});
    actions.push({name:"download-image",func:DownloadImageAction,type:""});
    actions.push({name:"cancel-action",func:CancelAction,type:""});
    actions.push({name:"save-action",func:SaveAction,type:""});
    actions.push({name:"rollback-action",func:RollbackAction,type:""});
    actions.push({name:"history-toggle-action",func:HistoryToggleAction,type:""});
    actions.push({name:"store-file-action",func:StoreFileVersion,type:""});
    actions.push({name:"remove-bg-action",func:RemoveBackgroundAction,type:""});
    actions.push({name:"flip-image-action",func:FlipImageAction,type:""});
    actions.push({name:"rotate-image-action",func:RotateImageAction,type:""});
    actions.push({name:"crop-image-action",func:CropImageAction,type:""});

    actions.push({name:"cancel",func:Cancel,type:""});
    actions.push({name:"finish",func:Finish,type:""});
}

function initCropElements() {

    container_editer = $("#edit-wrap");
    cropWrap = $("#canvas-wrap");
    crop = $("#crop");
    canvas = document.getElementById("canvas-sign");

    $(document).on('mousedown',function(e) {
        direct_resize = $(e.target).data("direct") || "";
    });
    $(document).on('mouseup',function() {
        direct_resize = "";
    });

    cropWrap.on('mousemove',function(e) {
        e.preventDefault();
        if(direct_resize == ""){
            return;
        }
        mouse_offset.x = e.pageX - cropWrap.position().left;
        mouse_offset.y = e.pageY - cropWrap.position().top;

        if(direct_resize != "moving") {
            calcResize(direct_resize);
            
        }else if(direct_resize == "moving"){
            let top = mouse_offset.y - crop_offset.y;
            let left =  mouse_offset.x - crop_offset.x;
            crop.css({
                top: top + 'px',
                left: left + 'px',
            });
        }
        
    });

    crop.on('mousedown',function(e) {
        crop_offset.x = e.offsetX;
        crop_offset.y = e.offsetY;
    });

    function calcResize(direct) {
        let left = crop.position().left;
        let top = crop.position().top;
        let width = crop.outerWidth();
        let height = crop.outerHeight();
        switch (direct) {
            case 'bottom':
                height = mouse_offset.y - top;
                break;
            case 'top':
                height = (top + height) - mouse_offset.y;
                top = mouse_offset.y;
                break;
            case 'left':
                width = (left + width) - mouse_offset.x;
                left = mouse_offset.x;
                break;
            case 'right':
                width = mouse_offset.x - left;
                break;
            case 'top left':
                height = (top + height) - mouse_offset.y;
                top = mouse_offset.y;
                width = (left + width) - mouse_offset.x;
                left = mouse_offset.x;
                break;
            case 'top right':
                height = (top + height) - mouse_offset.y;
                top = mouse_offset.y;
                width = mouse_offset.x - left;
                break;
            case 'bottom right':
                height = mouse_offset.y - top;
                width = mouse_offset.x - left;
                break;
            case 'bottom left':
                height = mouse_offset.y - top;
                width = (left + width) - mouse_offset.x;
                left = mouse_offset.x;
                break;
            default:
                break;
        }
        crop.css({
            top: top + 'px',
            left: left + 'px',
            width: width + 'px',
            height: height + 'px'
        });
    }
}

// remove background event
range_filler.addEventListener('input', function() {
    let fileData = getCurrentFile(current_index);
    if(fileData){
        command('remove-bg-action','',[fileData,range_filler.value]);
    }
});

function getCurrentFile(index) {
    if(file_versions.length == 0){
        return null;
    }
    let imageData = file_versions[index]
    return new ImageData(
        new Uint8ClampedArray(imageData.data),
        imageData.width,
        imageData.height
    )
}

/**
 * 
 * @param {string} action 
 * @param {string} type
 * @param {[]} payload
 */
function command(action,type,payload) {
    if(type == "toggle"){
        ToggleControlsAction(action);
    }else{
        ExecuteCommand(action,payload);
    }
}

// ACTIONS
function ToggleControlsAction(action) {
    $("#controls-actions [data-action]").hide();
    $(`#controls-actions [data-action="${action}"]`).css("display","flex");
    $(`#controls-actions [data-action="confirm-step"]`).css("display","flex");

    $("#controls-buttons [data-toggle]").css("background","white");
    $(`#controls-buttons [data-toggle="${action}"]`).css("background","#ccf3d5");

    if(action == "crop-image-action"){
        crop.css({
            display:"flex",
            width:"40%",
            height:"40%",
            top:0,
            left:0,
        });

    }else{
        crop.hide();
    }
    current_action = action;
}

/**
 * 
 * @param {string} action 
 * @param {[]} payload 
 */
function ExecuteCommand(action,payload) {
    for (let i = 0; i < actions.length; i++) {
        if(actions[i].name == action){
            actions[i].func(...payload);
            break;
        }
    }
}

function CancelAction() {
    $("#controls-actions [data-action]").hide();
    $("[data-action]").hide();
    $("#controls-buttons [data-toggle]").css("background","white");
}

function SaveAction() {
    // actions
    if(current_action == "crop-image-action"){
        command(current_action,'',[]);
    }

    // remove old action
    if(current_index >= 0 && current_index < file_versions.length - 1){
        if(current_index == 0){
            file_versions = [file_versions[0]];
        }else{
            file_versions = file_versions.slice(0,current_index);
        }
    }

    command('store-file-action','',[]);

    current_index = file_versions.length - 1;

    // hide all action
    command('cancel-action','',[""]);
    // check history
    command('history-toggle-action','',[]);
}

function RollbackAction(direction) {
    if(current_index < 0 && current_index > (file_versions.length - 1)){
        return;
    }
    let index = current_index + direction;
    let file = getCurrentFile(index);
    if(file){
        command('load-file-servion','',[file]);
        current_index = index;
    }
    command('history-toggle-action','',[]);
}

function HistoryToggleAction() {
    let wrap = $("#his-wrap");
    wrap.find('[data-direction]').prop("disabled",false);
    if(current_index == 0){
        wrap.find('[data-direction="back"]').prop("disabled",true);
    }
    if(current_index == file_versions.length - 1){
        wrap.find('[data-direction="forward"]').prop("disabled",true);
    }
}

function clearDatas(){
    file_versions = [];
    current_index = 0;
}

function StoreFileVersion() {
    const ctx = canvas.getContext('2d',{ willReadFrequently: true });
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    file_versions.push(imageData);
}

// controls action
function RemoveBackgroundAction(imageData,amount) {
    
    const ctx = canvas.getContext('2d',{ willReadFrequently: true });
    const threshold = amount;
    const data = imageData.data;
    for (let i = 0; i < data.length; i += 4) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];

        if (r > threshold && g > threshold && b > threshold) {
            data[i + 3] = 0;
        }
    }
    ctx.putImageData(imageData, 0, 0);
}

function FlipImageAction(type) {
    
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;


    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = width;
    tempCanvas.height = height;
    const tempCtx = tempCanvas.getContext('2d');
    tempCtx.drawImage(canvas, 0, 0);

    ctx.clearRect(0, 0, width, height);
    ctx.save();
    // horizonal
    if(type == 0){
        ctx.scale(-1, 1);
        ctx.drawImage(tempCanvas, -width, 0);
    }else{
        // vetical
        ctx.scale(1, -1);
        ctx.drawImage(tempCanvas, 0, -height);
    }
    ctx.restore();
    tempCanvas.remove();
}

function RotateImageAction(angle) {
    
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;

    const tempCanvas = document.createElement('canvas');
    const tempCtx = tempCanvas.getContext('2d');
    tempCanvas.width = width;
    tempCanvas.height = height;
    tempCtx.drawImage(canvas, 0, 0);

    if (angle === 90 || angle === -90) {
        canvas.width = height;
        canvas.height = width;
    }

    // Clear the original canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    if (angle === 90) {
        ctx.translate(height, 0);
    } else if (angle === -90) {
        ctx.translate(0, width);
    } else if (angle === 180) {
        ctx.translate(width, height);
    }

    ctx.rotate(angle * Math.PI / 180);

    ctx.drawImage(tempCanvas, 0, 0);

    ctx.setTransform(1, 0, 0, 1, 0, 0);
    
    resizeWrap(canvas.width,canvas.height);
    tempCanvas.remove();
}

function CropImageAction(){
    let left = crop.position().left;
    let top = crop.position().top;
    let width = crop.width();
    let height = crop.height();

    
    const ctx = canvas.getContext('2d',{ willReadFrequently: true });
    const imageData = ctx.getImageData(left, top, width, height);
    canvas.width = width;
    canvas.height = height;
    ctx.putImageData(imageData, 0, 0);
    resizeWrap(width,height);
}

function LoadImageAction(input_id) {
    // get input file
    let input = document.querySelector(`#${input_id}`);
    file = input.files[0];
    if(!file){
        return;
    }
    file_ext = file.name.split(".")[1];
    file_type = file.type;

    const reader = new FileReader();
    reader.onload = function(e) {
        const img = new Image();
        img.onload = function(e) {
            
            // let resizedCanvas = resizeImage(img,maxRatito);

            const ctx = canvas.getContext('2d',{ willReadFrequently: true });
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            canvas.width = img.width;
            canvas.height = img.height;
            ctx.drawImage(img, 0, 0);
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            file_versions.push(imageData);
            // wrap style
            resizeWrap(canvas.width,canvas.height);
        };
        img.src = e.target.result;
    };
    reader.readAsDataURL(file);
    // style
    container_editer.css("display","flex");
}

function Finish(input_id) {

    command('cancel-action','',[""]);

    // clean actions
    clearDatas();
    command('history-toggle-action','',[]);

    var blobBin = atob(canvas.toDataURL().split(',')[1]);
    var array = [];
    for(var i = 0; i < blobBin.length; i++) {
        array.push(blobBin.charCodeAt(i));
    }
    var blob = new Blob([new Uint8Array(array)], {type: 'image/png'});
    var file = new File([blob], "sign-image");
    let datatrans = new DataTransfer(); 
    datatrans.items.add(file);
    document.querySelector(`#${input_id}`).files = datatrans.files;

    container_editer.css("display","none");

    // show preview
    let files = document.getElementById(input_id).files;
    if (FileReader && files && files.length) {
        var fr = new FileReader();
        fr.onload = function () {
            document.getElementById("image_singnature").src = fr.result;
        }
        fr.readAsDataURL(files[0]);
    }
}

function Cancel() {
    clearDatas();
    command('cancel-action','',[""]);
    container_editer.css("display","none");
}

function LoadFileVersionAction(imageData){
    
    const ctx = canvas.getContext('2d',{ willReadFrequently: true });
    canvas.width = imageData.width;
    canvas.height = imageData.height;
    ctx.putImageData(imageData, 0, 0);
    resizeWrap(imageData.width,imageData.height);
}

// download file event
function DownloadImageAction() {
    if(file_versions.length > 0){
        var link = document.getElementById('link-download');
        link.setAttribute('download', 'sign-image.png');
        link.setAttribute('href', canvas.toDataURL("image/png").replace("image/png", "image/octet-stream"));
        link.click();
    }
}

function resizeImage(img) {
    let width = img.width;
    let height = img.height;

    const maxDimension = Math.max(width, height);
    if (maxDimension > maxRatito) {
        const scale = maxRatito / maxDimension;
        width = Math.round(width * scale);
        height = Math.round(height * scale);
    }

    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = width;
    tempCanvas.height = height;
    const tempCtx = tempCanvas.getContext('2d');
    tempCtx.drawImage(img, 0, 0, width, height);

    return tempCanvas;
}

function loadImgTagToInput(img) {
    
    let width = img.width;
    let height = img.height;
    let temp_preview = document.createElement('canvas');
    temp_preview.width = img.width;
    temp_preview.height = img.height;
    let ctx = temp_preview.getContext('2d');
    ctx.drawImage(img, 0, 0);

    const maxDimension = Math.max(width, height);
    if (maxDimension > maxRatito) {
        const scale = maxRatito / maxDimension;
        width = Math.round(width * scale);
        height = Math.round(height * scale);
    }

    let temp_resized = document.createElement('canvas');
    temp_resized.width = width;
    temp_resized.height = height;
    const tempCtx = temp_resized.getContext('2d');
    tempCtx.drawImage(img, 0, 0, width, height);

    loadImageToInputForm(temp_resized,'filepond_multiple');
    temp_preview.remove();
    temp_resized.remove();
}

function loadImageToInputForm(canvas_edit,input_id) {
    var blobBin = atob(canvas_edit.toDataURL().split(',')[1]);
    var array = [];
    for(var i = 0; i < blobBin.length; i++) {
        array.push(blobBin.charCodeAt(i));
    }
    var blob = new Blob([new Uint8Array(array)], {type: 'image/png'});
    var file = new File([blob], "sign-image");
    let datatrans = new DataTransfer(); 
    datatrans.items.add(file);
    document.querySelector(`#${input_id}`).files = datatrans.files;
    return file;
}


function resizeWrap(width,height){
    let wrap = $("#canvas-wrap");
    wrap.css("width",width);
    wrap.css("height",height);
}