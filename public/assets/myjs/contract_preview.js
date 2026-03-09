let editTokenElement = null;
$(document).ready(function() {
    let wrap_content = $('#scontent');
    
    // render token
    tokenList.forEach(token=>{
        value = token.value;
        if(token.value.trim().length <= 0 || token.value.trim() == token.name.trim()){
            value = token.name;
            wrap_content.find(`[data-token-name=${token.name}]`).find(".token-display").toggleClass("empty-token",true);
        }
        wrap_content.find(`[data-token-name=${token.name}]`).find(".token-display").html(value);
    });

    // check tokens exist
    if (exitsTokens.length > 0){
        // load list tokens
        let messageContent =  document.createElement("div");
        let messageText = `<h3 class="mb-3 text-warning" style="font-size: 1.1em;">Sử dụng token đã tồn tại?</h3>`;
        let tokenContainer = document.createElement("ul");
        tokenContainer.className = "list-group scrollbar pe-2";
        tokenContainer.style.maxHeight = "450px";
        exitsTokens.forEach(item=>{
            let token = `
                <li class="pt-1 pb-1 pe-4 list-group-item d-flex align-items-center justify-content-between"    id="token-${item.id}">
                    <div>
                        <p style="font-size: 0.9em;" class="m-0">${item.name}</p>
                        <p style="font-weight: 600;font-size: 0.9em;" class="m-0">${item.value}</p>
                    </div>
                    <span  class="fas fa-trash text-danger" style="cursor: pointer;" onclick="clickRemoveReplaceToken(${item.id})"></span>
                </li>
            `;
            tokenContainer.innerHTML += token;
        });
        messageContent.innerHTML = messageText;
        messageContent.append(tokenContainer);
        // show confirm modal
        openConfirmDialog(messageContent,(reslult)=>{
            if (reslult){
                //  replace exist token
                tokenList.forEach(token=>{
                    let index = exitsTokens.findIndex(item => item.name == token.name);
                    if(index >= 0){
                        let value = exitsTokens[index].value;
                        token.value = value;
                        wrap_content.find(`[data-token-name=${token.name}]`).find(".token-display").html(value);
                        wrap_content.find(`[data-token-name=${token.name}]`).find(".token-display").toggleClass("empty-token",false);
                    }
                });

            }
        })
    }
});


function clickRemoveReplaceToken(tokenID) {
    $("#token-"+tokenID).remove();
    let index = exitsTokens.findIndex(token => token.id === tokenID);
    if (index >= 0) {
        exitsTokens.splice(index,1);
    }
    if (exitsTokens.length == 0) {
        toggleConfirmDialog(false);
    }
}

$(".token-display").on('click',(e)=>{
    editTokenElement = $(e.target.parentElement);
    let name = editTokenElement.attr("data-token-name");
    let value = "";
    let id = "";

    tokenList.forEach(token => {
        if(token.name == name){
            value = token.value
            id = token.id
        }
    });

    // ignore empty value
    if (value.trim() == name.trim()){
        value = "";
    }

    $("#token-popup-name").val(name);
    $("#token-popup-value").val(value);
    $("#token-popup-id").val(id);

    $("#token-edit-popup").modal('toggle');
    $("#token-popup-value").focus()
})

$("#token-popup-value").on('keydown',(e)=>{
    showArletToken(false);
    if(e.key == "Enter"){
        $("#button-save-token").click();
    }
});

function clickSaveToken(){
    let value = $("#token-popup-value").val();
    let name = $("#token-popup-name").val();
    let index = tokenList.findIndex(token=>token.name == name);
    if(index < 0){
        $('#token-edit-popup').modal('hide');
        return;
    }

    if(value.trim() == "" || value.trim() == name.trim()){
        showArletToken(true);
        return;
    }else{
        showArletToken(false);
    }
    
    tokenList[index].value = value;

    // change all token name in preview
    let items = $('#scontent').find(`[data-token-name='${name}']`).find(".token-display");
    items.toggleClass("empty-token",false);
    items.html(value);
    $("#token-popup-name").attr("data-name");
    $('#token-edit-popup').modal('hide');
}

