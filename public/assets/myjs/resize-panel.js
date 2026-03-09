/* Author: Đinh Hoàng Vũ */
/**
 * @param {String} gutterID
 * @param {String} targetID panel to resize
 * @param {String} containerID container of panels
 * @param {Number} minSize default 0, 0 mean no limit
 * @param {Number} maxSize default 0, 0 mean no limit
 * @param {String} resizeDirection resize direction "x" | "y"
 * 
 */
 const ResizePanel = (gutterID,targetID,containerID,minSize = 0, maxSize = 0,resizeDirection) =>{
    // valid param
    minSize = minSize || 0;
    maxSize = maxSize || 0;
    resizeDirection = resizeDirection ? resizeDirection : "x";

    let gutterControl = document.querySelector(`#${gutterID}`);
    let targetPanel = document.querySelector(`#${targetID}`);
    let containerPanel = document.querySelector(`#${containerID}`);
    let isMouseDown = false;
    let panelSize = null;
    let preMousePos = 0;

    if(!gutterControl || !targetPanel){
        return;
    }

    //  mouse event
    /**
     * 
     * @param {MouseEvent} e 
     * @returns 
     */
    function ControlMousedown(e){
        if(e.button != 0 ){
            return;
        }
        // style
        containerPanel.classList.toggle("container-cursor",true);
        panelSize = targetPanel.getBoundingClientRect();    
        isMouseDown = true;
        preMousePos = e[resizeDirection];
    }
    function ControlMouseup(e){
        if(e.button != 0 ){
            return;
        }
        containerPanel.classList.toggle("container-cursor",false);
        isMouseDown = false;
    }
    function ControlMousemove(e){
        if(e.button != 0 || !isMouseDown){
            return;
        }

        let newMousePos = preMousePos - e[resizeDirection];
        let newSize = resizeDirection == "x" ?  panelSize.width - newMousePos : panelSize.height - newMousePos;

        if((newSize > maxSize && maxSize != 0) || (newSize < minSize && minSize != 0)){
            return;
        }
        
        if(resizeDirection == "x"){
            targetPanel.style.width = newSize + "px";
        }else{
            targetPanel.style.height = newSize + "px";
        }
    }

    gutterControl.addEventListener("mousedown",ControlMousedown);
    containerPanel.addEventListener("mouseup",ControlMouseup);
    containerPanel.addEventListener("mousemove",ControlMousemove);

}