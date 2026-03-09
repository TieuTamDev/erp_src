
// Huy: Import file
function initImportFileStuInfo(){
	$("#file-import-student-stu-info").on('change',(e)=>{
		let file = $("#file-import-student-stu-info")[0].files[0];
		if(file != undefined && file != null){
			$("#import-file-containter-stu-info").show();
			$("#button-upload-file-stu-info").toggleClass("btn-secondary disabled",false);
			$("#file-process-stu-info").css("width","0%");
			$("#import-file-size-stu-info").html(formatBytes(file.size));
			$("#import-file-name-stu-info").html(file.name);
		}
	})
}
initImportFileStuInfo();

/**
 * Call when click import file
 */
function clickOpenImportStuInfo(){
// clean form
let uploadBtn = $("#button-upload-file-stu-info");
let selectBtn = $("#label-select-file-stu-info");
let reUpload = $("#reupload-button-stu-info");
$("#import-file-containter-stu-info").hide();
uploadBtn.toggleClass("disabled",true);
uploadBtn.show();
selectBtn.toggleClass("disabled",false);
selectBtn.show();
reUpload.hide();

$("#file-import-student-stu-info").val(null);
$('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr("content"));
$('#import-result-stu-info').collapse("hide");
uploadBtn.find(".upload-text").show();
uploadBtn.find(".upload-process").hide();

$("#update_list_stu_info").html("");
$("#error_list_stu_info").html("");
$("#import-server-error-stu-info").hide();
}

/**
 * Click upload file to server
 */
function clickImportFileStuInfo(){
let file = $("#file-import-student-stu-info")[0].files[0];
	if(file != undefined && file != null){
	
	let uploadBtn = $("#button-upload-file-stu-info");
	let selectBtn = $("#label-select-file-stu-info");
	
	// disable cancel when on process
	$(".button-cancel-import").toggleClass("disabled",true);

	// process state: 2
	uploadBtn.toggleClass("disabled",true);
	selectBtn.toggleClass("disabled",true);
	selectBtn.toggleClass("btn-secondary disabled",true);
	uploadBtn.find(".upload-text").html(trans_uploading);
	uploadBtn.find(".upload-process").show();

	// send file
	sendImportFileStuInfo(file);
	}



}

function clickReuploadStuInfo(){
let resultShow = $('#import-result-stu-info');
let uploadBtn = $("#button-upload-file-stu-info");
let selectBtn = $("#label-select-file-stu-info");
let reUpload = $("#reupload-button-stu-info");

$("#import-file-containter-stu-info").hide();
resultShow.collapse('hide');
uploadBtn.toggleClass("btn-secondary disabled",true);
uploadBtn.find(".upload-text").html(trans_upload + `<span class="fas fa-upload ms-1"></span>`);
reUpload.hide();
uploadBtn.show();
selectBtn.show();

$("#update_list_stu_info").html("");
$("#error_list_stu_info").html("");
$("#import-server-error-stu-info").hide();
}


let import_update_list_stu_info = [];
function renderResultStuInfo(result){
import_update_list_stu_info = result.updates;
// disable cancel when upload done
$(".button-cancel-import").toggleClass("disabled",false);
let uploadBtn = $("#button-upload-file-stu-info");
let selectBtn = $("#label-select-file-stu-info");
let resultShow = $('#import-result-stu-info');
let reUpload = $("#reupload-button-stu-info");

uploadBtn.toggleClass("btn-secondary disabled",true);
uploadBtn.find(".upload-text").html(trans_upload);
uploadBtn.find(".upload-process").hide();
uploadBtn.hide();

selectBtn.toggleClass("disabled",false);
selectBtn.hide();

reUpload.show();

$("#file-import-student-stu-info").val(null);
//  load data
$("#result_total_stu_info").html(result.result_total);
$("#success_count_stu_info").html(result.success_count);
let valids = result.valids;
let error_count = $("#error_count_stu_info");
error_count.html(valids.length);
error_count.toggleClass("text-400",valids.length <= 0);

// update
let update_count = $("#update_count_stu_info");
update_count.html(import_update_list_stu_info.length);
update_count.toggleClass("text-400",import_update_list_stu_info.length <= 0);
if(import_update_list_stu_info.length > 0){
	$("#update-all-button-stu-info").show();
}else{
	$("#update-all-button-stu-info").hide();
}
let updateContainer = $("#update_list_stu_info");
import_update_list_stu_info.forEach(adpre=>{

	updateContainer.append(`<div id="update-import-${adpre.user_id}" class="border rounded-1 p-2 update-import-item" style="display: flex;align-items: center;justify-content: space-between;">
							<div style="display: flex;">
								<div class="avatar me-2" style="display: flex;justify-content: center;flex-direction: column;">
								<div style="border: 1px solid var(--falcon-badge-soft-secondary-background-color);border-radius: 50%;background-image: url(${adpre.avatar_url});overflow: hidden;background-repeat: no-repeat;background-size: cover;height: 2.9rem;width: 2.9rem;">
								</div>
								</div>
								<div>
								<p class="m-0" style="font-size: 0.9em;font-weight: 600;color: var(--falcon-badge-soft-dark-color);">${adpre.origin_name} (${adpre.sid})</p>
								<p class="m-0" style="font-size: 0.8em;font-weight: 500;color: var(--falcon-badge-soft-info-color);">${adpre.origin_email}</p>
								<p class="m-0" style="font-size: 0.9em;font-weight: 600;color: var(--falcon-badge-soft-dark-color);">${adpre.srtContractype}</p>
								<p class="badge badge-soft-danger m-0 error-message" style="font-size: 0.75em;text-align: left;width: fit-content;display:none;"></p>
								</div>
							</div>
							<div class="d-none">
								<div class="btn btn-secondary btn-sm btn-action" style="font-size: 0.7em;" onclick="skipUpdateStuInfo(${adpre.user_id})">${trans_skip}</div>
								<div class="btn btn-primary btn-sm btn-action btn-update" style="font-size: 0.7em;min-width: 65px;" onclick="updateImportStuInfo(${adpre.user_id})">
								<span class="text-update" >${trans_update}</span>
								<span class="spinner-border spinner-border-sm process-update" role="status" aria-hidden="true" style="display:none;height: 13px;width: 13px;"></span>
								</div>
								<span class='fas fa-check text-success me-3 icon-done' style="width:18px; height:18px;display:none;"></span>
							</div>
							</siv>`)
});

// errors
let error_list = $("#error_list_stu_info");
error_list.html("");
valids.forEach(valid=>{
	error_list.append(`<p class="m-0">
						<span class="badge me-1 badge-soft-danger">${valid.line}</span>
					</p>`);
})
resultShow.collapse('show');

}

/**
 * Handle update duplicate import
 * @param {any} userId
 */
function updateImportStuInfo(userId){
// get user data
let user = null
import_update_list_stu_info.forEach(item=>{
	if(item.student_id === userId){
	user = item;
	}
})

if(user == null){
	console.log("Not find :",userId)
	return;
}
submitupdateImportStuInfoForm(`#update-import-${userId}`,[user]);

}

function submitupdateImportStuInfoForm(itemId,data){
// pass data to remote form
let uploadForm = $("#update_import_form_stu_info");
uploadForm.find("#datas-stu-info").attr("value", JSON.stringify(data))

$('input[name="authenticity_token"]').val($('meta[name="csrf-token"]').attr("content"));
// submit
uploadForm.submit();

// upload button effect
if (itemId != null){
	let itemContainer = $(itemId);
	itemContainer.find(".text-update").hide();
	itemContainer.find(".process-update").show();

	// all button effect
	itemContainer.find(".btn-action").toggleClass("disabled",true);
	itemContainer.find(".error-message").hide();
}else{
	let list_item = $("#update_list_stu_info");

	list_item.find(".text-update").hide();
	list_item.find(".process-update").show();
	// all button effect
	list_item.find(".btn-action").toggleClass("disabled",true);
	list_item.find(".error-message").hide();
}
}

/**
 * Handle update all duplicate import
 */
function uploadAllImportStuInfo(){
submitupdateImportStuInfoForm(null,import_update_list_stu_info);
}

/**
 * Onclick Skip update
 * @param {any} userId 
 */
function skipUpdateStuInfo(userId){
// remove store user
for (let i = 0; i < import_update_list_stu_info.length; i++) {
	if(userId == import_update_list_stu_info[i].student_id){
	import_update_list_stu_info.splice(i, 1);
	break;
	}
}
// remove element
$(`#update-import-${userId}`).remove();

// count
$("#update_count_stu_info").html(import_update_list_stu_info.length);

if(import_update_list_stu_info.length > 0){
	$("#update-all-button-stu-info").show();
}else{
	$("#update-all-button-stu-info").hide();
}
}

/**
 * Call from back end
 */
function resultupdateImportStuInfo(result){
	result.updateds.forEach(update=>{

		for (let i = 0; i < import_update_list_stu_info.length; i++) {
		if(update.student_id == import_update_list_stu_info[i].student_id){
			import_update_list_stu_info.splice(i, 1);
			break;
		}
		}

		let wrapContainer = $(`#update-import-${update.student_id}`);
		wrapContainer.find(".icon-done").show();
		wrapContainer.find(".btn-action").remove();
	});

	result.errors.forEach(item=>{
		
		let wrapContainer = $(`#update-import-${item.student_id}`);
		// update button
		wrapContainer.find(".text-update").show();
		wrapContainer.find(".process-update").hide();
		// all action button
		wrapContainer.find(".btn-action").toggleClass("disabled",false);
		// show error message
		wrapContainer.find(".error-message").show();
		wrapContainer.find(".error-message").html(item.message);
	})
}

/**
 * Send file to backend action
 * @param {File} file 
 */
function sendImportFileStuInfo(file){

let processItem = $("#file-process-stu-info");

let formdata = new FormData();
formdata.append("file",file);
formdata.append("authenticity_token",$('meta[name="csrf-token"]').attr("content"));

var request = new XMLHttpRequest();
request.onreadystatechange = function(){
	if(request.readyState == 4 && request.status >= 200 && request.status <= 299){
		try {
			let result = JSON.parse(request.responseText);
			if (result.code >= 400){
			console.log(result);

			showServerErrorStuInfo();
			}else{
				console.log(result);
			renderResultStuInfo(result);
			}
		} catch (e){
			console.log(e)
			showServerErrorStuInfo();
		}
	}
	else if(request.status >= 400 && request.readyState == 4){
		try{
		let result = JSON.parse(request.responseText);
		console.log(result);
		}catch(e){
		console.log(e);
		}
		showServerErrorStuInfo();
	}
};

request.upload.addEventListener('progress', function(e){
	var progress_width = Math.ceil(e.loaded/e.total * 100);
	processItem.css("width",`${progress_width}%`);
	if(progress_width == 100){
		setTimeout(() => {
		$("#import-file-containter-stu-info").hide();
		processItem.css("width","0%");
		$("#button-upload-file-stu-info").find(".upload-text").html(trans_processing);
		}, 400);
	}
}, false);

let action = $("#import-action-stu-info").html();
request.open('POST', action);
request.send(formdata);
}

function showServerErrorStuInfo(){
$(".button-cancel-import").toggleClass("disabled",false);
let uploadBtn = $("#button-upload-file-stu-info");
let selectBtn = $("#label-select-file-stu-info");
let resultShow = $('#import-result-stu-info');
let reUpload = $("#reupload-button-stu-info");


uploadBtn.toggleClass("btn-secondary disabled",true);
uploadBtn.find(".upload-text").html(trans_upload);
uploadBtn.find(".upload-process").hide();
uploadBtn.hide();

selectBtn.toggleClass("disabled",false);
selectBtn.hide();

reUpload.show();

$("#file-import-student-stu-info").val(null);
$("#update_list_stu_info").html("");
$("#error_list_stu_info").html("");
resultShow.collapse('hide');
$("#import-server-error-stu-info").show();
}

/**
 * Fortmat file size
 * @param {*} a Fiel size
 * @param {*} b 
 * @param {*} k 
 * @returns 
 */
function formatBytes(a,b=2,k=1024)
{
	let d=Math.floor(Math.log(a)/Math.log(k));
	return 0 == a ? "0 Bytes" : parseFloat((a/Math.pow(k,d)).toFixed(Math.max(0,b)))+" "+["Bytes","KB","MB","GB","TB","PB","EB","ZB","YB"][d]
}