class FormMedia{

    #files = []

    #action = "";
    #bShowDelBtn = true;
    #bShowLabelAdd = true;

    #container = null;
    #containerID = null;
    #inputElement = null;
    #emptyInput = null;
    #listItems = null;

    #table = null;

    #controls = null;
    #modal = null;
    
    #events = []; // upload_success, confirmdel

    #bUpload = false;
    #iconPath = "";
    #root_path = "/";

    #translate = {
        upload_guide_1:"Chọn file để upload",
        upload_guide_2:"Bạn cũng có thể chọn nhiều files cùng một lúc",
        upload_guide_3:"Bạn cũng có thể kéo thả files vào khung đây để upload",
        confirm_delete:"Xác nhận xóa",
        confirm_delete_all:"Xóa tất cả",
        select_files:"Chọn files",
        cancel:"Cancel",
        confirm:"Confirm",
        message:"Message",
        remove:"Remove",
        upload:"Upload",
        error: "Lỗi",
        try_again:"Vui lòng thử lại",
        file_name: "Tên tập tin",
        create_date: "Ngày tạo",
        created_by: "Người tạo"
    }

    /**
     * constructor
     * @param {String} containerID 
     */
    constructor(containerID,root_path){
        this.#containerID = containerID;
        this.#root_path = root_path;
    }

    // PRIVATE
    #initUI(){

        if(this.#containerID == null || this.#containerID == undefined){
            console.warn("initUI: Empty ID");
            return;
        }
        this.#container = document.getElementById(this.#containerID);
        if(this.#container == null){
            console.warn("initUI: Not found container : "+this.#containerID);
            return;
        }
        
        // empty container

        this.#emptyInput = document.createElement('div');
        this.#emptyInput.className = "mb-2";
        this.#emptyInput.innerHTML = `<span style="height: 30px;width: 30px;" class="fas fa-plus"></span>`;
        this.#emptyInput.style.cssText = "width: 100%;cursor: pointer;border: 2px dashed var(--falcon-warning);border-radius: 10px;display: flex;align-items: center;justify-content: center;padding: 10px;color: var(--falcon-btn-falcon-warning-color);opacity: 0.6;";
        
        this.#emptyInput.addEventListener('click',(e)=>{
            this.#inputElement.click();
        });

        this.#emptyInput.addEventListener('drop',(e)=>{
            e.preventDefault();
            this.#onFiledrop(e);
        },false);

        this.#emptyInput.addEventListener("dragover",function(e){
            e.preventDefault();
        },false);

        this.#container.append(this.#emptyInput);

        if(this.#bShowLabelAdd){
            $(this.#emptyInput).show();
        }else{
            $(this.#emptyInput).hide();
        }

        // input
        this.#inputElement = document.createElement('input');
        this.#inputElement.type = 'file';
        this.#inputElement.multiple = true;
        this.#inputElement.hidden = true;
        this.#inputElement.addEventListener('change',()=>{
            this.#onInputFile(this.#inputElement);
        })
        this.#container.append(this.#inputElement);

        // list item
        this.#listItems = document.createElement("ul");
        this.#listItems.className = "list-group scrollbar";
        this.#container.append(this.#listItems);

        // controls
        this.#controls = document.createElement("div");
        this.#controls.hidden = true;
        this.#controls.className = "mt-3 media-controls";

        let btnUploadAll = document.createElement("div");
        btnUploadAll.className = "btn btn-warning me-3";
        btnUploadAll.innerHTML = `<i class="fas fa-upload"></i> ${this.#translate.upload}`;
        btnUploadAll.addEventListener('click',()=>{
            this.#clickUploadAll();
        });

        // this.#controls.append(btnAddMore);
        this.#controls.append(btnUploadAll);
        // this.#controls.append(btnDeleteAll);
        
        this.#container.append(this.#controls);


        let tableDom = document.createElement('div');
        tableDom.id = `table_file_${this.#containerID}`;
        tableDom.className = "table-responsive scrollbar mt-2";
        tableDom.setAttribute("data-list","");
        tableDom.innerHTML = `<table class="table table-bordered table-striped fs--2 table-sm mb-0">
                                    <thead class="text-900 bg-200">
                                        <tr>
                                            <th class="sort" data-sort="name">${this.#translate.file_name}</th>
                                            <th class="sort" data-sort="created_at">${this.#translate.create_date}</th> 
                                            <th class="sort" data-sort="file_owner">${this.#translate.created_by}</th>
                                            <th></th>
                                        </tr>
                                    </thead>
                                    <tbody class="list"></tbody>
                                </table>
                                <div class="d-flex justify-content-center mt-3 mb-1">
                                    <a class="btn btn-sm btn-falcon-default me-1" type="button" title="Previous" data-list-pagination="prev"><span class="fas fa-chevron-left"></span></a>
                                    <ul class="pagination mb-0"></ul>
                                    <a class="btn btn-sm btn-falcon-default ms-1" type="button" title="Next" data-list-pagination="next"><span class="fas fa-chevron-right"> </span></a>
                                </div>`;

        this.#container.append(tableDom);
        let icon_path = this.#iconPath;
        let self = this;
        var options = {
            valueNames: [ 'name', 'created_at','file_owner','id_doc','benefit_id' ],
            page:5,
            pagination:true,
            item: function (doc){
                return `<tr id="item-${self.#containerID}${doc.id}">
                            <td style="text-align: left" class="name">
                                <img style="margin-left: 10px; margin-right: 5px;" src="${icon_path + self.#getIconFile(doc.file_name)}" alt="file">${doc.file_name}
                            </td>
                            <td style="text-align: left" class="created_at">${doc.created_at}</td>
                            <td style="text-align: left" class="file_owner">${doc.file_owner}</td>
                            <td style="text-align: center;white-space: nowrap;">
                                <a href="https://erp.bmtu.edu.vn/mdata/hrm/${doc.file_name}" target="_blank" class="me-3" style="text-decoration: none; cursor: pointer;" title="View" >
                                    <i class = "fas fa-eye icon"></i>
                                </a>
                                <a download href="https://erp.bmtu.edu.vn/mdata/hrm/${doc.file_name}" target="_blank" class="me-3" style="text-decoration: none; cursor: pointer;" title="Download" >
                                    <i class = "fas fa-file-download icon"></i>
                                </a>
                                ${self.#bShowDelBtn ? `<a id="remove-doc" data-button-remove-doc="${doc.id}" style="text-decoration: none; cursor: pointer;" title="Delete">
                                                            <span style="pointer-events: none;" class="text-danger fas fa-trash" style="width : 15px"></span>
                                                        </a>` : ""}
                                
                            </td>
                        </tr>`;
            }
        };
        this.#table = new window.List(tableDom.id,options)

        tableDom.addEventListener('click',(e)=>{
            let id = e.target.getAttribute('data-button-remove-doc');
            if(id){
                let items = this.#table.items;

                for (let i = 0; i < items.length; i++) {
                    let data = items[i].values();
                    if(data.id.toString() == id.toString()){
                        // add remove click event
                        this.#showConfirm(`${this.#translate.confirm_delete}: <span style="color:red;">${data.file_name}</span> ?`,(result)=>{
                            if(result){
                                this.#fireEvent('confirmdel',data);
                            }
                        });
                        break;
                    }
                }
            }
        })

        // modal confirm
        this.#modal = document.createElement('div');
        this.#modal.id = this.#containerID + "-modal";
        this.#modal.className = "modal fade";

        this.#modal.innerHTML +=    `<div class="modal-dialog modal-dialog-centered" role="document" style="max-width: 500px">
                                        <div class="modal-content position-relative">
                                            <div class="position-absolute top-0 end-0 mt-2 me-2 z-index-1">
                                            <button class="btn-close btn btn-sm btn-circle d-flex flex-center transition-base" data-bs-dismiss="modal" aria-label="Close"></button>
                                        </div>
                                            <div class="modal-body p-0">
                                                <div class="rounded-top-lg py-3 ps-4 pe-6 bg-light">
                                                    <h4 class="mb-1">${this.#translate.message}</h4>
                                                </div>
                                                <div class="p-4 pb-0">
                                                    <p id="dialog-message"></p>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <button id="close-modal" class="btn btn-secondary" type="button" data-bs-dismiss="modal">${this.#translate.cancel}</button>
                                                <button id="confirm-modal" class="btn btn-primary" type="button">${this.#translate.confirm}</button>
                                            </div>
                                        </div>
                                    </div>`;

        
        this.#container.append(this.#modal);
    }

    #onInputFile(input){
        if(this.#bUpload){
            return;
        }

        let inputFiles = input.files;
        let duplicate = false;
        for (var i = 0; i < inputFiles.length; i++) {
            duplicate = this.#files.some(item=>item.file.name == inputFiles[i].name);
            if(!duplicate){
                this.#addFile(inputFiles[i]);
            }
        }
        //clear value
        input.value = null;
        this.#updateList();
    }

    // event
    #onFiledrop(e){
        if(this.#bUpload){
            return;
        }

        var files_drop = e.dataTransfer.files;
        let duplicate = false;
        for (var i = 0; i < files_drop.length; i++) {
            duplicate = this.#files.some(item=>item.file.name == files_drop[i].name);
            if(!duplicate){
                this.#addFile(files_drop[i]);
            }
        }
  
        this.#updateList();
  
    };

    #updateList(){
        this.#controls.hidden = this.#files.length <= 0;

        this.#listItems.innerHTML = "";
        for (let i = 0; i < this.#files.length; i++) {
            let file = this.#files[i].file;
            let id = this.#files[i].id;
            let item = this.#renderItem(id,file.name,file.size,file.type);
            this.#listItems.append(item);
        }
    }
    
    #renderItem(itemID,name,size,type){
        // size calc
        let str_size = this.#formatBytes(size);
        let file_type = this.#get_file_type(type,name.split('.').pop());
        let iamgeUrl = `${this.#iconPath}${file_type}.png`;
        let item = document.createElement('li');
        item.id = itemID;
        item.className = "list-group-item item-file";
        item.innerHTML =    `<div class="item-file-info">
                                <img style="margin-left: 10px; margin-right: 5px;" src="${iamgeUrl}" alt="file">
                                <p class="m-0 form-check-label item-file-name" style="font-size: 0.9em;font-weight: 700;">${name}</p>
                            </div>
                            <p class="item-file-size">${str_size}</p>
                            <div class="me-3 item-file-process">
                                <span class="item-file-error" hidden></span>
                                <div class="progress">
                                    <div class="progress-bar" role="progressbar" style="width: 0%" aria-valuenow="25" aria-valuemin="0" aria-valuemax="100"></div>
                                </div>
                            </div>`;

        let controls = document.createElement('div');
        controls.className = "item-file-buttons";
        
        let uploadButton = document.createElement('div');
        uploadButton.className = "btn btn-success btn-sm upload-button";
        uploadButton.style.cssText = "margin-right: 10px; padding: 2px 7px;";
        uploadButton.innerHTML = `<i class="fas fa-upload"></i> ${this.#translate.upload}`;
        uploadButton.addEventListener('click',(e)=>{
            this.#clickUpload(itemID);
        })
        let removeButton = document.createElement('div');
        removeButton.className = "btn btn-danger btn-sm remove-button";
        removeButton.style.cssText = "padding: 2px 7px;";
        removeButton.innerHTML = `<i class="far fa-trash-alt"></i> ${this.#translate.remove}`;

        removeButton.addEventListener('click',()=>{
            this.#clickRemove(name,itemID);
        })
        controls.append(uploadButton);
        controls.append(removeButton);

        item.append(controls);
        return item;
    }


    #addFile(file){
        this.#files.push({
            id:"item-" + file.lastModified,
            file:file
        });
    }

    #clickRemove(name,itemID){
        this.#showConfirm(`${this.#translate.confirm_delete}: <span style="color:red;">${name}</span> ?`,(bShow)=>{
            if(bShow){
                this.#removeFile(itemID);
            }else{
                    
            }
        });
    }

    #clickUpload(itemID){
        for (let i = 0; i < this.#files.length; i++) {
            let file = this.#files[i].file;
            if(this.#files[i].id == itemID){
                this.#upload(file,itemID);
                break;
            }
            
        }
    }

    #clickUploadAll(){
        for (let i = 0; i < this.#files.length; i++) {
            let file = this.#files[i].file;
            let id = this.#files[i].id;
            this.#upload(file,id);
        }
    }

    #clickDeleteAll(){
        this.#showConfirm(`${this.#translate.confirm_delete_all} ?`,(bShow)=>{
            if(bShow){
                this.removeAllFiles();
            }else{
                
            }
        })
    }

    #get_file_type(type,ext){
        if(type != "" && type.trim().length != 0){
            let types = {
                "photo":"image/png image/jpg image/jpeg image/webp image/gif image/tiff",
                "doc":"application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "excel":"application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "power-point":"application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation",
                "text":"text/plain",
                "pdf":"application/pdf",
                "video":"video/mp4 video/avi video/x-ms-wmv video/quicktime",
                "zip":"application/zip application/x-zip-compressed"
            }
            for (var key in types){
                if(types[key].includes(type)){
                    return key;
                }
            }
        }else{
                if(ext == "rar"){
                    return "zip";
                }
            return "file";
        }
        return "file"
    }

    #getIconFile(name){
        let ext = name.split('.').pop();
        if(['png','jpg','jpeg','webp','gif','tiff'].includes(ext)){
            return "photo.png";
        }else if(['doc','docx'].includes(ext)){
            return "doc.png";
        }else if(['xls','xlsx'].includes(ext)){
            return "excel.png";
        }else if(['txt'].includes(ext)){
            return "text.png"
        }else if(['pdf'].includes(ext)){
            return "pdf.png"
        }else if(['mp4','avi','wmv'].includes(ext)){
            return "video.png"
        }else if(['pptx','ppt'].includes(ext)){
            return "power-point.png"
        }else if(['zip','rar'].includes(ext)){
            return "zip.png"
        }else{
            return "file.png";
        }
    }

    #formatBytes(a,b=2,k=1024)
    {
        let d=Math.floor(Math.log(a)/Math.log(k));
        return 0 == a ? "0 Bytes" : parseFloat((a/Math.pow(k,d)).toFixed(Math.max(0,b)))+" "+["Bytes","KB","MB","GB","TB","PB","EB","ZB","YB"][d]
    }

    #upload(file,itemID) {

        if(this.#action == ""){
            return;
        }

        let upload = this;
        
        let item = document.querySelector("#" + itemID);
        let process = item.querySelector(".progress");
        process.hidden = false;
        //  process bar
        let process_bar = item.querySelector(".progress-bar");
        process_bar.style.cssText = "width: 0%";
        // button upload
        let btnUpload = item.querySelector(".upload-button");
        btnUpload.innerHTML = `<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>`;
        btnUpload.disabled = true;
        // button remove
        let btnRemove = item.querySelector(".remove-button");
        btnRemove.disabled = true;
        //error message
        let errorMsg = item.querySelector(".item-file-error");
        errorMsg.hidden = true;

        let formdata = new FormData();
        formdata.append("file",file);
        formdata.append("authenticity_token",document.querySelector('meta[name="csrf-token"]').getAttribute('content'));

        var request = new XMLHttpRequest();
        request.onreadystatechange = function(){
            if(request.readyState == 4 && request.status >= 200 && request.status <= 299){
                try {
                    upload.#removeFile(itemID);
                    upload.tableAddItems([JSON.parse(request.responseText)]);
                    upload.#fireEvent("upload_success",JSON.parse(request.responseText));
                } catch (e){
                    
                }
            }
            else if(request.status >= 400){
                btnUpload.innerHTML = `<i class="fas fa-plus"></i> ${upload.#translate.upload}`;
                btnUpload.disabled = false;
                btnRemove.disabled = false;

                process.hidden = true;
                errorMsg.hidden = false;
                errorMsg.innerHTML = `${upload.#translate.error} (${request.status}). ${upload.#translate.try_again}`;
            }
        };

        request.upload.addEventListener('progress', function(e){
            var progress_width = Math.ceil(e.loaded/e.total * 100) + '%';
            process_bar.style.cssText = `width: ${progress_width}`;
        }, false);

        request.open('POST', this.#action);
        request.send(formdata);
    }

        /**
     * Fire event
     * @param {String} eventName 
     * @param {Any} payload 
     */
    #fireEvent(eventName,payload){
        for (var i = 0; i < this.#events.length; i++) {
            if(eventName == this.#events[i].name){
                this.#events[i].callback(payload);
            }
        }
    }

    /**
    * Show confirm dialog with callback
    * @param {String} message
    * @param {Function} callback
    */
    #showConfirm(message,callback){
        $("#" + this.#modal.id).find("#dialog-message").html(message);
        $("#" + this.#modal.id).modal('show');

        $("#" + this.#modal.id).find("#close-modal").off().on('click',()=>{
            callback(false);
        });

        $("#" + this.#modal.id).find("#confirm-modal").off().on('click',()=>{
            $("#" + this.#modal.id).modal('hide');
            callback(true);
        });
    }

    #removeFile(id){
        let index = -1;
        for (let i = 0; i < this.#files.length; i++) {
            if(this.#files[i].id == id){
                index = i;
                break;
            }
        }
        if(index >= 0){
          this.#files.splice(index,1);
        }

        let item = this.#listItems.querySelector("#"+ id);
        item.remove();
        this.#controls.hidden = this.#files.length <= 0;
    }

    tableAddItems(datas){
        datas.forEach(data=>{
            this.#table.add(data);
        })
    }

    removeTableItem(id){
        this.#table.remove('id',id);
    }

    removeTableItemAll(){
        this.#table.clear();
    }

    // PUBLIC
    /**
     * 
     * @param {String} name 
     * @param {Function} callback 
     */
     addEventListener(name,callback){
        this.#events.push({
            name:name,
            callback:callback
        });
    }

    removeAllFiles(){
        for (let i = 0; i < this.#files.length; i++) {
            let id = this.#files[i].id;
            let item = this.#listItems.querySelector("#"+ id);
            item.remove();
        }
        this.#files = [];
        this.#controls.hidden = true;
    }

    /**
     * 
     * @param {String} iconPath 
     */
    setIconPath(iconPath){
        this.#iconPath = iconPath;
    }

    /**
     * 
     * @param {String} action 
     */
    setAction(action){
        this.#action = action
    }

    setTableItems(items){

    }

    /**
     * 
     */
    showDeleteButton(bShow){
        this.#bShowDelBtn = bShow;
    
    }
    /**
     * 
     */
    showLabelAdd(bShow){
        this.#bShowLabelAdd = bShow;
        if(this.#bShowLabelAdd){
            $(this.#emptyInput).show();
        }else{
            $(this.#emptyInput).hide();
        }

    }

    /**
     * 
     * @param {Object} trans 
     */
    setTranslate(trans){
        this.#translate = {...this.#translate,...trans};
    }

    /**
     * Init lib
     */
    init(){
        this.#initUI();
    }
}       