/* Author: Đinh Hoàng Vũ */
class Diagram {
    #id = null;
    #nodeMain = null;
    #nodeContainer = null;
    #formsLabelList = [];
    #dropMenu = null;
    #nodeprefix = "node-";
    #node_width_default = 200;
    #node_height_default = 40;
    #selectClass = "show-button";

    #labelId = "connect-label"
    #labelFormId = "label-forms"
    #labelStatusId = "label-status"
    #labelIdenfityId = "label-idenfity"
    #labelButtonId = "label-button"
    #popupSelectFormId = "popup-edit-label";
    // Control, Shift,Alt
    
    // event
    #eventHandlers = [];
    #EVENT_ZOOM = "onzoom";
    #EVENT_CHANGE_FORCUS = "onchangeforcus";

    // color
    #colorSelectArrow = "#000000";

    // gird
    #GRID_UNIT = 10;
    #PREAK_LENGTH = 20;
    // arrow type
    #ARROW_DASH = "ARROW_DASH";
    #ARROW_SOLID = "ARROW_SOLID";
    // define action
    #NONE_ACT = "";
    #MOVING_NODE_ACT = "MOVING_NODE_ACT";
    #DRAW_ARROW_ACT = "DRAW_ARROW_ACT";
    #MOVING_ARROW_ACT = "MOVING_ARROW_ACT";
    #MOVING_CONTAINER_ACT = "MOVING_CONTAINER_ACT";
    #RESIZE_NODE_ACT = "RESIZE_NODE_ACT";
    #MOVING_ARROW_PATH_ACT = "MOVING_ARROW_PATH_ACT";
    #DRAW_SELECT_AREA_ACT = "DRAW_SELECT_AREA_ACT";

    // direction
    #UP = "UP";
    #LEFT = "LEFT";
    #DOWN = "DOWN";
    #RIGHT = "RIGHT";

    // points amount
    #POINT_AMOUNTS = [5,5,5,5];
    #POINT_DIRECTS = [this.#UP,this.#LEFT,this.#DOWN,this.#RIGHT];


    // key status
    #keyHold = []