function showArletToken(bShow){
    let arlet = $("#alert-token");
    if(bShow){
        arlet.attr('class', 'alert alert-warning fade show p-2');
        arlet.show();
    }else{
        arlet.attr('class', '');
        arlet.hide();
    }
}

/**
 * Get list of empty tokens
 * @returns {Array} list empty token
 */
function getEmptyTokens(){
    return tokenList.filter(item=>{
        return item.name == item.value
    });
}

function clickSave(bExport = false){
    // check token empty value
    let emptyTokens = getEmptyTokens();
    // show 
    if(emptyTokens.length > 0 && bExport == true){
        let htmlMessage = renderEmptyTokens(emptyTokens);
        openConfirmDialog(htmlMessage,(result)=>{
            if(result){
                submitSave(bExport);
            }
        });
    }else{
        submitSave(bExport);
    }
}

function submitSave(bExport){
    $('#preview-update-form').find("#bexport").val(bExport.toString());
    tokenList.forEach(token => {
        $('#preview-update-form').append(`<input type="hidden" name="names[]" value="${token.name}" />`);
        $('#preview-update-form').append(`<input type="hidden" name="values[]" value="${token.value}" />`);
        $('#preview-update-form').append(`<input type="hidden" name="ids[]" value="${token.id}" />`);
    });
    $('#preview-update-form').submit();
}

/**
 * Render list empty token to modal
 * @param {Array} emptyTokens 
 */
function renderEmptyTokens(emptyTokens){
    let messageHtml =  document.createElement("div");
    let messageText = `<p class="mb-3 text-warning" style="font-weight: 500;">Tìm thấy token chưa có dữ liệu. Bạn muốn tiếp tục ?</p>`;
    messageHtml.innerHTML = messageText;
    let tokenContainer = document.createElement("ul");
    tokenContainer.className = "list-group scrollbar pe-2";
    tokenContainer.style.maxHeight = "450px";
    emptyTokens.forEach(item=>{
        let token = `<li class="pt-1 pb-1 pe-4 list-group-item d-flex align-items-center justify-content-between font-size: 0.9em;" >${item.name}</li>`;
        tokenContainer.innerHTML += token;
    });
    messageHtml.append(tokenContainer);
    return messageHtml;
}

function clickPrint(){
    // check token empty value
    let emptyTokens = getEmptyTokens();
    if(emptyTokens.length > 0){

        let htmlMessage = renderEmptyTokens(emptyTokens);
        openConfirmDialog(htmlMessage,(result)=>{
            if(result){
                printContent(replaceEmptyToken(emptyTokens));
            }
        });
    }else{
        printContent(replaceEmptyToken(emptyTokens));
    }
}

function replaceEmptyToken(emptyTokens){
    let content = document.createElement("div");
    content.innerHTML = $('#scontent').html();
    let jq_content = $(content);
    jq_content.find("[data-token-name]").each((i,item)=>{
        let jq_item = $(item).find(".token-display");
        let html = jq_item.html();
        if (html){
            let dataName = $(item).attr("data-token-name");
            let findIndex = emptyTokens.findIndex(token=>token.name == dataName);
            if(findIndex >= 0){
                jq_item = $(jq_item);
                jq_item.toggleClass("token-display",false);
                jq_item.html(" ");
            }
        }
    });

    return jq_content.html();
}


function printContent(content){
    
    var mywindow = window.open('', 'PRINT', 'height=400,width=600');
    mywindow.document.write('<html><head></head>');
    mywindow.document.write(`<style>
                                p {
                                    margin:0
                                }
                            </style>`)
    mywindow.document.write('<body>');
    mywindow.document.write(content);
    mywindow.document.write('</body></html>');

    mywindow.document.close(); // necessary for IE >= 10
    mywindow.focus(); // necessary for IE >= 10*/

    mywindow.print();
    mywindow.close();
}
