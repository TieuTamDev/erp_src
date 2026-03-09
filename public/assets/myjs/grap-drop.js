/* Author: Đinh Hoàng Vũ */
class GrapDrop{

    // event name
    #eventHandlers = [];
    // #GRAP_EVENT = "ongrap";
    // #DRAG_EVENT = "ondrag";
    #DROP_EVENT = "ondrop";
    
    #is_grab = false;
    #cloneElement = null;
    #dropTarget = null;
    #mouseOffset= 15;
    #selectItems = [];
    #singleItemSelect = null;

    #grabInfo={
        displayName:"",
        ids:[],
        folderPaths:[],
        iconPath:"",
        count:0
    };
    #defaultGrapInfo ={
        displayName:"",
        ids:[],
        folderPaths:[],
        iconPath:"",
        count:0
    };
    #lastGragIds =[];

    constructor(){
        document.body.addEventListener('mousedown',(e)=>{
            this.#mouseDown(e);
        });
        document.body.addEventListener('mousemove',(e)=>{
            this.#mouseMove(e);
        });
        document.body.addEventListener('mouseup',(e)=>{
            this.#mouseUp(e);
        });
    }

    // PRIVATE
    /**
     * Document mouse down
     * @param {MouseEvent} e 
     * @returns 
     */
    #mouseDown(e){

        if(this.#is_grab || e.button != 0){
            return;
        }

        // get grap item
        this.#singleItemSelect = this.#getGrapDropElement(e.target,true);
        if(this.#singleItemSelect == null){
            return;
        }

        // check grap when multi is selected
        if(this.#selectItems.length > 0){
            this.#is_grab = this.#selectItems.some(item=> item == this.#singleItemSelect);
            this.#singleItemSelect = null;
        }else{
            this.#is_grab = true;
            this.#getGrapInfo([this.#singleItemSelect]);
        }
    }

    /**
     * Document mouse move
     * @param {MouseEvent} e 
     */
    #mouseMove(e){

        if(!this.#is_grab){
            return;
        }

        var dot, eventDoc, doc, body, pageX, pageY;

        e = e || window.event; // IE-ism

        if (e.pageX == null && e.clientX != null) {
            eventDoc = (e.target && e.target.ownerDocument) || document;
            doc = eventDoc.documentElement;
            body = eventDoc.body;

            e.pageX = e.clientX +
              (doc && doc.scrollLeft || body && body.scrollLeft || 0) -
              (doc && doc.clientLeft || body && body.clientLeft || 0);
            e.pageY = e.clientY +
              (doc && doc.scrollTop  || body && body.scrollTop  || 0) -
              (doc && doc.clientTop  || body && body.clientTop  || 0 );
        }
        let x = e.pageX + this.#mouseOffset;
        let y = e.pageY + this.#mouseOffset;

        // check select multi
        if(this.#selectItems.length == 0){
            if(this.#singleItemSelect){
                this.#toggleHightlightElement(this.#singleItemSelect,'grap-select',true);
            }
        }
    
        if(!this.#cloneElement){
            this.#createClone(y,x);
        }
        this.#MoveClone(y,x);

        // fix click item issue
        this.#lastGragIds = [];
        this.#grabInfo.ids.forEach(id=>{
            this.#lastGragIds.push(id);
        });
    }

    /**
     * Document mouse up
     * @param {MouseEvent} e 
     */
    #mouseUp(e){

        this.#is_grab = false;
        // clear last grab
        setTimeout(() => {
            this.#lastGragIds = [];
        },50);
        if(this.#cloneElement){
            this.#cloneElement.remove();
            this.#cloneElement = null;
        }
        if(!this.#singleItemSelect && this.#selectItems.length == 0){
            this.#grabInfo = this.#defaultGrapInfo;
            return;
        }

        // hightlight element
        if(this.#selectItems.length == 0){
            this.#toggleHightlightElement(this.#singleItemSelect,'grap-select',false);
        }
        
        this.#dropTarget  = this.#getGrapDropElement(e.target,false);
        if(!this.#dropTarget){
            this.#grabInfo = this.#defaultGrapInfo;
            return;
        }
        let b_canDrop = this.#validDrop( this.#dropTarget);
        this.#grabInfo = this.#defaultGrapInfo;
        // hover effect
        this.#dropTarget.classList.toggle("item-drop",false);

        if(b_canDrop){
            this.#fireEvent(this.#DROP_EVENT,{
                graps : this.#selectItems.length > 0 ? this.#selectItems : [this.#singleItemSelect],
                target : this.#dropTarget
            });
        }
        
    }

    /**
     *  Element mouse enter
     * @param {MouseEvent} e 
     */
    #MouseEnterElement(e){
        if(this.#is_grab){
            let element = this.#getGrapDropElement(e.target,!this.#is_grab);
            if(element && this.#validDrop(element)){
                this.#toggleHightlightElement(element,"item-drop",true);
            }
        }
    }

    /**
     * Element mouse leave
     * @param {MouseEvent} e 
     */
    #MouseLeaveElement(e){
        if(this.#is_grab){
            let element = this.#getGrapDropElement(e.target,!this.#is_grab);
            if(element && this.#validDrop(element)){
                this.#toggleHightlightElement(element,"item-drop",false);
            }
        }
    }

    #fireEvent(eventName,payload){
        for (var i = 0; i < this.#eventHandlers.length; i++) {
            if(eventName == this.#eventHandlers[i].name){
                this.#eventHandlers[i].callback(payload);
            }
        }
    }

    /**
     * 
     * @param {[Element]} elements
     * @param {Number} count 
     */
    #getGrapInfo(elements){

        //path list
        this.#grabInfo.folderPaths = [];
        this.#grabInfo.ids = [];
        this.#lastGragIds = [];
        this.#grabInfo.displayName = "";
        this.#grabInfo.count = 0;
        this.#grabInfo.iconPath = "";
        elements.forEach(item=>{
            this.#grabInfo.folderPaths.push(item.getAttribute("data-path"));
            this.#grabInfo.ids.push(item.id);
        });

        // name
        this.#grabInfo.displayName = elements[elements.length - 1].getAttribute("data-name");
        // icon
        let iconItem = elements[elements.length - 1].querySelector("[data-icon]");
        if(iconItem){
            this.#grabInfo.iconPath = iconItem.src;
        }
        this.#grabInfo.count = elements.length;
    }

    /**
     * Get grap or drop element: get by attribute can-grap | can-drop , check on mouse target or mouse target parent
     * @param {Element} element 
     * @param {Boolean} b_grap 
     * @return {Element} element to grap or drop
     */
    #getGrapDropElement(element,b_grap){
        let atributte = b_grap ? 'can-grap' : 'can-drop';
        // grap
        let canGrap = element.getAttribute(atributte);
        if(canGrap !== "true"){
            element = element.parentElement;
            if(!element){
                return null;
            }
            canGrap = element.getAttribute(atributte);
            if(canGrap !== "true"){
                return null;
            }
        }
        return element;
    }

    /**
     * Create Clone Element
     * @param {String} name 
     * @param {Number} posX 
     * @param {Number} posY  
     * @param {Boolean} multi
     */
    #createClone(posX,posY){

        let count = this.#grabInfo.count;
        let displayName = this.#grabInfo.displayName;

        this.#cloneElement = document.createElement("div");
        this.#cloneElement.className = `clone-item ${count > 1 ? "clone-item-multi" : ""}`;
        this.#cloneElement.setAttribute('style',`top: ${posX}px; left: ${posY}px`);

        this.#cloneElement.innerHTML = `
            <p><img src="${this.#grabInfo.iconPath}" alt=""> ${displayName}</p>
            <p class="clone-item-count">${count}</p>
        `;
        document.body.append(this.#cloneElement);
    }

    /**
     * Moving clone to pos
     * @param {Number} X  
     * @param {Number} Y  
     */
    #MoveClone(X,Y){
        if(!this.#cloneElement){
            return;
        }
        this.#cloneElement.style.top =  X + 'px';
        this.#cloneElement.style.left = Y + 'px';
    }

    /**
     * Hight light element
     * @param {Element} element
     * @param {String} className
     * @param {Boolean} toggle
     */
    #toggleHightlightElement(element,className,toggle){

        if(element.getAttribute("data-hl") == "true"){
            element.classList.toggle(className,toggle);
        }else{
            let childHl = element.querySelector('[data-hl]');
            if(childHl.getAttribute("data-hl") == "true"){
                childHl.classList.toggle(className,toggle);
            }
        }
    }

    /**
     * Validate drop action
     * @param {Element} dropElement
     * @returns {Boolean} 
     */
    #validDrop(dropElement){
        // attribute candrop
        let canDrop = dropElement.getAttribute('can-drop');
        if(!canDrop || canDrop == 'false'){
            return false;
        }

        //moving to it self : single select
        if(this.#selectItems.length == 0 && (!this.#singleItemSelect || dropElement == this.#singleItemSelect || dropElement.id == this.#singleItemSelect.id)){
            return false;
        }

        //drop to owner childs or it self: multi file include. Using for drop file purpose
        let dropElementPath = dropElement.getAttribute("data-path");
        if(dropElementPath){
            let path_arr = dropElementPath.split("/").filter(str=> {return str != ''});
            let isDropChild = false;
            for (let i = 0; i < this.#grabInfo.ids.length; i++) {
                const id = this.#grabInfo.ids[i];
                if(path_arr.includes(id)){
                    isDropChild = true;
                    break;
                }else if( dropElement.id == id){ // moving it self
                    isDropChild = true;
                    break;
                }else{ // moving with out change path
                    this.#grabInfo.folderPaths.forEach(path=>{
                        let arr = path.split("/").filter(str=> {return str != ''});
                        if(arr[arr.length -1 ] == dropElement.id){
                            isDropChild = true;
                        }
                    })
                }
            }
            if(isDropChild){
                return false;
            }   
        }

        return true;
    }

    //PUBLIC
    /**
    * Add element to grap array ( for multi grap items , checkbox )
    * @param {Element} item 
    */
    addGrapItem(item){
        this.#selectItems.push(item);
        // get grap info
        this.#getGrapInfo(this.#selectItems);

    }
    /**
    * Remove element from grap array ( for multi grap items , checkbox )
    * @param {Element} item 
    */
    removeGrapItem(item){
        // remove item in array
        let index = this.#selectItems.indexOf(item);
        if(index > -1){
            this.#selectItems.splice(index,1);
        }
        // get grap info
        if(this.#selectItems.length > 0){
            this.#getGrapInfo(this.#selectItems);
        }
    }

    /**
     * Get items selected
     */
    getSelectItems(){
        return this.#selectItems;
    }

    /**
    * Clear select item ( for multi grap items , checkbox ) : using when new data is load from api
    */
    clearSelectItems(){
        this.#selectItems = [];
        this.#singleItemSelect = null;
    }

    /**
     * Clear item in document after drop. Include tree view
     * @param {String} treeId 
     */
    removeSelectItemsElement(treeId = null){
        this.selectItems.forEach(item => {
            item.remove();
        });
        if(this.singleItemSelect){
            this.singleItemSelect.remove();
            this.singleItemSelect = null;
        }
        this.selectItems = [];

        // clear old node in treeview when grab from other view to tree view 
        if(treeId){
            let treeView = document.getElementById(treeId);
            this.grabInfo.ids.forEach((id,index)=>{
                let nodes = treeView.querySelectorAll("#"+id);
                for (let i = 0; i < nodes.length; i++) {
                    let node = nodes[i];
                    let path = node.getAttribute("data-path");
                    if(path == this.grabInfo.folderPaths[index]){
                        node.remove();
                        break;
                    }
                }
            });
        }
    }

    /**
    * Add hover effect for grap/drop element
    * @param {String}  parentId
    */
     updateDropEffect(parentId){
        let container = document.querySelector("#"+parentId);
        if(container){
            let childs = container.children;
            for (let i = 0; i < childs.length; i++) {
                let element = childs[i];
                element.addEventListener("mouseenter",(e)=>{
                    this.#MouseEnterElement(e);
                });
                element.addEventListener("mouseleave",(e)=>{
                    this.#MouseLeaveElement(e);
                });
            }
        }
    }

    /**
     * Using only for tree view combine
     * @param {String} treeId 
     * @param {String} nodeId
     */
    updateItemsTreeEffect(treeId,nodeId = null){
        let treeview = document.querySelector("#"+treeId);
        let childs = [];
        if(!nodeId){
            childs = treeview.children;
        }else{
            let node = treeview.querySelector("#"+nodeId);
            childs = node.children;
        }
        for (let i = 0; i < childs.length; i++) {
            const element = childs[i];
            let items = element.querySelectorAll(".tree-view-node");
            for (let y = 0; y < items.length; y++) {
                const item = items[y];
                if(item){
                    item.addEventListener("mouseenter",(e)=>{
                        this.#MouseEnterElement(e);
                    });
                    item.addEventListener("mouseleave",(e)=>{
                        this.#MouseLeaveElement(e);
                    });
                }
            }
        }
    }

    /**
     * Get array id of last items graped
     * @returns {[]}
     */
    getLastGrab(){
        return this.#lastGragIds;
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
}