    #actionData = {
        curr_mouse:{x:0,y:0},
        curr_action:this.#NONE_ACT,
        mouseOffset:{x:0,y:0},
        act_target: null,
        resize:{
            target:null,
            direction:null,
            currSize:null,
            currMouse:{x:0,y:0}
        },
        drawArrow:{
            start:{
                id:"",
                direct:""
            }
        },
        movingPath:{
            connectId:null,
            path:null,
            areaArrow:null,
            direct:"x",
            p1Index:0,
            p2Index:0,
            offset:{x:0,y:0},
            arr_paths: []
        },
        selectItem:{
            target:null,
            onShow:false
        }
    }
    // paths
    #CIRCLE_PATH = "M 8.75 0 a 8.75 8.75 90 1 1 -17.5 0 a 8.75 8.75 90 1 1 17.5 0"
    #REMOVE_ICON_PATH = "M-3-5C-3.5-5.5-4.5-5.5-5-5-5.5-4.5-5.5-3.5-5-3L-2 0-5 3C-5.5 3.5-5.5 4.5-5 5-4.5 5.5-3.5 5.5-3 5L0 2 3 5C3.5 5.5 4.5 5.5 5 5 5.5 4.5 5.5 3.5 5 3L2 0 5-3C5.5-3.5 5.5-4.5 5-5 4.5-5.5 3.5-5.5 3-5.021L0-2Z";
    #LABEL_ICON_PATH = "M 0.8148 -3.1352 l 2.5604 2.5604 l -5.5598 5.5598 l -2.2828 0.252 C -4.773 5.2708 -5.0312 5.0124 -4.9972 4.7068 l 0.254 -2.2844 l 5.558 -5.5576 z m 4.144 -0.3812 l -1.2022 -1.2022 c -0.375 -0.375 -0.9832 -0.375 -1.3582 0 l -1.131 1.131 l 2.5604 2.5604 l 1.131 -1.131 c 0.375 -0.3752 0.375 -0.9832 0 -1.3582 z";
    #xmlns = "http://www.w3.org/2000/svg";

    // data should be reset when addnew, load new call
    #listNodes = [];
    #listConnects = [];

    // controls
    #curr_zoom = 1.0;
    #zoom_step = 0.1;
    #b_showGrid = true;
    #controlData = {
        arrowColor:"rgb(0 0 0)",
        arrowType: this.#ARROW_SOLID,
        arrowMarkEnd:true
    }

    // other
    #bShowFlowAnim = false;


    // preview
    #previewArrow = null;
    #previewPath = null;
    #previewInfo = {
        offset:{x:0,y:0},
        startPos:{x:0,y:0},
        startId:"",
        startDirect : "",
        drawNew: true
    }

    // select multi
    #selectNodes = [];
    #SelectAreaSVG = null;
    #SelectAreaPath = null;
    #selectAreaInfo = {
        startPos:{x:0,y:0}
    }
    
    // mouse state
    #bMousedown = false;
    #mouseButton = null;

    #trans = {
        cancel:"Cancel",
        delete:"Delete",
        confirm:"Confirm",
        popup_connect_title:"Select form"
    }

    /**
     * @param {String} containerId
     */
    constructor(containerId){
        this.#nodeMain = document.getElementById(containerId);
    }

    init(){
        if(this.#nodeMain){
            this.#initMainElement(this.#nodeMain);
            this.#initKeyEvent();
            this.#nodeContainer = this.#createNodeContainer();
            this.#nodeMain.append(this.#nodeContainer);
            this.#createPreviewArrow();
            this.#createSelectArea();
            this.#dropMenu = this.#initDropdown();
            this.#initPopupSelect();
        }else{
            console.error("Can't get diagram container: "+containerId);
        }
        
    }

    // PRIVATE METHOD

    /**
     * Setup key event
     */
    #initKeyEvent(){
        document.addEventListener('keypress',(e)=>{
            if (e.key == "Delete"){
                this.#removeSelected();
            }
        })
        document.addEventListener('keydown',(e)=>{
            if(!this.#keyHold.includes(e.key)){
                this.#keyHold.push(e.key);
            }
            // ctrl + S
            if (e.keyCode == 83 && (navigator.platform.match("Mac") ? e.metaKey : e.ctrlKey)){
                e.preventDefault();
                this.#fireEvent('ctrl+s',this.getDiagramData());
            }
             // ctrl + F
            else if (e.keyCode == 70 && (navigator.platform.match("Mac") ? e.metaKey : e.ctrlKey)){
                e.preventDefault();
                this.#bShowFlowAnim = !this.#bShowFlowAnim;
                this.#listConnects.forEach(connect=>{
                    connect.path.classList.toggle("flow-anim",this.#bShowFlowAnim);
                });
            }
    });
        document.addEventListener('keyup',(e)=>{
            if(e.key == "Delete"){
                this.#removeSelected();
            }

            const index = this.#keyHold.indexOf(e.key);
            if (index > -1) {
                this.#keyHold.splice(index, 1);
            }
        });
    }

    /**
     * Setup main container
     * @param {HTMLElement} nodeMain 
     */
    #initMainElement(nodeMain){
        nodeMain.classList.toggle("node-main",true);
        nodeMain.setAttribute("oncontextmenu","return false;");

        //event
        nodeMain.addEventListener('mousedown',(e)=>{
            this.#setMouseButton(e.button);
            if(e.button == 0 && e.target.classList != "dropdown-item"){
                this.#hideMenu();
            }
            this.#mouseDown(e);
        });
        nodeMain.addEventListener('mousemove',(e)=>{
            this.#mouseMove(e);
        });
        nodeMain.addEventListener('mouseup',(e)=>{
            this.#mouseUp(e);
        });
        nodeMain.addEventListener('click',(e)=>{
            this.#mouseClick(e);
        });
        nodeMain.addEventListener('wheel', (e) => {
            if(!e.altKey){
                return;
            }
            e.preventDefault();
            this.#zoom(e);
        },true);
    }

    #initDropdown(){

        let menu = document.createElement('div');
        menu.className ="dropdown-menu";
        menu.style.display = "none";
        menu.style.position = "absolute";
        menu.style.top = "0px";
        menu.style.left = "0px";
        menu.style.padding = "5px";
        
        let menuItemMark = document.createElement('a');
        menuItemMark.className ="dropdown-item";
        menuItemMark.innerHTML = `<span class="fas fa-flag" style="font-size:14px; color: #707070;"></span><p style="margin: 0;margin-left: 22px;pointer-events: none;">Mark as start</p>`;
        menuItemMark.addEventListener('click',e=>{
            let node = this.#actionData.selectItem.target;
            if(node != null && node.getAttribute("data-name") == "node"){
                this.toggleMark(node.id);
            }
            this.#hideMenu();
        });
        menu.append(menuItemMark);
        this.#nodeMain.append(menu);
        return menu;
    }

    #initPopupSelect(){
        let popup = document.createElement("div");
        popup.id = this.#popupSelectFormId;
        popup.className = "modal fade";
        popup.setAttribute("data-bs-keyboard",false);
        popup.setAttribute("data-bs-backdrop","static");
        popup.innerHTML = `<div class="modal-dialog modal-dialog-centered" role="document" style="max-width: 500px">
                                <div class="modal-content position-relative">
                                    <div class="position-absolute top-0 end-0 mt-2 me-2 z-index-1">
                                        <button class="btn-close btn btn-sm btn-circle d-flex flex-center transition-base" data-bs-dismiss="modal" aria-label="Close"></button>
                                    </div>
                                    <div class="modal-body p-0">
                                        <div class="rounded-top-lg py-3 ps-4 pe-6 bg-light">
                                            <h4 class="mb-1" id="#">${this.#trans.popup_connect_title}</h4>
                                        </div>
                                        <div class="p-3 pb-0">
                                            <div class="d-flex mb-3">
                                                <div class="me-3">
                                                    <label class="form-label">Idenfity:</label>
                                                    <input class="form-control" style="width: 100px;" name="idenfity-step" type="number"/>
                                                </div>
                                                <div class="">
                                                    <label class="form-label">Status result:</label>
                                                   
                                                    <select class="form-control form-select" name="idenfity-result">
                                                        <option value="" ></option>
                                                        <option value="created" >created</option>
                                                        <option value="updated" >updated</option>
                                                        <option value="assign" >assign</option>
                                                        <option value="pending" >pending</option>
                                                        <option value="approved" >approved</option>
                                                        <option value="rejected" >rejected</option>
                                                        <option value="finished" >finished</option>
                                                        <option value="stoped" >stoped</option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="mb-3">
                                                <label class="form-label">Status:</label>
                                                <input class="form-control" name="status"/>
                                            </div>
                                            <label class="form-label" >Form:</label>
                                            <div id="popup-body"></div>
                                        </div>
                                    </div>
                                    <div class="modal-footer">
                                        <button class="btn btn-secondary" id="close" type="button" data-bs-dismiss="modal">${this.#trans.cancel}</button>
                                        <button class="btn btn-danger" id="delete" type="button" data-bs-dismiss="modal">${this.#trans.delete}</button>
                                        <button class="btn btn-primary" id="confirm" type="button">${this.#trans.confirm}</button>
                                    </div>
                                </div>
                            </div>`;
        this.#nodeMain.append(popup);
    }

    /**
     * Open select forms
     * @param {Object} data
     * @param {Function} callback 
     */
    #openSelectPopupForm(data,callback){
        let dialog = $('#'+this.#popupSelectFormId);
        let body = dialog.find("#popup-body");
        body.html("");

        // render data
        let html_data = "";
        this.#formsLabelList.forEach((item,index)=>{
            html_data += `<div class="form-check">
                                <input class="form-check-input" style="cursor: pointer;"id="select-form-${index}" type="radio" name="forms"
                                    value="${item.value}" ${data.forms == item.value ? "checked" : ""} />
                                <label style="cursor: pointer;" class="form-check-label" for="select-form-${index}">${item.name}</label>
                            </div>`});
        body.html(html_data);

        // status input
        dialog.find(`[name="status"]`).val(data.status != "undefined" ? data.status : "");
        
        let idenfity = data.idenfity.split("-");
        dialog.find(`[name="idenfity-step"]`).val(idenfity[0] || "");
        dialog.find(`[name="idenfity-result"]`).val(idenfity[1] || "");

        // show popup
        dialog.modal('show');

        dialog.find("#close").off().on('click',()=>{
            callback(false,null);
            dialog.modal('hide');
        });

        dialog.find("#confirm").off().on('click',()=>{
            let playload = {};
            playload.forms = dialog.find('input[name="forms"]:checked').val();
            playload.status = dialog.find('input[name="status"]').val();
            playload.idenfity = dialog.find('input[name="idenfity-step"]').val() + "-" + dialog.find('select[name="idenfity-result"]').val();
            callback(true,playload);
            dialog.modal('hide');
        });

        dialog.find("#delete").off().on('click',()=>{
            callback(true,"");
            dialog.modal('hide');
        });
    }

    /**
     * Create container of nodes
     * @returns {HTMLElement}
     */
     #createNodeContainer(){
        let container = document.createElement('div');
        container.id = "node-container";
        container.className = 'node-container grid-line';
        return container;
    }

    #createPreviewArrow(){
        
        let svg = document.createElementNS(this.#xmlns, "svg");
        svg.id = "svg-preview-arrow";
        svg.setAttributeNS(null, "width", 1);
        svg.setAttributeNS(null, "height", 1);
        svg.setAttribute("style",`left:${-1}px; top:${-1}px;`);
        svg.setAttribute("class",'arrow-preview');
        svg.innerHTML = `<defs>
                            <marker id="preview-path-mark-end" markerUnits="userSpaceOnUse" markerWidth="13" markerHeight="13" refx="10" refy="6.2" orient="auto">
                            <path d="M2,2 L2,11 L10,6 L2,2" style="fill:black;" />
                            </marker>
                        </defs>`;

        let pathElement = document.createElementNS(this.#xmlns, 'path');

        pathElement.setAttribute("d","M0 0 L 1 1");
        pathElement.style.fill = "none";
        pathElement.style.strokeWidth = 1;

        // stoke style
        pathElement.style.stroke = "black";
        pathElement.style.markerEnd = "url(#preview-path-mark-end)";
        pathElement.style.strokeDasharray = "6";
        svg.append(pathElement);

        this.#previewArrow = svg;
        this.#previewPath = pathElement;

        this.#nodeContainer.append(this.#previewArrow);
    }
    
    #createSelectArea(){

        let svg = document.createElementNS(this.#xmlns, "svg");
        svg.id = "svg-select-area";
        svg.setAttribute("class",'arrow-preview');
        svg.setAttribute("style", "top: 0px;left: 0px");

        let rect = document.createElementNS(this.#xmlns, "rect");
        rect.setAttribute("width", 100);
        rect.setAttribute("height", 100);
        rect.setAttribute("style", "fill: #0067ff4d;stroke-width:2;stroke:rgb(0,120,215);");

        svg.append(rect);
        this.#SelectAreaSVG = svg;
        this.#SelectAreaPath = rect;
        this.#nodeContainer.append(this.#SelectAreaSVG);

    }

    /**
     * Update arrow preview: call when mouse down node points
     * @param {String} startId 
     * @param {String} startDirect 
     * @param {boolean} drawNew 
     */
    #updatePreviewArrow(startId,startDirect,drawNew,arrowId = null){
        let startElement = this.#nodeContainer.querySelector("#" + startId);
        let startPos =  this.#getPointPosByDirect(startElement,startDirect);

        // svg pos
        let svgLeft = startPos.x;
        let svgTop =  startPos.y;
        this.#previewArrow.setAttribute("style",`left:${svgLeft}px; top:${svgTop}px;`);
        this.#previewInfo.startPos = startPos;
        this.#previewInfo.offset = {x:svgLeft,y:svgTop};
        this.#previewInfo.startId = startId;
        this.#previewInfo.startDirect = startDirect.split("-")[0];
        this.#previewInfo.drawNew = drawNew;
        this.#previewInfo.currentArrow = arrowId;
    }

    /**
     * Update arrow preview: call when drag connect
     * @param {MouseEvent} e
     */
    #updatePreviewPath(e){
        let startPos = {
            x:this.#previewInfo.startPos.x,
            y:this.#previewInfo.startPos.y
        }
        let mainRect = this.#nodeMain.getBoundingClientRect();
        
        let endPos = {
            x: e.x - mainRect.x - this.#nodeContainer.offsetLeft,
            y: e.y - mainRect.y - this.#nodeContainer.offsetTop,
        };
        
        // fix scroll
        endPos.x += this.#nodeMain.scrollLeft;
        endPos.y += this.#nodeMain.scrollTop;

        // fixed with grid
        endPos = this.#getPosInGrid(endPos.x,endPos.y,this.#GRID_UNIT);
        let rect_end = {
            top:endPos.y,
            left:endPos.x ,
            right:endPos.x + 10,
            bottom: endPos.y + 10
        }
        
        let startElement = this.#nodeContainer.querySelector("#" +this.#previewInfo.startId);
        let rect_start = this.#getElementRect(startElement);
        let rect_check = {
            top:rect_start.top - this.#PREAK_LENGTH,
            left: rect_start.left - this.#PREAK_LENGTH,
            right: rect_start.right + this.#PREAK_LENGTH,
            bottom: rect_start.bottom + this.#PREAK_LENGTH,
        };

        // direct end
        let endDirect = e.target.getAttribute("data-direct");

        if(this.#isPointInRect(endPos,rect_check) && !endDirect){
            return;
        }

        if(endDirect){
            rect_end = this.#getElementRect(e.target.parentElement);
        }else{
            if(endPos.y <= rect_start.top){
                endDirect = this.#DOWN;
            }else if(endPos.y >= rect_start.bottom){
                endDirect = this.#UP;
            }else if(endPos.x >= rect_start.right){
                endDirect = this.#LEFT;
            }else{
                endDirect = this.#RIGHT;
            }
        }

        let arr_paths = this.#buildPath(startPos,endPos,this.#previewInfo.startDirect,endDirect,rect_start,rect_end,this.#PREAK_LENGTH,this.#GRID_UNIT/2);
        let path_string = this.#convertArrayPathToString(arr_paths,this.#previewInfo.offset.x,this.#previewInfo.offset.y);

        this.#previewArrow.style.opacity = 0.8;
        this.#previewPath.setAttribute("d",path_string);
    }

    #resetPreviewArrow(){
        this.#previewArrow.style.opacity = 0;
        this.#previewPath.setAttribute("d","M0 0 L 1 1");
    }

    /**
     * Update select area: call when drag connect
     * @param {MouseEvent} e
     */
    #updateSelectArea(e){

        let mainRect = this.#nodeContainer.getBoundingClientRect();
        let endPos = {
            x:e.x - mainRect.x,
            y:e.y - mainRect.y
        }

        let startPos = {x:this.#selectAreaInfo.startPos.x,y:this.#selectAreaInfo.startPos.y};

        // calc size
        let width = Math.abs(startPos.x - endPos.x);
        let height = Math.abs(startPos.y - endPos.y);

        // calc pos
        let pos = {
            x: startPos.x < endPos.x ? startPos.x : endPos.x,
            y: startPos.y < endPos.y ? startPos.y : endPos.y
        }

        this.#SelectAreaSVG.setAttribute("style", `top: ${pos.y}px;left: ${pos.x}px`);
        this.#SelectAreaPath.setAttribute("width", width);
        this.#SelectAreaPath.setAttribute("height", height);
        this.#SelectAreaSVG.style.opacity = 0.5;

    }

    /**
     * 
     * @param {MouseEvent} e
     */
    #getSelectAreaElement(e){
        let mainRect = this.#nodeContainer.getBoundingClientRect();
        let endPos = {
            x:e.x - mainRect.x,
            y:e.y - mainRect.y
        }
        let startPos = this.#selectAreaInfo.startPos;

        if(startPos.x > endPos.x){
            let temp = {x:startPos.x,y:startPos.y};
            startPos = {x:endPos.x,y:endPos.y};
            endPos = temp;
        }
        // get list node
        this.#listNodes.forEach(node=>{
            let nodestart = {x:parseInt(node.pos.x),y:parseInt(node.pos.y)};
            let nodeend= {x:parseInt(node.pos.x) + parseInt(node.size.width),y:parseInt(node.pos.y) + parseInt(node.size.height)};
            if (nodestart.x >= startPos.x && nodestart.y >= startPos.y
                && nodeend.x <= endPos.x && nodeend.y <= endPos.y){
                node.element.classList.toggle(this.#selectClass,true);
            }else if (!this.#isKeyHold("Control")){
                node.element.classList.toggle(this.#selectClass,false);
            }
        })
    }

    #resetSelectArea(){
        this.#SelectAreaSVG.setAttribute("style", `top: 0px;left: 0px`);
        this.#SelectAreaSVG.style.opacity = 0;
        this.#SelectAreaPath.setAttribute("width", 0);
        this.#SelectAreaPath.setAttribute("height", 0);
    }

    /**
     * Main mouse down
     * @param {MouseEvent} e 
     */
    #mouseDown(e){
        this.#bMousedown = true;
        this.#actionData.act_target = e.target;

        // moving  node container
        if(e.target == this.#nodeMain){
            if(e.button == 2 ){
                this.#setAction(this.#MOVING_CONTAINER_ACT);
                this.#actionData.act_target = this.#nodeContainer
                this.#getActionMouseOffset(this.#nodeContainer,e);
            }else if(e.button == 0){
                // clear select connect
                if(this.#actionData.selectItem.target != null){
                    this.#clearSelectConnect();
                }
                this.#setAction(this.#DRAW_SELECT_AREA_ACT);
                let mainRect = this.#nodeContainer.getBoundingClientRect();
                this.#selectAreaInfo.startPos = {
                    x:e.x - mainRect.x,
                    y:e.y - mainRect.y
                }
            }
            return;
        }
        else if(e.button == 0){
            // moving node
            if(e.target.getAttribute("data-name") == "node"){
                this.#getActionMouseOffset(this.#actionData.act_target,e);
                this.#actionData.act_target = e.target;
                return;
            }
            // resize node
            if(e.target.getAttribute("data-act") == "resize"){
                // get action data
                this.#setAction(this.#RESIZE_NODE_ACT);
                let direction =  e.target.getAttribute("data-resize");
                let target = e.target.parentElement;

                this.#actionData.resize.direction = direction;
                this.#actionData.resize.currSize =  target.getBoundingClientRect();
                this.#actionData.resize.target = target;
                this.#actionData.resize.currMouse = {x:e.x, y :e.y};
                return;
            }
            // draw arrow
            if(e.target.getAttribute("data-name") == "node-direct"){
                this.#setAction(this.#DRAW_ARROW_ACT);

                this.#actionData.act_target = e.target;
                // GET START INFO
                let direct = e.target.getAttribute("data-direct");
                let nodeId = e.target.parentElement.id;

                this.#actionData.drawArrow.start.direct = direct;
                this.#actionData.drawArrow.start.id = nodeId;
                this.#actionData.drawArrow.forms = null;
                this.#actionData.drawArrow.status = null;
                this.#updatePreviewArrow(nodeId,direct,true,null);

                return;
            }

            // moving arrow
            if(e.target.getAttribute('data-parent') == 'moving-button' || e.target.getAttribute('data-name') == 'moving-button'){
                this.#setAction(this.#DRAW_ARROW_ACT);
                let arrowId = e.target.parentElement.getAttribute('data-id');
                let arrow = this.#listConnects.find(connect=>connect.id == arrowId);
                let direct = arrow.start_direct;
                let nodeId = arrow.start_id;

                // for draw
                this.#actionData.drawArrow.forms = arrow.forms;
                this.#actionData.drawArrow.forms = arrow.status;
                this.#actionData.drawArrow.start.direct = direct;
                this.#actionData.drawArrow.start.id = nodeId;

                this.#updatePreviewArrow(nodeId,direct,false,arrowId);
                return;
            }
        }
    }

    /**
     * Main mouse move
     * @param {MouseEvent} e 
     */
    #mouseMove(e){
        
        if(this.#isMouseDown() && this.#getMouseButton() == 0){
            switch(this.#getCurrAction()){
                case this.#DRAW_SELECT_AREA_ACT:
                    this.#updateSelectArea(e);
                    break;
                case this.#RESIZE_NODE_ACT:
                    this.#resizeNode(e);
                    break;
                case this.#MOVING_ARROW_PATH_ACT:
                    this.#moveArrowPath(e);
                    break;
                case this.#DRAW_ARROW_ACT:
                    this.#updatePreviewPath(e);
                    break;
                default:
                    // moving node
                    if(this.#actionData.act_target && this.#actionData.act_target.getAttribute("data-name") == "node"){
                        this.#setAction(this.#MOVING_NODE_ACT);
                        this.#moveNode(e,true);
                        this.#updateNodeConnects(e.target.id);
                        this.#actionData.act_target.classList.toggle("node-grab",true);
                    }
                    break;
            }

        }else{
            switch(this.#getCurrAction()){
                case this.#MOVING_CONTAINER_ACT:
                    if(this.#getMouseButton() == 2){
                        // moving container
                    }
                    break;
            }
        }

        // get current mouse
        this.#actionData.curr_mouse = this.#getPosInGrid(e.offsetX - this.#nodeContainer.offsetLeft,e.offsetY - this.#nodeContainer.offsetTop,this.#GRID_UNIT);
    }

    /**
     * Main mouse up
     * @param {MouseEvent} e
     */
    #mouseUp(e){

        if(this.#checkCurrAction(this.#DRAW_ARROW_ACT)){
            if(e.target.getAttribute("data-name") == "node-direct"){
                if(!this.#previewInfo.drawNew){
                    let arrowId = this.#previewInfo.currentArrow;
                    this.#removeConnect(arrowId);
                }
                let sPath = this.#previewPath.getAttribute("d");
                this.#drawNewArrow(e,sPath,!this.#previewInfo.drawNew);
            }
            this.#resetPreviewArrow();
        }else if(this.#checkCurrAction(this.#MOVING_ARROW_PATH_ACT)){

            let path = this.#actionData.movingPath.path;
            let areaArrow = this.#actionData.movingPath.areaArrow;
            let arr_paths = this.#actionData.movingPath.arr_paths;
            let connectId = this.#actionData.movingPath.connectId;
            let svg = path.parentElement;
            let check_point = {x:arr_paths[2].x,y:arr_paths[2].y};
            let check_direct = check_point.x == arr_paths[3].x ? "x" : "y";

            for (let i = 3; i < arr_paths.length - 3; i++) {

                const point = {x:arr_paths[i].x,y:arr_paths[i].y}
                let nextIndex = i+1;
                const nextPoint = {x:arr_paths[nextIndex].x,y:arr_paths[nextIndex].y};
                
                // check
                if(check_point[check_direct] == point[check_direct]){
                    // can remove
                    if(check_point[check_direct] == nextPoint[check_direct]){
                        arr_paths.splice(i, 1);
                        i--;
                        continue;
                    }
                    // when turn
                    else{
                        check_point = {x:point.x,y:point.y};
                        check_direct = check_direct == "x" ? "y" : "x";
                        continue;
                    }
                }
            }

            // fix: perk start not remove duplicate
            if((arr_paths[1].x == arr_paths[2].x && arr_paths[1].y == arr_paths[2].y)
                && (arr_paths[2].x == arr_paths[3].x && arr_paths[2].y == arr_paths[3].y)){
                arr_paths.splice(1, 1);
            }

            this.#rebuildMidPointButton(connectId,svg,path,areaArrow,arr_paths);
        }else if(this.#checkCurrAction(this.#MOVING_NODE_ACT)){
            this.#actionData.act_target.classList.toggle("node-grab",false);
        }else if(this.#checkCurrAction(this.#DRAW_SELECT_AREA_ACT)){
            this.#getSelectAreaElement(e);
            this.#resetSelectArea();
        }

        // clear act data
        this.#clearActData();
    }

    /**
     * Main mouse click
     * @param {MouseEvent} e
     */
    #mouseClick(e){
       
    }

    /**
     * Draw new connect from drag arrow action
     * @param {MouseEvent} e data-name
     * @param {string} sPath string path
     * @param {boolean} bUpdate string path
     */
    #drawNewArrow(e,sPath,bUpdate){
        // valid point : it self
        if( e.target == this.#actionData.act_target){
            this.#clearActData();
            return;
        }

        // valid point : same parent
        // if( e.target.parentElement == this.#actionData.act_target.parentElement){
        //     this.#clearActData();
        //     return;
        // }

        let start_id = this.#actionData.drawArrow.start.id;
        let end_id = e.target.parentElement.id;
        let end_direct = e.target.getAttribute("data-direct");
        let start_direct = this.#actionData.drawArrow.start.direct;
        let forms = this.#actionData.drawArrow.forms;
        let connectData = this.#createConnect(start_id,start_direct,end_id,end_direct,null,sPath,this.#controlData.arrowType,this.#controlData.arrowMarkEnd,this.#controlData.arrowColor,forms);
        if(connectData){
            this.#listConnects.push({
                id:connectData.svg.id,
                element:connectData.svg,
                forms:forms,
                start_id:start_id,
                start_direct:start_direct,
                end_id:end_id,
                end_direct:end_direct,
                path:connectData.path,
                midPoints:connectData.midPoints,
                areaArrow:connectData.areaArrow,
                connect_type:this.#controlData.arrowType,
                color:this.#controlData.arrowColor,
                mark_end:this.#controlData.arrowMarkEnd
            });
        }

        if(bUpdate){
            // let selectPath = connectData.svg.querySelector(".select-path");

            connectData.path.style.strokeWidth = 1.25;
            connectData.svg.classList.toggle("hover-show",false);
            this.#clearSelectConnect();
            this.#setSelectConnect(connectData.svg);
        }
    }

    /**
     * Clear action data
     */
    #clearActData(){
        this.#bMousedown = false;
        this.#setMouseButton(null);
        this.#setAction(this.#NONE_ACT);
    }

    /**
     * Set action
     * @param {String} action
     */
    #setAction(action){
        this.#actionData.curr_action = action;
    }

    /**
     * Set button of mouse down event
     * @param {Number | Null} button 
     */
    #setMouseButton(button){
        this.#mouseButton = button;
    }

    /**
     * Get mouse down event button: 0-left | 1-middle | 2-right
     * @returns {Number | Null}
     */
    #getMouseButton(){
      return this.#mouseButton;
    }

    /**
     * Check current action name
     * @param {String} action 
     * @returns {Boolean}
     */
    #checkCurrAction(action){
        return this.#actionData.curr_action == action;
    }

    /**
     * Get current action name
     * @returns {String} Current action
     */
    #getCurrAction(){
        return this.#actionData.curr_action;
    }

    /**
     * Get mouse status
     * @returns {Boolean}
     */
    #isMouseDown(){
        return this.#bMousedown;
    }

    /**
     * Zoom
     * @param {MouseEvent} e
     */
    #zoom(e){
        this.#curr_zoom = e.deltaY < 0 ? this.#curr_zoom += this.#zoom_step : this.#curr_zoom -= this.#zoom_step;
        this.#nodeContainer.style.zoom = this.#curr_zoom;
        this.#fireEvent(this.#EVENT_ZOOM,this.#curr_zoom);
    }

    /**
     * Move path of arrow
     * @param {MouseEvent} e 
     */
    #moveArrowPath(e){
        let path = this.#actionData.movingPath.path;
        let areaArrow = this.#actionData.movingPath.areaArrow;
        let arr_paths = this.#actionData.movingPath.arr_paths;
        let direct = this.#actionData.movingPath.direct;
        let connectId = this.#actionData.movingPath.connectId;
        // get points
        let p1_index = this.#actionData.movingPath.p1Index;
        let p2_index = this.#actionData.movingPath.p2Index;
        let pos = {
            x:e.clientX + this.#actionData.mouseOffset.x + this.#actionData.movingPath.offset.x,
            y:e.clientY + this.#actionData.mouseOffset.y + this.#actionData.movingPath.offset.y
        }
        pos = this.#getPosInGrid(pos.x,pos.y,this.#GRID_UNIT);

        // move points
        arr_paths[p1_index][direct] = pos[direct];
        arr_paths[p2_index][direct] = pos[direct];

        // check start_peak
        if(arr_paths[1].x != arr_paths[2].x || arr_paths[1].y != arr_paths[2].y){
            arr_paths.splice(1,0,{x:arr_paths[1].x,y:arr_paths[1].y});
            this.#actionData.movingPath.p1Index += 1;
            this.#actionData.movingPath.p2Index += 1;
        }
        //check end_peak
        if(arr_paths[arr_paths.length - 2].x != arr_paths[arr_paths.length - 3].x || arr_paths[arr_paths.length - 2].y != arr_paths[arr_paths.length - 3].y){
            arr_paths.splice(arr_paths.length - 1,0,{x:arr_paths[arr_paths.length - 2].x,y:arr_paths[arr_paths.length - 2].y});
        }

        // update
        let svg = path.parentElement;
        this.#rebuildMidPointButton(connectId,svg,path,areaArrow,arr_paths);

    }

    /**
     * Rebuild all mid point button
     * @param {String} connectId 
     * @param {Element} svg 
     * @param {Element} path 
     * @param {Element} areaArrow 
     * @param {Array} arr_paths 
     */
    #rebuildMidPointButton(connectId,svg,path,areaArrow,arr_paths){

        // clear old buttons
        this.#listConnects.forEach(connect=>{
            if(connect.id == connectId){
                connect.midPoints.forEach(midPoint=>{
                    midPoint.remove();
                });
                connect.midPoints = [];
            }
        });

        // create buttons
        let arr_midPoints = this.#getMidPointsFromPath(arr_paths);
        let arr_midPointButton = this.#createMidPointButton(connectId,arr_midPoints,this.#actionData.movingPath.offset.x,this.#actionData.movingPath.offset.y,path,areaArrow,arr_paths);
        arr_midPointButton.forEach(control=>{
            svg.append(control);
        })

        // store
        this.#listConnects.forEach(connect=>{
            if(connect.id == connectId){
                // create mid point
                connect.midPoints = arr_midPointButton;
            }
        });

        // reload element path d
        let pathString = this.#convertArrayPathToString(arr_paths,this.#actionData.movingPath.offset.x,this.#actionData.movingPath.offset.y);
        path.setAttribute("d",pathString);
        areaArrow.setAttribute("d",pathString);

        // moving label
        let svgLeft = this.#actionData.movingPath.offset.x;
        let svgTop = this.#actionData.movingPath.offset.y;
        this.#updateConnectLabelPos(svg,arr_midPoints,svgLeft,svgTop);
    }

    /**
     * Move node
     * @param {MouseEvent} e 
     * @param {Boolean} limit keep element in grid view 
     */
    #moveNode(e,limit = false){

        let deltaX,deltaY = 0;
        let pos = {
            x:e.clientX + this.#actionData.mouseOffset.x,
            y:e.clientY + this.#actionData.mouseOffset.y
        }

        pos = this.#getPosInGrid(pos.x,pos.y,this.#GRID_UNIT);

        if(limit && (pos.x < 0 || pos.y < 0)){
            return;
        }

        if(this.#actionData.act_target.getAttribute("data-name") == "node"){
            this.#actionData.act_target.style.left = pos.x + "px";
            this.#actionData.act_target.style.top = pos.y + "px";
            this.#updateNodeConnects(this.#actionData.act_target.id);
            // store node target info
            this.#listNodes.forEach(node=>{
                if(node.id == this.#actionData.act_target.id){
                    deltaX = pos.x - node.pos.x;
                    deltaY = pos.y - node.pos.y;
                    node.pos = {
                        x:pos.x,
                        y:pos.y
                    }
                }
            });
            // moving other select nodes
            this.#listNodes.forEach(node=>{
                if(node.element.classList.contains(this.#selectClass) && node.id != this.#actionData.act_target.id){
                    let newpos = {x:parseInt(node.pos.x) + deltaX,y:parseInt(node.pos.y) + deltaY}
                    this.#updateNodeConnects(node.id);
                    node.element.style.left = newpos.x + "px";
                    node.element.style.top = newpos.y + "px";
                    node.pos = {
                        x:newpos.x,
                        y:newpos.y
                    }
                }
            });
        }

    }

    /**
     * Create connect (svg arrow)
     * @param {String} startId 
     * @param {String} startDirect 
     * @param {String} endId 
     * @param {String} endDirect 
     * @param {[{x:Number,y:Number}]} arr_paths 
     * @param {String} path_string 
     * @param {String} connect_type 
     * @param {String} mark_end 
     * @param {Boolean} color 
     * @param {String} forms 
     * @param {String} status 
     * @param {String} idenfity 
     * @returns {{svg:Element,path:Element,midPoints:[]}} paths data
     */
    #createConnect(startId,startDirect,endId,endDirect,arr_paths = null,path_string = null,connect_type,mark_end,color,forms = null,status = null,idenfity = null){

        let bFindPath = arr_paths != null ? false : true;

        let startElement = this.#nodeContainer.querySelector("#" + startId);
        let endElement = this.#nodeContainer.querySelector("#" + endId);

        if(!startElement || !endElement){
            return null;
        }

        let startPos =  this.#getPointPosByDirect(startElement,startDirect);
        let endPos = this.#getPointPosByDirect(endElement,endDirect);
        let rect_start = this.#getElementRect(startElement);
        let rect_end = this.#getElementRect(endElement);

        // svg pos
        let svgTop =  startPos.y < endPos.y ? startPos.y : endPos.y;
        let svgLeft = startPos.x < endPos.x ? startPos.x : endPos.x;

        // CREATE VSG
        let id = "connect-"+ Date.now() + this.#randomInt(20,15) + this.#randomInt(67,900);
        // check id
        while(this.#listConnects.includes(connect=>connect.id == id)){
            id = "connect-"+ Date.now() +this.#randomInt(20,15) + this.#randomInt(67,900);
        }

        let svg = document.createElementNS(this.#xmlns, "svg");
        let mark_end_id = "end" + id;
        svg.id = id;
        svg.setAttributeNS(null, "width", Math.abs(endPos.x - startPos.x));
        svg.setAttributeNS(null, "height", Math.abs(endPos.y - startPos.y));
        svg.setAttribute("style",`left:${svgLeft}px; top:${svgTop}px;`);
        svg.setAttribute("class",'arrow');
        svg.innerHTML = `<defs>
                            <marker id="${mark_end_id}" markerUnits="userSpaceOnUse" markerWidth="13" markerHeight="13" refx="10" refy="6.2" orient="auto">
                            <path d="M2,2 L2,11 L10,6 L2,2" style="fill:${color};" />
                            </marker>
                        </defs>`;

        if(bFindPath){
            arr_paths = this.#buildPath(startPos,endPos,startDirect,endDirect,rect_start,rect_end,this.#PREAK_LENGTH,this.#GRID_UNIT/2);
            path_string = this.#convertArrayPathToString(arr_paths,svgLeft,svgTop);
        }else{
            arr_paths.forEach(path=>{
                path.x = path.x + svgLeft;
                path.y = path.y + svgTop;
            })
        }

        // CREATE ARROW
        let arrowPath = this.#createArrowPathElement(path_string,connect_type,mark_end,mark_end_id,color);
        svg.append(arrowPath);

        // CREATE SELECT AREA ARROW
        let areaArrow = this.#createArrowSelectArea(path_string);
        areaArrow.addEventListener('mouseenter',(e)=>{
            if (this.#actionData.selectItem.target != svg){
                arrowPath.style.strokeWidth = 3;
                svg.classList.toggle("hover-show",true);
            }
        });
        areaArrow.addEventListener('mouseleave',(e)=>{
            if (this.#actionData.selectItem.target != svg){
                arrowPath.style.strokeWidth = 1.25;
                svg.classList.toggle("hover-show",false);
            }
        });

        areaArrow.addEventListener('click',(e)=>{
            arrowPath.style.strokeWidth = 1.25;
            svg.classList.toggle("hover-show",false);
            // clear selected nodes
            this.#listNodes.forEach(node=>{
                node.element.classList.toggle(this.#selectClass,false);
            });
            this.#clearSelectConnect();
            this.#setSelectConnect(svg);

            this.#fireEvent(this.#EVENT_CHANGE_FORCUS,this.#rgbToHex(arrowPath.style.stroke));
        });
        
        // CREATE CENTER CONTROLS
        let arr_center = this.#getMidPointsFromPath(arr_paths);
        let arr_moveControls = this.#createMidPointButton(id,arr_center,svgLeft,svgTop,arrowPath,areaArrow,[...arr_paths]);
        arr_moveControls.forEach(control=>{
            svg.append(control);
        })

        // CREATE REMOVE ICON
        let removeIcon = this.#createButtonRemoveSvg("remove-button",this.#REMOVE_ICON_PATH,25,"#f72929",2,'button-svg');
        removeIcon.setAttribute("x",arr_paths[1].x - svgLeft);
        removeIcon.setAttribute("y",arr_paths[1].y - svgTop);
        removeIcon.addEventListener('click',(e)=>{
            this.#removeConnect(id);
        })
        svg.append(removeIcon);

        // CREATE LINK LABEL
        let label = this.#createConnectLabel(svg,arr_paths,svgLeft,svgTop,forms,status,idenfity);
        svg.append(label);

        // CREATE MOVING ARROW
        let movingButton = this.#createButtonRemoveSvg("moving-button",this.#REMOVE_ICON_PATH,26,"#01bd22",2,'button-svg moving-arrow-button');
        movingButton.setAttribute("x",arr_paths[arr_paths.length - 1].x - svgLeft);
        movingButton.setAttribute("y",arr_paths[arr_paths.length - 1].y - svgTop);
        movingButton.setAttribute('data-id',id);
        svg.append(movingButton);
        
        this.#nodeContainer.append(svg);
        svg.append(areaArrow);
        
        return {
            svg:svg, // svg component
            path:arrowPath, // path element
            areaArrow:areaArrow,
            midPoints:[...arr_moveControls], // center element
        };
    }

    /**
     * Create remove button
     * @param {String} id 
     * @param {String} path_string 
     * @param {{x:Number,y:Number}} pos 
     * @param {Number} size
     * @param {String} fill_color
     * @param {Number} strokeWidth 
     * @param {String} className 
     * @returns {Element}
     */
    #createButtonRemoveSvg(id,path_string,size,fill_color,strokeWidth,className){
        
        let svg = document.createElementNS(this.#xmlns, "svg");
        svg.id = id;
        svg.setAttributeNS(null, "width", 2);
        svg.setAttributeNS(null, "height", 2);
        svg.setAttribute('class',className);
        svg.setAttribute('data-name',id);

        let background = document.createElementNS(this.#xmlns, 'path');
        background.setAttribute('d',this.#CIRCLE_PATH);
        background.setAttribute('x',0);
        background.setAttribute('y',0);
        background.style.scale = 1;
        background.setAttribute('fill',fill_color);
        background.setAttribute('stroke-width',strokeWidth);
        background.setAttribute('stroke',"white");
        background.setAttribute('class','scale-background');
        background.setAttribute('data-parent',id);

        let icon = document.createElementNS(this.#xmlns, 'path');
        icon.setAttribute("d",path_string);
        
        icon.style.fill = 'white';
        icon.style.scale = 0.7;
        icon.setAttribute('x', '0');
        icon.setAttribute('y', '0');
        icon.setAttribute('class','scale-path button-path');
        icon.setAttribute('data-parent',id);

        svg.append(background);
        svg.append(icon);
        return svg;
    }

    /**
     * Create Connect Label
     * @param {Element} connectSvg 
     * @param {[]} arr_paths 
     * @param {Number} offsetX 
     * @param {Number} offsetY
     * @param {String} scodeForm 
     * @param {String} status
     * @param {String} idenfity
     * @returns 
     */
    #createConnectLabel(connectSvg,arr_paths,offsetX,offsetY,scodeForm,status,idenfity){
        let text = null;
        if(scodeForm != null){
            this.#formsLabelList.forEach(label=>{
                if (scodeForm == label.value){
                    text = label.name;
                    if(text){
                        text = text.trim();
                    }
                }
            })
        }

        let id_filter_forms = "filte-forms-"+ Date.now() +this.#randomInt(20,15) + this.#randomInt(67,900);
        let id_filter_status = "filter-status-"+ Date.now() +this.#randomInt(20,15) + this.#randomInt(67,900);
        let id_filter_idenfity = "filter-idenfity-"+ Date.now() +this.#randomInt(20,15) + this.#randomInt(67,900);
        let svg = document.createElementNS(this.#xmlns, "svg");
        svg.id = this.#labelId;
        svg.setAttributeNS(null,"x",0);
        svg.setAttributeNS(null,"y",0);
        svg.setAttribute('class','button-svg button-label');
        let inner = `
                    <defs>
                        <filter id="${id_filter_forms}" x="0%" width="100%" y="0%" height="100%">
                            <feFlood flood-color="#FFAA55"/>
                            <feGaussianBlur stdDeviation="2"/>
                            <feComponentTransfer>
                                <feFuncA type="table"tableValues="0 0 0 1"/>
                            </feComponentTransfer>
                            <feComponentTransfer>
                                <feFuncA type="table"tableValues="0 1 1 1 1 1 1 1"/>
                            </feComponentTransfer>
                            <feComposite operator="over" in="SourceGraphic"/>
                        </filter>
                        <filter id="${id_filter_status}" x="0%" width="100%" y="0%" height="100%">
                            <feFlood flood-color="#55baff"/>
                            <feGaussianBlur stdDeviation="2"/>
                            <feComponentTransfer>
                                <feFuncA type="table"tableValues="0 0 0 1"/>
                            </feComponentTransfer>
                            <feComponentTransfer>
                                <feFuncA type="table"tableValues="0 1 1 1 1 1 1 1"/>
                            </feComponentTransfer>
                            <feComposite operator="over" in="SourceGraphic"/>
                        </filter>
                        <filter id="${id_filter_idenfity}" x="0%" width="100%" y="0%" height="100%">
                            <feFlood flood-color="#46bd40"/>
                            <feGaussianBlur stdDeviation="2"/>
                            <feComponentTransfer>
                                <feFuncA type="table"tableValues="0 0 0 1"/>
                            </feComponentTransfer>
                            <feComponentTransfer>
                                <feFuncA type="table"tableValues="0 1 1 1 1 1 1 1"/>
                            </feComponentTransfer>
                            <feComposite operator="over" in="SourceGraphic"/>
                        </filter>
                    </defs>`;

        svg.innerHTML = inner;

        let label_form =  document.createElementNS('http://www.w3.org/2000/svg', 'text');
        label_form.id = this.#labelFormId;
        label_form.setAttributeNS(null,"x",0);
        label_form.setAttributeNS(null,"y",0);
        label_form.setAttributeNS(null,"filter",`url(#${id_filter_forms})`);
        label_form.setAttribute('class','button-svg button-label');
        label_form.setAttribute('style',"font-weight: 600;");
        label_form.setAttribute('data-value',scodeForm);
        label_form.textContent = text ? text : "";
        svg.append(label_form);

        let label_idenfity =  document.createElementNS('http://www.w3.org/2000/svg', 'text');
        label_idenfity.id = this.#labelIdenfityId;
        label_idenfity.setAttributeNS(null,"x",0);
        label_idenfity.setAttributeNS(null,"y",0);
        label_idenfity.setAttributeNS(null,"text-anchor","end");
        label_idenfity.setAttributeNS(null,"filter",`url(#${id_filter_idenfity})`);
        label_idenfity.setAttribute('class','button-svg button-label');
        label_idenfity.setAttribute('style',"font-weight: 600;");
        label_idenfity.setAttribute('data-value',idenfity);
        label_idenfity.textContent = idenfity ? idenfity.split("-").filter(n => n).join("-") : "";
        svg.append(label_idenfity);
        
        let posY = 0;
        if(text){
            posY = -22;
        }
        let label_status =  document.createElementNS('http://www.w3.org/2000/svg', 'text');
        label_status.id = this.#labelStatusId;
        label_status.setAttributeNS(null,"x",0);
        label_status.setAttributeNS(null,"y",posY);
        label_status.setAttributeNS(null,"filter",`url(#${id_filter_status})`);
        label_status.setAttribute('class','button-svg button-label');
        label_status.setAttribute('style',"font-weight: 600;");
        label_status.setAttribute('data-value',status);
        label_status.textContent = status;
        svg.append(label_status);

        let labelButton = this.#createLabelButton(this.#LABEL_ICON_PATH,25);
        svg.append(labelButton);

        //  set button visible base on value emplty or not
        labelButton.classList.toggle("force-hidden",text != null && text != "");

        labelButton.addEventListener('click',(e)=>{
            this.#openEditLabelForm(connectSvg);
        })

        label_form.addEventListener('click',(e)=>{
            this.#openEditLabelForm(connectSvg);
        })

        let center = this.#getPointsCenter(arr_paths[2],arr_paths[3]);
        // fix pos on vetical path
        let newX = parseInt((center.x - offsetX));
        newX = Math.abs(this.#getAngle(arr_paths[2],arr_paths[3])) == 90 ? newX + 10 : newX;
        svg.setAttribute("x",newX);
        svg.setAttribute("y",(center.y - offsetY) - 10);
        
        return svg;
    }

    /**
     * Open edit form
     * @param {Element} connectSvg 
     */
    #openEditLabelForm(connectSvg){
        // get data
        let label = connectSvg.querySelector("#"+this.#labelId);
        let label_forms = label.querySelector("#" + this.#labelFormId);
        let label_status = label.querySelector("#" + this.#labelStatusId);
        let label_idenfity = label.querySelector("#" + this.#labelIdenfityId);
        let forms = label_forms.getAttribute("data-value");
        let status = label_status.getAttribute("data-value");
        let idenfity = label_idenfity.getAttribute("data-value");

        if(status == 'null'){
            status = null;
        }
        if(forms == 'null'){
            forms = null;
        }
        let data = {
            forms: forms,
            status: status,
            idenfity: idenfity,
        }
        this.#openSelectPopupForm(data,(confirm,playload)=>{
            if(confirm){
               this.#updateConnectLabelValue(connectSvg,playload);
            }
        })
    }

    /**
     * Create remove button
     * @param {String} path_string
     * @param {Number} size
     * @returns {HTMLElement}
     */
    #createLabelButton(path_string,size){
    
        let svg = document.createElementNS(this.#xmlns, "svg");
        svg.id = this.#labelButtonId;
        svg.setAttributeNS(null, "width", 2);
        svg.setAttributeNS(null, "height", 2);
        svg.setAttribute('class','button-svg');
        svg.setAttribute('style','pointer-events: all;');
        let background = document.createElementNS(this.#xmlns, 'circle');
        background.setAttribute('r',size/2 - 4);
        background.setAttribute('cx',0);
        background.setAttribute('cy',0);
        background.style.scale = 1;
        background.setAttribute('fill',"#068aff");
        background.setAttribute('stroke-width',1);
        background.setAttribute('stroke',"white");
        background.setAttribute('class','scale-background');

        let icon = document.createElementNS(this.#xmlns, 'path');
        icon.setAttribute("d",path_string);
        
        icon.style.fill = 'white';
        icon.style.scale = 1;
        icon.setAttribute('x', '0');
        icon.setAttribute('y', '0');
        icon.setAttribute('class','button-path');

        svg.append(background);
        svg.append(icon);
        return svg;
    }

    #onClickMovingArrow(arrow_id){
        console.log(arrow_id);
    }

    /**
     * Remove connection
     * @param {String} id 
     */
    #removeConnect(id){
        for (let i = 0; i < this.#listConnects.length; i++) {
            if(this.#listConnects[i].id == id){
                this.#nodeContainer.querySelector("#"+id).remove();
                this.#listConnects.splice(i, 1);
                break;
            }
        }
    }
    
    /**
     * Create arrow path
     * @param {String} path_string 
     * @param {String} stroke_type 
     * @param {Boolean} isDrawEnd 
     * @param {String} mark_end_id 
     * @param {String} color
     * @returns {Element}
     */
    #createArrowPathElement(path_string,stroke_type,isDrawEnd,mark_end_id,color){

        let pathElement = document.createElementNS(this.#xmlns, 'path');

        pathElement.setAttribute("d",path_string);
        pathElement.style.fill = "none";
        pathElement.style.cursor = "pointer";
        pathElement.style.strokeWidth = 1.25;

        // stoke style
        pathElement.style.stroke = color;
        pathElement.style.markerEnd = isDrawEnd ? `url(#${mark_end_id})` : "none";

        if (stroke_type == this.#ARROW_DASH){
            pathElement.style.strokeDasharray = "6";
        }

        return pathElement;
    }

    /**
     * Create arrow select area
     * @param {Element} parent svg element
     * @param {String} path_string 
     * @returns 
     */
    #createArrowSelectArea(path_string){
        let pathElement = document.createElementNS(this.#xmlns, 'path');

        pathElement.setAttribute("d",path_string);
        pathElement.style.fill = "none";
        pathElement.style.cursor = "pointer";
        pathElement.style.strokeWidth = 20;
        pathElement.setAttribute('class', 'select-path');

        return pathElement;
    }

    #setSelectConnect(connect){
        connect.classList.toggle(this.#selectClass,true);
        connect.style.strokeWidth = 3;
        this.#actionData.selectItem.target = connect;
    }
    #clearSelectConnect(){
        if(this.#actionData.selectItem.target != null && this.#actionData.selectItem.target.tagName == "svg"){
            this.#actionData.selectItem.target.classList.toggle(this.#selectClass,false);
            this.#actionData.selectItem.target.style.strokeWidth = 1.25;
            this.#actionData.selectItem.target = null;
        }
    }

    /**
     *  Get pos in grid
     * @param {Number} x
     * @param {Number} y
     * @param {Number} unit grid unit
     * @returns {{x:Number,y:Number}} point fix pos
     */
    #getPosInGrid(x,y,unit){

        let newX = Math.round(x/unit)*unit;
        let newY = Math.round(y/unit)*unit;
        return {
            x:newX,
            y:newY
        }
    }

    /**
     * Get random number
     * @param {Number} min 
     * @param {Number} max 
     * @returns 
     */
    #randomInt(min,max){
        return Math.floor(Math.random() * (max - min + 1)) + min;
     }

    /**
     * Update all connects of node, call when move/resize node
     * @param {String} id node id
     */
    #updateNodeConnects(id){

        this.#listConnects.forEach(connect=>{
            if(connect.start_id == id || connect.end_id == id){
                let svg = document.getElementById(connect.id);
                let path = connect.path;
                let areaArrow = connect.areaArrow;
                connect.midPoints.forEach(midPoint=>{
                    midPoint.remove();
                })
                connect.midPoints = [];
                connect.midPoints = this.#updatePath(svg,path,areaArrow,connect.start_id,connect.start_direct,connect.end_id,connect.end_direct);
            }
        })
    }

    /**
     * Resize node element
     * @param {Element} node 
     * @param {MouseEvent} e 
     */
    #resizeNode(e){
        
        let direction = this.#actionData.resize.direction;
        let mousePos = this.#actionData.resize.currMouse;
        let currSize = this.#actionData.resize.currSize;
        let newMousePos = { x: mousePos.x - e.x , y : mousePos.y - e.y };
        let newSize = {x:  currSize.width - newMousePos.x , y: currSize.height - newMousePos.y };
        
        if(newSize.x <= 20 || newSize.y <= 20){
            return;
        }
        
        newSize = this.#getPosInGrid(newSize.x,newSize.y,this.#GRID_UNIT);

        if(direction == "x"){
            this.#actionData.resize.target.style.width = newSize.x + "px";
        }else if (direction == "y"){
            this.#actionData.resize.target.style.height = newSize.y + "px";
        }else if (direction == "xy"){
            this.#actionData.resize.target.style.width = newSize.x + "px";
            this.#actionData.resize.target.style.height = newSize.y + "px";
        }

        // update node
        this.#updateNodeConnects(this.#actionData.resize.target.id);

        // store node info
        this.#listNodes.forEach(node=>{
            if(node.id == this.#actionData.resize.target.id){
                node.size = {
                    width:newSize.x,
                    height:newSize.y
                }
            }
        });
    }

    /**
     * Remove node
     * @param {String} id
     */
    #removeSelected(){
        for (let i = 0; i < this.#listNodes.length; i++) {
            let element = this.#listNodes[i].element;
            let node_id = this.#listNodes[i].id;
            if(element.classList.contains(this.#selectClass)){
                // Remove connects
                for (let y = 0; y < this.#listConnects.length; y++) {
                    if(this.#listConnects[y].start_id == node_id || this.#listConnects[y].end_id == node_id){
                        this.#nodeContainer.querySelector("#" +this.#listConnects[y].id).remove();
                        this.#listConnects.splice(y, 1);
                        if(this.#listConnects.length == 0){
                            break;
                        }
                        y = -1;
                    }
                }
                // remove node
                element.remove();
                this.#listNodes.splice(i, 1);
                i--;
            }
        }
        // Remove selected connect
        if(this.#actionData.selectItem.target != null && this.#actionData.selectItem.target.tagName == "svg"){
            for (let y = 0; y < this.#listConnects.length; y++) {
                if(this.#actionData.selectItem.target.id ==  this.#listConnects[y].id){
                    this.#listConnects[y].element.remove();
                    this.#listConnects.splice(y, 1);
                    break;
                }
            }
        }
    }

    /**
     * Update arrow path, call when moving/resize node
     * @param {Element} svg 
     * @param {Element} path 
     * @param {Element} areaArrow 
     * @param {String} startId 
     * @param {String} startDirect 
     * @param {String} endId 
     * @param {String} endDirect 
     */
    #updatePath(svg,path,areaArrow,startId,startDirect,endId,endDirect){

        let startElement = this.#nodeContainer.querySelector("#" +startId);
        let endElement = this.#nodeContainer.querySelector("#" +endId);

        let startPos =  this.#getPointPosByDirect(startElement,startDirect);
        let endPos = this.#getPointPosByDirect(endElement,endDirect);

        let rect_start = this.#getElementRect(startElement);
        let rect_end = this.#getElementRect(endElement);

        // svg pos
        let svgTop =  startPos.y < endPos.y ? startPos.y : endPos.y;
        let svgLeft = startPos.x < endPos.x ? startPos.x : endPos.x;

        svg.setAttributeNS(null, "width", Math.abs(endPos.x - startPos.x));
        svg.setAttributeNS(null, "height", Math.abs(endPos.y - startPos.y));
        svg.setAttribute("style",`left:${svgLeft}px; top:${svgTop}px; `);

        let arr_paths = this.#buildPath(startPos,
                                endPos,
                                startDirect,
                                endDirect,
                                rect_start,
                                rect_end,
                                this.#PREAK_LENGTH,this.#GRID_UNIT/2);
        
        let pathString = this.#convertArrayPathToString(arr_paths,svgLeft,svgTop);
        path.setAttribute("d",pathString);
        areaArrow.setAttribute("d",pathString);

        // CREATE CENTER CONTROLS
        let arr_center = this.#getMidPointsFromPath(arr_paths);
        let arr_moveControls = this.#createMidPointButton(svg.id,arr_center,svgLeft,svgTop,path,areaArrow,[...arr_paths]);
        arr_moveControls.forEach(control=>{
            svg.append(control);
        })

        // move button remove
        let remove = svg.querySelector("#remove-button");
        remove.setAttribute("x",arr_paths[1].x - svgLeft);
        remove.setAttribute("y",arr_paths[1].y - svgTop);

        // update moving button
        let moving = svg.querySelector("#moving-button");
        moving.setAttribute("x",arr_paths[arr_paths.length - 1].x - svgLeft);
        moving.setAttribute("y",arr_paths[arr_paths.length - 1].y - svgTop);
        // move label
        this.#updateConnectLabelPos(svg,arr_center,svgLeft,svgTop);

        return arr_moveControls;
    }
    

    /**
     * Find arrow path
     * @param {Object} start 
     * @param {Object} end 
     * @param {String} start_direct
     * @param {Object} rect_start
     * @param {Object} rect_end
     * @param {Number} peak_length
     * @param {Number} step_length
     * @returns {paths:{x:Number,y:Number}} paths data
     */
    #buildPath(start,end,start_direct,end_direct,rect_start,rect_end,peak_length,step_length){

        // get direct
        start_direct = start_direct.split("-")[0];
        end_direct = end_direct.split("-")[0];

        start = this.#fixPos(start);
        end = this.#fixPos(end);
        let curr_turn = start_direct;
        let arr_paths = [];

        // get peak
        let start_peak = this.#getPeak(start,curr_turn,peak_length);
        let end_peak = this.#getPeak(end,end_direct,peak_length);

        // rect wrap
        let width  = Math.abs(end_peak.x - start_peak.x);
        let height = Math.abs(end_peak.y - start_peak.y);
        let top =  start_peak.y < end_peak.y ? start_peak.y : end_peak.y;
        let left = start_peak.x < end_peak.x ? start_peak.x : end_peak.x;
        let rect_wrap = {
            top:top,
            left:left,
            bottom:top + height,
            right:left + width
        };

        // scale rect wrap
        rect_wrap.top = rect_wrap.top >= rect_start.top ? rect_start.top - peak_length : rect_wrap.top;
        rect_wrap.bottom = rect_wrap.bottom <= rect_start.bottom ? rect_start.bottom + peak_length : rect_wrap.bottom;
        rect_wrap.left = rect_wrap.left >= rect_start.left ? rect_start.left - peak_length : rect_wrap.left;
        rect_wrap.right = rect_wrap.right <= rect_start.right ? rect_start.right + peak_length : rect_wrap.right;

        rect_wrap.top = rect_wrap.top >= rect_end.top ? rect_end.top - peak_length : rect_wrap.top;
        rect_wrap.bottom = rect_wrap.bottom <= rect_end.bottom ? rect_end.bottom + peak_length : rect_wrap.bottom;
        rect_wrap.left = rect_wrap.left >= rect_end.left ? rect_end.left - peak_length : rect_wrap.left;
        rect_wrap.right = rect_wrap.right <= rect_end.right ? rect_end.right + peak_length : rect_wrap.right;
        
        // moving until end
        let movePoint = {x:start_peak.x,y:start_peak.y};
        let pointDirect = "";
        let stepDirect = 1;
        let canShort = true;

        let turn_limit = 10;
        let loop_count = 0;
        let turn_store = [];
        turn_store.push(start_direct);
        
        // find another way
        let tryOtherWay = false;
        let tryIndex = 1;
        let tryTurnWay = "";

        // add start
        this.#addPath(arr_paths,{x:start.x,y:start.y});
        this.#addPath(arr_paths,{x:start_peak.x,y:start_peak.y});
        this.#addPath(arr_paths,{x:start_peak.x,y:start_peak.y});

        // debug_view([...arr_paths]);

        while(true){
            loop_count += 1;

            if(tryOtherWay && turn_store.length -1 == tryIndex){
                curr_turn = tryTurnWay;
            }

            // check can go to end 
            if(movePoint.x == end_peak.x || movePoint.y == end_peak.y){
                if(this.#ray_tracing_to_end(movePoint,end_peak,rect_start,rect_end,step_length,movePoint.x == end_peak.x ? "y":"x")){
                    if(!this.#isPointEqual(movePoint,arr_paths[arr_paths.length - 1])){

                        // check short
                        if(canShort && arr_paths.length == 3 && this.#isOppositeDirect(start_direct,end_direct)){
                            let midPointMove = this.#getShortPoint(movePoint,curr_turn,rect_start,rect_end);
                            let midPointEnd = {
                                x:  movePoint.x != end_peak.x ? end_peak.x :  midPointMove.x,
                                y:  movePoint.y != end_peak.y ? end_peak.y :  midPointMove.y
                            }
                            this.#addPath(arr_paths,{x:midPointMove.x,y:midPointMove.y});
                            this.#addPath(arr_paths,midPointEnd);
                        }else{
                            this.#addPath(arr_paths,{x:movePoint.x,y:movePoint.y});
                        }
                    }
                    break;
                }
            }

            // take one step
            this.#movePointTo(movePoint,pointDirect,stepDirect*step_length);

            // check point over border: 
            if(curr_turn == this.#UP && movePoint[pointDirect] < rect_wrap.top ||
                curr_turn == this.#RIGHT && movePoint[pointDirect] > rect_wrap.right ||
                curr_turn == this.#DOWN && movePoint[pointDirect] > rect_wrap.bottom ||
                curr_turn == this.#LEFT && movePoint[pointDirect] < rect_wrap.left){
                
                // get center on touch rect border
                if(arr_paths.length >= 2 && canShort){

                    this.#movePointTo(movePoint,pointDirect,stepDirect*step_length,true);

                        if(!this.#isPointEqual(movePoint,start_peak)){
                            
                            canShort = false;
                            
                            let midPoint = this.#getShortPoint(movePoint,curr_turn,rect_start,rect_end);

                            let next_turn = this.#getNextTurn(midPoint,end_peak,curr_turn);

                            if(!this.#ray_tracing_touch_rect(midPoint,next_turn,rect_wrap,rect_start,rect_end,step_length)){
                                
                                this.#addPath(arr_paths,{x:midPoint.x,y:midPoint.y});
                                movePoint = {x:midPoint.x,y:midPoint.y};
                            }else{
                                this.#movePointTo(movePoint,pointDirect,stepDirect*step_length,true);
                                this.#addPath(arr_paths,{x:movePoint.x,y:movePoint.y})
                            }
                        }
                    
                }else{
                    this.#movePointTo(movePoint,pointDirect,stepDirect*step_length,true);
                    this.#addPath(arr_paths,{x:movePoint.x,y:movePoint.y});
                }

                // get to end
                if(movePoint.x == end_peak.x && movePoint.y == end_peak.y){
                    break;
                }
                // get next direct
                curr_turn = this.#getNextTurn(movePoint,end_peak,curr_turn);
                turn_store.push(curr_turn);
            }
            // check element collision
            else if(this.#isPointInRect(movePoint,rect_start) || this.#isPointInRect(movePoint,rect_end)){

                if(canShort){
                    canShort = false;

                    let midPoint = this.#getShortPoint(movePoint,curr_turn,rect_start,rect_end);

                    movePoint = {x:midPoint.x,y:midPoint.y};
                    this.#addPath(arr_paths,{x:midPoint.x,y:midPoint.y});
                    curr_turn = this.#getNextTurn(movePoint,end_peak,curr_turn);
                    turn_store.push(curr_turn);

                }else{
                    this.#addPath(arr_paths,{x:movePoint.x,y:movePoint.y});
                    curr_turn = this.#getNextTurn(movePoint,end_peak,curr_turn);
                    turn_store.push(curr_turn);
                }
                // store point
                if(movePoint.x == end_peak.x && movePoint.y == end_peak.y){
                    break;
                }
            }

            // compele path
            if(movePoint.x == end_peak.x && movePoint.y == end_peak.y){
                break;
            }

            // Fails to get path
            if( arr_paths.length >= turn_limit || loop_count >= 500){
                // console.warn("Limit loop");

                if(!tryOtherWay){
                    // let's try again
                    tryOtherWay = true;
                    tryTurnWay = this.#getOtherWay(turn_store[tryIndex]);
                    arr_paths = [];
                    curr_turn = start_direct;
                    turn_store = [start_direct];
                    movePoint = {
                        x:start_peak.x,
                        y:start_peak.y
                    };
                    this.#addPath(arr_paths,{
                        x:start.x,
                        y:start.y
                    });
                    this.#addPath(arr_paths,{
                        x:start_peak.x,
                        y:start_peak.y
                    });
                    
                }else{
                    break;
                }
                
            }

            pointDirect = curr_turn == this.#UP || curr_turn == this.#DOWN ? "y" : "x";
            stepDirect = curr_turn == this.#UP || curr_turn == this.#LEFT ? -1 : 1;
        }
        
        // final add end
        this.#addPath(arr_paths,{x:end_peak.x,y:end_peak.y});
        this.#addPath(arr_paths,{x:end_peak.x,y:end_peak.y});
        this.#addPath(arr_paths,end);

        return [...arr_paths];
    }

    /**
     * Fix pos devine by 0 and 5
     * @param {object} pos  - vector 
     * @returns 
     */
    #fixPos(pos){

        let r_x = pos.x % 5;
        pos.x = r_x === 0 ? pos.x : (pos.x - r_x + (r_x < 3 ? 0 : 5));

        let r_y = pos.y % 5;
        pos.y = r_y === 0 ? pos.y : (pos.y - r_y + (r_y < 3 ? 0 : 5));
        return pos;
    }

    /**
     * Get list mid points from array paths
     * @param {{x:Number,y:Number}} arr_paths 
     * @returns {[pos:{x:Number,y:Number},direct:String,p1_index:Number,p2_index:Number]} list controls data
     */
    #getMidPointsFromPath(arr_paths){
        let arr_midPoints = [];
        for (let i = 2; i < arr_paths.length - 3; i++) {
            let midpoint = this.#getPointsCenter(arr_paths[i],arr_paths[i + 1]);
            let direct = Math.abs(this.#getAngle(arr_paths[i],arr_paths[i + 1])) != 90 ? "y" : "x";
            arr_midPoints.push({
                pos:midpoint,
                direct: direct,
                p1_index:i,
                p2_index:i + 1
            });
        }
        return arr_midPoints;
    }

    /**
     * Move point with diect and step lenght
     * @param {Object} point 
     * @param {String} direct 
     * @param {Number} amount 
     * @param {Boolean} backwalk 
     */
    #movePointTo(point,direct,amount,backwalk = false){
        if(backwalk){
            point[direct] -= amount;
        }else{
            point[direct] += amount;
        }
    }

    /**
     * Add point to array path
     * @param {Array} arr 
     * @param {Object} point 
     */
    #addPath(arr,point){
        arr.push(point);
    }

    /**
     * Check two direct is opposite or not
     * @param {String} diect_1 
     * @param {String} diect_2 
     * @returns {Boolean}
     */
    #isOppositeDirect(diect_1,diect_2){
        return  diect_1 == this.#LEFT && diect_2 == this.#RIGHT || diect_1 == this.#RIGHT && diect_2 == this.#LEFT ||
                diect_1 == this.#UP && diect_2 == this.#DOWN || diect_1 == this.#DOWN && diect_2 == this.#UP ;
    }

    /**
     * Check point is inside rect
     * @param {{x:Number,y:Number}} point 
     * @param {Object} rect 
     * @returns {Boolean}
     */
    #isPointInRect(point,rect){
        if(!rect){
            return true;
        }
        return point.x <= rect.right && point.x >= rect.left && point.y >= rect.top && point.y <= rect.bottom;
    }

    /**
     * Get middle point between two rect by direct
     * @param {{x:Number,y:Number}} curr_point 
     * @param {String} curr_turn 
     * @param {Object} rect_start 
     * @param {Object} rect_end 
     * @returns 
     */
    #getShortPoint(curr_point,curr_turn,rect_start,rect_end){
        let point_start = {x:0,y:0}; 
        let point_end = {x:0,y:0}; 
        if(curr_turn == this.#UP || curr_turn == this.#DOWN){
            point_start.x = curr_point.x;
            point_start.y = rect_start.bottom;
            point_end.x = curr_point.x;
            point_end.y = rect_end.top;
        }else{
            point_start.x = rect_start.right;
            point_start.y = curr_point.y;
            point_end.x = rect_end.left;
            point_end.y = curr_point.y;
        }
        
        return this.#getPointsCenter(point_start,point_end);
    }

    /**
     * Get middle point between two points
     * @param {{x:Number,y:Number}} point_start 
     * @param {{x:Number,y:Number}} point_end 
     * @returns 
     */
    #getPointsCenter(point_start,point_end){
        return{
            x:Math.trunc(point_start.x+(point_end.x-point_start.x)*0.50),
            y:Math.trunc(point_start.y+(point_end.y-point_start.y)*0.50)
        }
    }

    /**
     * Convert array points to d path data as string
     * @param {Array} paths array of points
     * @param {Number} offsetX offset x
     * @param {Number} offsetY offset y
     * @returns {String} d data of path element
     */
    #convertArrayPathToString(paths,offsetX,offsetY){
        let string_path = "";
        for (let i = 0; i < paths.length; i++) {
            let path = paths[i];
            // offset
            string_path += `${i == 0 ? "M" : "L"}${path.x - offsetX} ${path.y - offsetY} `;
        }
        return string_path.trim();
    }

    /**
     * Calculate next direct to move
     * @param {{x:Number,y:Number}} from
     * @param {{x:Number,y:Number}} to
     * @param {String} last_turn
     * @returns
     */
    #getNextTurn(from,to,last_turn){

        let angle = this.#getAngle(from,to);
        if(angle == 0){
            if(last_turn == this.#LEFT){
                return this.#DOWN;
            }
            return last_turn != this.#RIGHT ? this.#RIGHT : this.#DOWN;
        }else if(angle == 180){
            if(last_turn == this.#RIGHT){
                return this.#DOWN;
            }
            return last_turn != this.#LEFT ? this.#LEFT : this.#DOWN;
        }
        else if(angle == -90){
            if(last_turn == this.#UP){
                return this.#RIGHT;
            }
            return last_turn != this.#DOWN ? this.#DOWN : this.#RIGHT;
        }else if(angle == 90){
            if(last_turn == this.#DOWN){
                return this.#RIGHT;
            }
            return last_turn != this.#DOWN ? this.#UP : this.#RIGHT;
    }
        // I
        else if(angle > 0 && angle < 90){ 
            if(last_turn == this.#UP || last_turn == this.#DOWN){
                return this.#RIGHT;
            }
            if(last_turn == this.#LEFT || last_turn == this.#RIGHT){
                return this.#DOWN;
            }
        }
        // II
        else if(angle > 90 && angle < 180){ 
            if(last_turn == this.#UP || last_turn == this.#DOWN){
                return this.#LEFT;
            }
            if(last_turn == this.#RIGHT || last_turn == this.#LEFT){
                return this.#DOWN;
            }
        }
        // III
        else if(angle > -180 && angle < -90){

            if(last_turn ==  this.#UP|| last_turn == this.#DOWN){
                return this.#LEFT;
            }
            if(last_turn ==  this.#LEFT|| last_turn == this.#RIGHT){
                return this.#UP;
            }
        }
        // IV
        else if(angle > -90 && angle < 0){ 
            if(last_turn ==  this.#UP|| last_turn == this.#DOWN){
                return this.#RIGHT;
            }
            if(last_turn == this.#LEFT || last_turn == this.#RIGHT){
                return this.#UP;
            }
        }
        
    }
    /**
     * Check can moving to end or not
     * @param {Object} point 
     * @param {Object} end 
     * @param {Object} rect_1 
     * @param {Object} rect_2 
     * @param {Number} step_length 
     * @param {String} direct 
     * @returns {Boolean}
     */
    #ray_tracing_to_end(point,end,rect_1,rect_2,step_length,direct){

        let limit = 500;
        let moving = {x:point.x,y:point.y};
        let step = moving[direct] > end[direct] ? step_length*(-1) : step_length;
        while(moving[direct] != end[direct]){
            limit -= 1;
            moving[direct] += step;
            // check collect rect
            if(this.#isPointInRect(moving,rect_1) || this.#isPointInRect(moving,rect_2)){
                return false;
            }
            if(limit <= 0){
                console.error("Can't tracing to end");
                return false;
            }
        }
        return true;

    }

    /**
     * Get other way for second try find path
     * @param {String} lastWay 
     * @returns {String}
     */
    #getOtherWay(lastWay){
        switch(lastWay){
            case this.#UP:
                return this.#DOWN;
            case this.#DOWN:
                return this.#UP;
            case this.#LEFT:
                return this.#RIGHT;
            case this.#RIGHT:
                return this.#LEFT;
        }
    }

    /**
     * Check moving direct will touch rect or not
     * @param {{x:Number,y:Number}} start 
     * @param {String} direct 
     * @param {Object} rect_wrap 
     * @param {Object} rect_1 
     * @param {Object} rect_2 
     * @param {Number} step_length 
     * @returns {Boolean}
     */
    #ray_tracing_touch_rect(start,direct,rect_wrap,rect_1,rect_2,step_length){
        let moving = {x:start.x,y:start.y};
        let pos_direct = (direct == this.#LEFT || direct == this.#RIGHT) ? "x" : "y";
        let step_direct = (direct == this.#RIGHT || direct == this.#DOWN) ? 1 : (-1);
        let arr = [];
        let limit = 500;
        while(!(direct == this.#UP && moving[pos_direct] < rect_wrap.top ||
            direct == this.#RIGHT && moving[pos_direct] > rect_wrap.right ||
            direct == this.#DOWN && moving[pos_direct] > rect_wrap.bottom ||
            direct == this.#LEFT && moving[pos_direct] < rect_wrap.left)){

                moving[pos_direct] += step_direct*step_length;
                arr.push({x:moving.x,y:moving.y});
                if(this.#isPointInRect(moving,rect_1) || this.#isPointInRect(moving,rect_2)){
                    return true;
                }
                limit-= 1;

                if(limit <= 0){
                    console.error("can't check tracing touch rect");
                    return false;
                }
            }
        return false;
    }
    
    /**
     * Get angle from vector
     * @param {{x:Number,y:Number}} from 
     * @param {{x:Number,y:Number}} to 
     * @returns {Number} angle in degrees
     */
    #getAngle(from,to){
        return Math.atan2(to.y - from.y, to.x - from.x) * 180 / Math.PI;
    }

    /**
     * Compare two points
     * @param {{x:Number,y:Number}} point1 
     * @param {{x:Number,y:Number}} point2 
     * @returns 
     */
    #isPointEqual(point1,point2){
        return point1.x == point2.x && point1.y == point2.y;
    }
    
    /**
     * Get peak from start/end
     * @param {{x:Number,y:Number}} point 
     * @param {{x:Number,y:Number}} direct 
     * @param {{x:Number,y:Number}} peak_length 
     * @returns {{x:Number,y:Number}} peak point
     */
    #getPeak(point,direct,peak_length){
        let new_point = {
            x:point.x,
            y:point.y
        };
        switch (direct){
            case this.#UP:
                new_point.y -= peak_length;
                break;
            case this.#DOWN:
                new_point.y += peak_length;
                break;
            case this.#LEFT:
                new_point.x -= peak_length;
                break;
            case this.#RIGHT:
                new_point.x += peak_length;
        }
        return new_point;
    }

    /**
     * Get data for moving node action
     * @param {Element} node 
     * @param {MouseEvent} e 
     */
    #getActionMouseOffset(node,e){
        this.#actionData.mouseOffset = {
            x: node.offsetLeft - e.clientX,
            y: node.offsetTop - e.clientY
        };
    }

    /**
     * Get rect of element
     * @param {HTMLElement} element 
     * @returns {Object}
     */
    #getElementRect(element){

        let rect = {
            top:element.offsetTop,
            left:element.offsetLeft,
            right: element.offsetLeft + element.offsetWidth,
            bottom: element.offsetTop + element.offsetHeight
        }
        
        return rect;
    }


    /**
     * Get element center pos
     * @param {HTMLElement} element element contain nodes
     * @param {String} direct node direct
     * @returns {{x:Number,y:Number}}
     */
    #getPointPosByDirect(element,direct){
        let pos = {x:0,y:0};

        let top = element.offsetTop;
        let bottom = element.offsetTop + element.offsetHeight;
        let left = element.offsetLeft;
        let right = element.offsetLeft + element.offsetWidth;
        let width = right - left;
        let height = bottom - top;
        let arrDirect = direct.split("-");
        let sDirect = arrDirect[0];
        let posDirect = parseInt(arrDirect[1]) || 3;
        let ratito = 0;
        
        let index_direct = this.#POINT_DIRECTS.findIndex((item)=>{return item == sDirect});
        switch (sDirect){
            case this.#UP:
                ratito = width / (this.#POINT_AMOUNTS[index_direct] + 1);
                pos.x = left + (ratito * posDirect);
                pos.y = top;
                break;
            case this.#DOWN:
                ratito = width / (this.#POINT_AMOUNTS[index_direct] + 1);
                pos.x = left + (ratito * posDirect);
                pos.y = bottom;
                break;
            case this.#LEFT:
                ratito = height / (this.#POINT_AMOUNTS[index_direct] + 1);
                pos.x = left;
                pos.y = top + (ratito * posDirect);
                break;
            case this.#RIGHT:
                ratito = height / (this.#POINT_AMOUNTS[index_direct] + 1);
                pos.x = right;
                pos.y = top + (ratito * posDirect);
                break;
        }
        pos.x = Math.round(pos.x);
        pos.y = Math.round(pos.y);
        return pos;
    }
    /**
     * Convert hex color to rbg array
     * @param {String} hex 
     * @returns 
     */
    #hexToRgb(hex) {
        var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
          r: parseInt(result[1], 16),
          g: parseInt(result[2], 16),
          b: parseInt(result[3], 16)
        } : null;
    }

    #rgbToHex(rgb){
        if(rgb.includes("rgb")){
            return `#${rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/).slice(1).map(n => parseInt(n, 10).toString(16).padStart(2, '0')).join('')}`;
        }else{
            return rgb;
        }
    }

    #getbrightness(rgb){
        return Math.round(((parseInt(rgb.r) * 299) +
        (parseInt(rgb.g) * 587) +
        (parseInt(rgb.b) * 114)) / 1000);
        
    }

    /**
     * Create node element
     * @param {String} id 
     * @param {String} name
     * @param {Number} x 
     * @param {Number} y 
     * @param {Number} width 
     * @param {Number} height 
     * @param {String} color 
     * @returns {HTMLElement}
     */
    #createNode(id,name,x,y,width,height,color){

        if(color == null  || color == undefined){
            color = "#ffffff";
        }

        if(width == null || height == null){
            width = this.#node_width_default;
            height = this.#node_height_default;
        }

        let node_Dom = document.createElement("div");
        node_Dom.id = id;
        node_Dom.className = "node";
        node_Dom.innerHTML = `<p style="pointer-events: none;">${name}</p>`;

        // position
        node_Dom.style.top = y + "px";
        node_Dom.style.left = x + "px";
        // size
        node_Dom.style.width = width + "px";
        node_Dom.style.height = height + "px";
        //background
        node_Dom.style.backgroundColor = color;
        // forcecolor
        let rgb = this.#hexToRgb(color);
        if(rgb){
            node_Dom.style.color = this.#getbrightness(rgb) > 125 ? '#000' : "#fff";
        }
        // attribute
        node_Dom.setAttribute("data-name","node");
        node_Dom.setAttribute("data-display",name);

        // event
        node_Dom.addEventListener('mousedown',(e)=>{
            // clear select connecet
            this.#clearSelectConnect();
            let isSelected = node_Dom.classList.contains(this.#selectClass);

            // hold control
            if (this.#isKeyHold("Control")){
                if (isSelected){
                    node_Dom.classList.toggle(this.#selectClass,false);
                }else{
                    node_Dom.classList.toggle(this.#selectClass,true);
                }
            }else{
                
                if(!isSelected){
                    // clear other select
                    this.#listNodes.forEach(node=>{
                        if(node.id != node_Dom.id){
                            node.element.classList.toggle(this.#selectClass,false);
                        }
                    });
                    node_Dom.classList.toggle(this.#selectClass,true);
                }
                this.#fireEvent(this.#EVENT_CHANGE_FORCUS,this.#rgbToHex(node_Dom.style.backgroundColor));
                this.#actionData.selectItem.target = node_Dom;
            }
        });
        node_Dom.addEventListener('mouseup',(e)=>{
            // check button
            if(e.button == 2){
                this.#actionData.selectItem.target = node_Dom;
                // get pos
                let posX = e.offsetX + node_Dom.offsetLeft;
                let posY = e.offsetY + node_Dom.offsetTop;
                // show menu
                this.#showMenu(posX,posY);
            }

        })

        // controls: points
        let topPoint = document.createElement("div");
        let bottomPoint = document.createElement("div");
        let rightPoint = document.createElement("div");
        let leftPoint = document.createElement("div");

        topPoint.className = "node-point point-top";
        topPoint.setAttribute("data-direct",this.#UP);
        topPoint.setAttribute("data-name","node-direct");

        leftPoint.className = "node-point point-left";
        leftPoint.setAttribute("data-direct",this.#LEFT);
        leftPoint.setAttribute("data-name","node-direct");
        
        bottomPoint.className = "node-point point-bottom";
        bottomPoint.setAttribute("data-direct",this.#DOWN);
        bottomPoint.setAttribute("data-name","node-direct");
        
        rightPoint.className = "node-point point-right";
        rightPoint.setAttribute("data-direct",this.#RIGHT);
        rightPoint.setAttribute("data-name","node-direct");

        
        node_Dom.append(topPoint);
        node_Dom.append(leftPoint);
        node_Dom.append(bottomPoint);
        node_Dom.append(rightPoint);

        // EXTRA points
        this.#createConnectPoints(node_Dom);

        // resize controls
        let rightRezise = document.createElement("div");
        let bottomRezise = document.createElement("div");
        let cornerRezise = document.createElement("div");
        
        rightRezise.className = "right-resize";
        rightRezise.setAttribute("data-act","resize");
        rightRezise.setAttribute("data-resize","x");

        bottomRezise.className = "bottom-resize";
        bottomRezise.setAttribute("data-act","resize");
        bottomRezise.setAttribute("data-resize","y");
        
        cornerRezise.className = "corner-resize";
        cornerRezise.setAttribute("data-act","resize");
        cornerRezise.setAttribute("data-resize","xy");

        // remove button
        let removeIcon = this.#createButtonRemoveSvg("remove-button",this.#REMOVE_ICON_PATH,25,"#f72929",2);
        removeIcon.style.top = 0;
        removeIcon.style.right = -1;
        removeIcon.addEventListener('click',()=>{
            this.#removeSelected();
        })

        node_Dom.append(removeIcon);
        node_Dom.append(rightRezise);
        node_Dom.append(bottomRezise);
        node_Dom.append(cornerRezise);

        return node_Dom;
    }

    /**
     * Create mark
     * @param {Element} node
     */
    #createMark(node){
        if(node.querySelector(".mark-node") == null){
            let mark = document.createElement('span');
            mark.className = "fas fa-flag mark-node";
            mark.style.color = "#e63757";
            mark.style.top = "2px";
            mark.style.right = "7px";
            mark.style.fontSize = "14px";
            node.append(mark);
            return mark;
        }
    }

    /**
     * Remove mark
     * @param {Element} node
     */
    #removeMark(node){
        let mark = node.querySelector(".mark-node");
        if( mark!= null){
           mark.remove();
        }
    }

    #createConnectPoints(node){
        // extra point

        for (let i = 0; i < this.#POINT_AMOUNTS.length; i++) {
            let top = 0;
            let left = 0;
            for (let amount = 1; amount <= this.#POINT_AMOUNTS[i]; amount++) {
                let ratito = 100/ (this.#POINT_AMOUNTS[i] + 1);
                let directClass = "vetical";
                switch (this.#POINT_DIRECTS[i]) {
                    case this.#UP:
                        left = ratito * amount;
                        break;
                    case this.#DOWN:
                        top = 100;
                        left = ratito * amount;
                        break;
                    case this.#LEFT:
                        top = ratito * amount;
                        directClass = "horizon";
                        break;
                    case this.#RIGHT:
                        top = ratito * amount;
                        left = 100;
                        directClass = "horizon";
                    break;
                    
                    default:
                        break;
                }


                let point = document.createElement("div");
                point.className = `node-point ${directClass}`;
                point.style = `top:${top}%;left:${left}%`;
                point.setAttribute("data-direct",this.#POINT_DIRECTS[i] + "-" + amount);
                point.setAttribute("data-name","node-direct");
                node.append(point);
            }
        }
    }

    /**
     * Create mid points button
     * @param {String} connectId connect Id
     * @param {{x:Number,y:Number}} arr_midPoints pathsData.centers
     * @param {Number} offsetX 
     * @param {Number} offsetY
     * @param {Element} pathElement
     * @param {Element} areaArrow
     * @param {[]} arr_paths
     * @returns {[Element]} array of move path controls
     */
    #createMidPointButton(connectId,arr_midPoints,offsetX,offsetY,pathElement,areaArrow,arr_paths){

        let arr_result = [];
        for (let i = 0; i <= arr_midPoints.length - 1; i++) {

            let center = arr_midPoints[i];
            let pos = {x:center.pos.x,y:center.pos.y};
            let direct = center.direct;
            let p1_index = center.p1_index;
            let p2_index = center.p2_index;

            // offset
            if(offsetX !== null){
                pos.x = pos.x - offsetX;
            }
            if(offsetY !== null){
                pos.y = pos.y - offsetY;
            }

            let circle = document.createElementNS(this.#xmlns, 'circle');
            circle.setAttribute('r',5);
            circle.setAttribute('cx',pos.x);
            circle.setAttribute('cy',pos.y);
            circle.setAttribute('fill',"#6988eda1");
            circle.setAttribute('stroke-width',0);
            circle.setAttribute('data-move-direct',direct);
            circle.setAttribute('class','button-svg');

            circle.addEventListener('mousedown',(e)=>{
                this.#setAction(this.#MOVING_ARROW_PATH_ACT);
                this.#bMousedown = true;
                this.#actionData.movingPath.connectId = connectId;
                this.#actionData.movingPath.path = pathElement;
                this.#actionData.movingPath.areaArrow = areaArrow;
                this.#actionData.movingPath.arr_paths = arr_paths;
                this.#actionData.movingPath.direct = direct;
                this.#actionData.movingPath.p1Index = p1_index;
                this.#actionData.movingPath.p2Index = p2_index;
                this.#actionData.movingPath.offset.x = offsetX;
                this.#actionData.movingPath.offset.y = offsetY;
                let centerPos = {x:e.target.getAttribute("cx"),y:e.target.getAttribute('cy')}
                // mouse offset
                this.#actionData.mouseOffset = {
                    x: centerPos.x - e.clientX,
                    y: centerPos.y - e.clientY
                };
            });

            arr_result.push(circle);
        }

        return arr_result;
    }

    /**
     * Update connect label
     * @param {Element} connectSvg
     * @param {Object} data 
     */
    #updateConnectLabelValue(connectSvg,data){
        let label = connectSvg.querySelector("#"+this.#labelId);
        // set button invisible
        let labelButton = label.querySelector("#"+this.#labelButtonId);
        if (!label){
            console.warn("No label found");
            return;
        }

        let label_forms = label.querySelector("#" + this.#labelFormId);
        let label_status = label.querySelector("#" + this.#labelStatusId);
        let label_idenfity = label.querySelector("#" + this.#labelIdenfityId);
        if (!label_forms){
            console.warn("No label form found");
            return;
        }

        if (!label_status){
            console.warn("No label status found");
            return;
        }
        if (!label_idenfity){
            console.warn("No label idenfity found");
            return;
        }

        // find connect data
        let connectIndex = this.#listConnects.findIndex(connect => connect.id == connectSvg.id);
        if(connectIndex < 0){
            return;
        }

        this.#listConnects[connectIndex].forms = null;
        this.#listConnects[connectIndex].status = data.status;
        this.#listConnects[connectIndex].idenfity = data.idenfity;

        // forms
        let form_name = "";
        this.#formsLabelList.forEach((item,index)=>{
            if(item.value == data.forms){
                form_name = item.name;
                this.#listConnects[connectIndex].forms = data.forms;
            }
        });

        labelButton.classList.toggle("force-hidden",form_name != "");

        label_forms.textContent = form_name;
        label_forms.setAttribute("data-value",data.forms);

        // status
        let posY = 0;
        if(form_name != ""){
            posY = -22;
        }
        label_status.textContent = data.status;
        label_status.setAttribute("data-value",data.status);
        label_status.setAttributeNS(null,"y",posY);

        // idenfity
        label_idenfity.textContent = data.idenfity;
        label_idenfity.setAttribute("data-value",data.idenfity.split("-").filter(n => n).join("-"));

    }
    /**
     * Update label pos
     * @param {Element} connectSvg
     * @param {[]} arr_midPoints
     * @param {Number} offsetX
     * @param {Number} offsetY
     */
    #updateConnectLabelPos(connectSvg,arr_midPoints,offsetX,offsetY){
        let label = connectSvg.querySelector("#"+this.#labelId);
        if (!label){
            console.warn("No label found");
            return;
        }
        let midIndex = Math.floor(arr_midPoints.length/2);
        let center = arr_midPoints[midIndex].pos;
        let pos = {
            x:parseInt((center.x - offsetX)),
            y:(center.y - offsetY) - 10
        }
        // fix pos on vetical path
        if(arr_midPoints[midIndex].direct == 'x'){
            pos.x += 10;
        }
        label.setAttribute("x",pos.x);
        label.setAttribute("y",pos.y);
    }

    /**
     * Convert path string to array point
     * @param {String} path 
     * @returns {Array} Array point
     */
    #pathStringToPathData(path = ""){
        let arr_paths = [];
        let temp_arr = path.trim().split(" ");
        // valid
        if(temp_arr.length == 0 || temp_arr.length % 2 != 0){
            return null;
        }
        let temp_pos = {x:0,y:0};

        temp_arr.forEach((part,index)=>{

            let pos = parseInt(part.toLowerCase().replace("l","").replace("m",""));
            if(index % 2 == 0){
                temp_pos.x = pos;
            }else{
                temp_pos.y = pos;
                arr_paths.push({x:temp_pos.x,y:temp_pos.y});
                temp_pos = {x:0,y:0};
            }
        });

        return arr_paths;
    }

    /**
     * Cheeck key is hold
     * @param {String} key 
     */
    #isKeyHold(key){
        return this.#keyHold.includes(key);
    }

    /**
     * Clear all data
     */
    #clearData(){
        //nodes
        for (let i = 0; i < this.#listNodes.length; i++) {
            const node = this.#listNodes[i];
            node.element.remove();
        }
        this.#listNodes = [];

        //nodes
        this.#listConnects.forEach(connect=>{
            if(connect.path){
                connect.element.remove();
            }
        })
        this.#listConnects = [];

    }

    /**
     * Fire event
     * @param {String} eventName 
     * @param {Any} payload 
     */
    #fireEvent(eventName,payload){
        for (var i = 0; i < this.#eventHandlers.length; i++) {
            if(eventName == this.#eventHandlers[i].name){
                this.#eventHandlers[i].callback(payload);
            }
        }
    }

    /**
     * Show menu
     * @param {Number} posX 
     * @param {Number} posY 
     */
    #showMenu(posX,posY){
        this.#dropMenu.style.top = posY + "px";
        this.#dropMenu.style.left = posX + "px";
        this.#dropMenu.style.display = "block";
    }

    /**
     * Hide menu
     */
    #hideMenu(){
        this.#dropMenu.style.top ="0px";
        this.#dropMenu.style.left = "0px";
        this.#dropMenu.style.display = "none";
    }

    // PUBLIC

    /**
     * Load diagram data
     * @param {Any} id 
     * @param {Array} nodes 
     * @param {Array} connects 
     */
    loadDiagram(id,nodes,connects){

        this.#id = id;
        this.#clearData();
        this.#bShowFlowAnim = false;
        // NODE
        nodes.forEach(node=>{

            let id = node.department_id; // department_id
            let name = node.name;
            let px = node.px;
            let py = node.py;
            let color = node.color;
            let height = node.height;
            let width = node.width;
            let nfirst = node.nfirst == "YES";

            this.addNode(id,name,px,py,width,height,color,nfirst);

        });

        // Connects
        connects.forEach(connect=>{

            let arr_paths = this.#pathStringToPathData(connect.path);
            let start_id = this.#nodeprefix + connect.nbegin;
            let end_id = this.#nodeprefix + connect.nend;
            let start_direct = connect.pbegin;
            let end_direct = connect.pend;
            let connect_type = connect.linetype;
            let mark_end = connect.endlinetype == "MARK";
            let color = connect.color;
            let forms = connect.forms;
            let status = connect.status;
            let idenfity = connect.idenfity;
            
            let connectdata = this.#createConnect(start_id,start_direct,end_id,end_direct,arr_paths,connect.path,connect_type,mark_end,color,forms,status,idenfity);
            // fix label
            

            if(connectdata){
                this.#listConnects.push({
                    id:connectdata.svg.id,
                    element:connectdata.svg,
                    path:connectdata.path,
                    areaArrow:connectdata.areaArrow,
                    start_id:start_id,
                    start_direct:start_direct,
                    end_id:end_id,
                    end_direct:end_direct,
                    midPoints:connectdata.midPoints,
                    connect_type:connect_type,
                    mark_end:mark_end,
                    color:color,
                    forms:forms,
                    status:status,
                    idenfity:idenfity,
                });
            }
        });

    }

    /**
     * Get data to save to database
     * @param {MouseEvent} e
     * @returns {{id:any,name:String,nodes:Array,connects:Array}}
     */
     getDiagramData(){
        let connects = this.#listConnects.map(connect=>{
            // get string path
            connect.path.getAttribute("d");
            return {
                start_id:connect.start_id.replace(this.#nodeprefix,""),
                start_direct:connect.start_direct,
                end_id:connect.end_id.replace(this.#nodeprefix,""),
                end_direct:connect.end_direct,
                path:connect.path.getAttribute("d"),
                connect_type:connect.connect_type,
                mark_end:connect.mark_end ? "MARK": "NONE",
                color:connect.color,
                status:connect.status,
                forms:connect.forms,
                idenfity:connect.idenfity
            }
        });
        let nodes = this.#listNodes.map(node=>{
            return {
                id:node.id.replace(this.#nodeprefix,""),
                name:node.name,
                pos:node.pos,
                size:node.size,
                color:node.color,
                nfirst:node.nfirst ? "YES" : null
            }
        })

        return {
            id:this.#id,
            nodes:nodes,
            connects:connects
        };
    }

    /**
     * Add node
     * @param {String} id 
     * @param {String} name 
     * @param {Number} x 
     * @param {Number} y 
     * @param {Number} width 
     * @param {Number} height 
     * @param {string} color 
     * @param {Boolean} nfirst 
     * @param {boolean} bFix 
     */
    addNode(id,name,x,y,width,height,color,nfirst = false,bFix = false){
        // add prefix to id, queryselecter can't query id only number
        id = this.#nodeprefix + id;
        
        // check
        if(this.#listNodes.some(node=> node.id == id)){
            return;
        }
        
        // fix scroll offset
        if(bFix){
            x += this.#nodeMain.scrollLeft;
            y += this.#nodeMain.scrollTop;
        }

        let nodeElement = this.#createNode(id,name,x,y,width,height,color);
        let markElement = null;
        // mark
        if(nfirst){
            markElement = this.#createMark(nodeElement);
        }
        // append to parent
        this.#nodeContainer.append(nodeElement);
        // store node
        this.#listNodes.push({
            id:id,
            name:name,
            pos:{
                x:x,
                y:y
            },
            size:{
                width: width != null ? width : this.#node_width_default,
                height: height != null ? height : this.#node_height_default
            },
            color:color,
            element:nodeElement,
            markElement:markElement,
            nfirst: nfirst
        });
    }

    /**
     * Add event listener
     * @param {String} name - ""
     * @param {Function} callback 
     */
    addEventListener(name,callback){
        this.#eventHandlers.push({
            name:name,
            callback:callback
        });
    }
    /**
     * Get current mouse pos in grid
     * @returns {x:Number,y:Number}
     */
    getMousePos(){
        return this.#actionData.curr_mouse;
    }

    /**
     * Get diagram container
     * @returns {String | null}
     */
    getContainerId(){
        if(this.#nodeMain){
            return this.#nodeMain.id;
        }else{
            return null;
        }
    }

    // CONTROLS
    /**
     * Get current zoom percent
     * @returns {Number}
     */
    getZoomPercent(){
        return Math.round((this.#curr_zoom /1) * 100);
    }
    /**
     * Reset zoom to default
     */
    resetZoom(){
        this.#curr_zoom = 1;
        this.#nodeContainer.style.zoom = 1;
    }
    /**
     * Toggle grid line visible
     * @returns {Boolean} grid line state
     */
    toggleGridLine(){
        this.#b_showGrid = !this.#b_showGrid;
        this.#nodeContainer.classList.toggle("grid-line",this.#b_showGrid);
        return this.#b_showGrid;
    }
    
    /**
     * Draw arrow mark at end or not
     * @param {Boolean} bDraw 
     * @returns {Boolean}
     */
    setArrowEndMark(bDraw){
        this.#controlData.arrowMarkEnd = bDraw;
    }

    /**
     * Set arrow type Dash
     * @param {Boolean} bSolid 
     */
    setArrowSolid(bSolid){
        let type = bSolid ? this.#ARROW_SOLID :this.#ARROW_DASH
        this.#controlData.arrowType = type;
    }

    /**
     * Set list form data
     * @param {[{name:String,value:String}]} listForms 
     */
    setListLabelData(listForms){
        this.#formsLabelList = listForms.map(item=>({
            name:item.name,
            value: item.scode
        }));
    }

    /**
     * Set arrow color value
     * @param {String} color 
     */
    #setArrowColor(color){
        if (this.#actionData.selectItem.target != null && this.#actionData.selectItem.target.tagName == "svg"){
            // change arrow color
            this.#actionData.selectItem.target.querySelectorAll("path").forEach(path=>{
                if (!path.classList.contains("select-path")){
                    if(!path.classList.contains("scale-path")){
                         path.style.stroke = color;
                    }
                    if(path.parentElement.tagName == "marker"){
                         path.style.fill = color;
                    }
                }
            });
            // store connect color
            this.#listConnects.forEach(connect=>{
                if(connect.id == this.#actionData.selectItem.target.id){
                    connect.color = color;
                }
            });
        }
        this.#controlData.arrowColor = color;
    }


    /**
     * Get diagram id
     * @returns {String}
     */
    getDiagramId(){
        return this.#id;
    }

    /**
     * Get diagram id
     * @param {String}
     */
    setDiagramId(id){
        this.#id = id;
    }

    /**
     * Mark node
     * @param {String} nodeid Id node 
     */
    toggleMark(nodeId){
        this.#listNodes.forEach(node=>{
            if(node.id == nodeId){
                node.nfirst = !node.nfirst;
            }else{
                node.nfirst = false;
            }

            // mark element
            if (node.nfirst){
                let markElement = this.#createMark(node.element);
                node.markElement = markElement;
            }else{
                this.#removeMark(node.element);
                node.markElement = null;
            }
        })
    }

    /**
     * Change arrow or node color
     * @param {String} color 
     */
    setColor(color){
        if(this.#actionData.selectItem.target != null && this.#actionData.selectItem.target.tagName == "svg"){
            this.#setArrowColor(color);
            this.#colorSelectArrow = color;
        }else{
            this.#listNodes.forEach(node=>{
                if(node.element.classList.contains(this.#selectClass)){
                    //background
                    node.element.style.backgroundColor = color;
                    // forcecolor
                    let rgb = this.#hexToRgb(color);
                    if(rgb){
                        node.element.style.color = this.#getbrightness(rgb) > 125 ? '#000' : "#fff";
                    }
                    node.color = color;
                }
            });
        }
    }

    /**
     * For change color arrow controls
     */
    isSelectNode(){
        return this.#actionData.selectItem.target != null;
    }

    /**
     * Set translate
     */
    setTranslate(trans){
        this.#trans = trans;
    }

    /**
     * Create new diagram
     */
    newDiagram(){
        this.#id = null;
        this.#clearData();
    }
}