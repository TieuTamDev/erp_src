function init(list_stages) {
    // list_stages = valuetest.split(";");
    var $ = go.GraphObject.make;  // for conciseness in defining templates
    go.Diagram.clean;
    myDiagram = $(go.Diagram, "myDiagram",  // must name or refer to the DIV HTML element
    {
        grid: $(go.Panel, "Grid",
            $(go.Shape, "LineH", { stroke: "lightgray", strokeWidth: 0.5 }),
            $(go.Shape, "LineH", { stroke: "gray", strokeWidth: 0.5, interval: 10 }),
            $(go.Shape, "LineV", { stroke: "lightgray", strokeWidth: 0.5 }),
            $(go.Shape, "LineV", { stroke: "gray", strokeWidth: 0.5, interval: 10 })
        ),
        allowDrop: true,  // must be true to accept drops from the Palette
        "draggingTool.dragsLink": true,
        "draggingTool.isGridSnapEnabled": true,
        "linkingTool.isUnconnectedLinkValid": true,
        "linkingTool.portGravity": 20,
        "relinkingTool.isUnconnectedLinkValid": true,
        "relinkingTool.portGravity": 20,
        "relinkingTool.fromHandleArchetype":
          $(go.Shape, "Diamond", { segmentIndex: 0, cursor: "pointer", desiredSize: new go.Size(8, 8), fill: "tomato", stroke: "darkred" }),
        "relinkingTool.toHandleArchetype":
          $(go.Shape, "Diamond", { segmentIndex: -1, cursor: "pointer", desiredSize: new go.Size(8, 8), fill: "darkred", stroke: "tomato" }),
        "linkReshapingTool.handleArchetype":
          $(go.Shape, "Diamond", { desiredSize: new go.Size(7, 7), fill: "lightblue", stroke: "deepskyblue" }),
        rotatingTool: $(TopRotatingTool),  // defined below
        "rotatingTool.snapAngleMultiple": 15,
        "rotatingTool.snapAngleEpsilon": 15,
        // don't set some properties until after a new model has been loaded
        "InitialLayoutCompleted": loadDiagramProperties,  // this DiagramEvent listener is defined below
        "undoManager.isEnabled": true
    });

    // when the document is modified, add a "*" to the title and enable the "Save" button
    myDiagram.addDiagramListener("Modified", function(e) {
        var idx = document.title.indexOf("*");
        if (myDiagram.isModified) {
          if (idx < 0) document.title += "*";
        } else {
          if (idx >= 0) document.title = document.title.substr(0, idx);
        }
    });

    // Define a function for creating a "port" that is normally transparent.
    // The "name" is used as the GraphObject.portId, the "spot" is used to control how links connect
    // and where the port is positioned on the node, and the boolean "output" and "input" arguments
    // control whether the user can draw links from or to the port.
    function makePort(name, spot, output, input) {
    // the port is basically just a small transparent square
        return $(go.Shape, "Circle",
        {
            fill: null,  // not seen, by default; set to a translucent gray by showSmallPorts, defined below
            stroke: null,
            desiredSize: new go.Size(7, 7),
            alignment: spot,  // align the port on the main Shape
            alignmentFocus: spot,  // just inside the Shape
            portId: name,  // declare this object to be a "port"
            fromSpot: spot, toSpot: spot,  // declare where links may connect at this port
            fromLinkable: output, toLinkable: input,  // declare whether the user may draw links to/from here
            cursor: "pointer"  // show a different cursor to indicate potential link point
        });
    }

    var nodeSelectionAdornmentTemplate = 
    $(go.Adornment, "Auto",
      $(go.Shape, { fill: null, stroke: "deepskyblue", strokeWidth: 1.5, strokeDashArray: [4, 2] }),
      $(go.Placeholder)
    );

    var nodeResizeAdornmentTemplate = 
    $(go.Adornment, "Spot",
        { locationSpot: go.Spot.Right },
        $(go.Placeholder),
        $(go.Shape, { alignment: go.Spot.TopLeft, cursor: "nw-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),
        $(go.Shape, { alignment: go.Spot.Top, cursor: "n-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),
        $(go.Shape, { alignment: go.Spot.TopRight, cursor: "ne-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),

        $(go.Shape, { alignment: go.Spot.Left, cursor: "w-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),
        $(go.Shape, { alignment: go.Spot.Right, cursor: "e-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),

        $(go.Shape, { alignment: go.Spot.BottomLeft, cursor: "se-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),
        $(go.Shape, { alignment: go.Spot.Bottom, cursor: "s-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" }),
        $(go.Shape, { alignment: go.Spot.BottomRight, cursor: "sw-resize", desiredSize: new go.Size(6, 6), fill: "lightblue", stroke: "deepskyblue" })
    );

    var nodeRotateAdornmentTemplate =
    $(go.Adornment,
        { locationSpot: go.Spot.Center, locationObjectName: "CIRCLE" },
        $(go.Shape, "Circle", { name: "CIRCLE", cursor: "pointer", desiredSize: new go.Size(7, 7), fill: "lightblue", stroke: "deepskyblue" }),
        $(go.Shape, { geometryString: "M3.5 7 L3.5 30", isGeometryPositioned: true, stroke: "deepskyblue", strokeWidth: 1.5, strokeDashArray: [4, 2] })
    );

    myDiagram.nodeTemplate =
    $(go.Node, "Spot",
        { locationSpot: go.Spot.Center },
        new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify),
        { selectable: true, selectionAdornmentTemplate: nodeSelectionAdornmentTemplate },
        { resizable: true, resizeObjectName: "PANEL", resizeAdornmentTemplate: nodeResizeAdornmentTemplate },
        { rotatable: true, rotateAdornmentTemplate: nodeRotateAdornmentTemplate },
        new go.Binding("angle").makeTwoWay(),
        // the main object is a Panel that surrounds a TextBlock with a Shape
        $(go.Panel, "Auto",
            { name: "PANEL" },
            new go.Binding("desiredSize", "size", go.Size.parse).makeTwoWay(go.Size.stringify),
            $(go.Shape, "Rectangle",  // default figure
            {
                portId: "", // the default port: if no spot on link data, use closest side
                fromLinkable: true, toLinkable: true, cursor: "pointer",
                fill: "white"  // default color
            },
            new go.Binding("figure"),
            new go.Binding("fill")),
            $(go.TextBlock,
            {
                font: "bold 11pt Helvetica, Arial, sans-serif",
                margin: 8,
                maxSize: new go.Size(160, NaN),
                wrap: go.TextBlock.WrapFit,
                // editable: true
            },
            new go.Binding("text").makeTwoWay())
        ),
        // four small named ports, one on each side:
        makePort("T", go.Spot.Top, false, true),
        makePort("L", go.Spot.Left, true, true),
        makePort("R", go.Spot.Right, true, true),
        makePort("B", go.Spot.Bottom, true, false),
        { // handle mouse enter/leave events to show/hide the ports
            mouseEnter: function(e, node) { showSmallPorts(node, true); },
            mouseLeave: function(e, node) { showSmallPorts(node, false); }
        }
    );
    var linkSelectionAdornmentTemplate =
    $(go.Adornment, "Link",
      $(go.Shape,
        // isPanelMain declares that this Shape shares the Link.geometry
        { isPanelMain: true, fill: null, stroke: "deepskyblue", strokeWidth: 0 })  // use selection object's strokeWidth
    );

    myDiagram.linkTemplate =
    $(go.Link,  // the whole link panel
      { selectable: true, selectionAdornmentTemplate: linkSelectionAdornmentTemplate },
      { relinkableFrom: true, relinkableTo: true, reshapable: true },
      {
        routing: go.Link.AvoidsNodes,
        curve: go.Link.JumpOver,
        corner: 5,
        toShortLength: 4
      },
      new go.Binding("points").makeTwoWay(),
      $(go.Shape,  // the link path shape
        { isPanelMain: true, strokeWidth: 2 }),
      $(go.Shape,  // the arrowhead
        { toArrow: "Standard", stroke: null }),
      $(go.Panel, "Auto",
        new go.Binding("visible", "isSelected").ofObject(),
        $(go.Shape, "RoundedRectangle",  // the link shape
          { fill: "#F8F8F8", stroke: null }),
        $(go.TextBlock,
          {
            textAlign: "center",
            font: "10pt helvetica, arial, sans-serif",
            stroke: "#919191",
            margin: 2,
            minSize: new go.Size(10, NaN),
            editable: true
          },
          new go.Binding("text", "value").makeTwoWay())
      )
    );

    // load();  // load an initial diagram from some JSON text
    myDiagram.model = go.Model.fromJson(document.getElementById("mySavedModel").value);
    // initialize the Palette that is on the left side of the page
    myPalette =
    $(go.Palette, "myPalette",  // must name or refer to the DIV HTML element
    {
        maxSelectionCount: 1,
        nodeTemplateMap: myDiagram.nodeTemplateMap,  // share the templates used by myDiagram
        linkTemplate: // simplify the link template, just in this Palette
          $(go.Link,
            { // because the GridLayout.alignment is Location and the nodes have locationSpot == Spot.Center,
              // to line up the Link in the same manner we have to pretend the Link has the same location spot
              locationSpot: go.Spot.Center,
              selectionAdornmentTemplate:
                $(go.Adornment, "Link",
                  { locationSpot: go.Spot.Center },
                  $(go.Shape,
                    { isPanelMain: true, fill: null, stroke: "deepskyblue", strokeWidth: 0 }),
                  $(go.Shape,  // the arrowhead
                    { toArrow: "Standard", stroke: null })
                )
            },
            {
              routing: go.Link.AvoidsNodes,
              curve: go.Link.JumpOver,
              corner: 5,
              toShortLength: 4
            },
            new go.Binding("points"),
            $(go.Shape,  // the link path shape
              { isPanelMain: true, strokeWidth: 2 }),
            $(go.Shape,  // the arrowhead
              { toArrow: "Standard", stroke: null })
          ),
        // model: new go.GraphLinksModel(list_stages, [
        //     // the Palette also has a disconnected Link, which the user can drag-and-drop
        //     { points: new go.List(go.Point).addAll([new go.Point(0, 0), new go.Point(30, 0), new go.Point(30, 40), new go.Point(60, 40)]) }
        // ])
            model: new go.GraphLinksModel(list_stages)
            // the Palette also has a disconnected Link, which the user can drag-and-drop
    });
    myPalette.layout.sorting = go.GridLayout.Forward;
}

go.Diagram.inherit(TopRotatingTool, go.RotatingTool);
/** @override */
TopRotatingTool.prototype.updateAdornments = function(part) {
    go.RotatingTool.prototype.updateAdornments.call(this, part);
    var adornment = part.findAdornment("Rotating");
    if (adornment !== null) {
        adornment.location = part.rotateObject.getDocumentPoint(new go.Spot(0.5, 0, 0, -30));  // above middle top
    }
};
function showSmallPorts(node, show) {
    node.ports.each(function(port) {
      if (port.portId !== "") {  // don't change the default port, which is the big shape
        port.fill = show ? "rgba(0,0,0,.3)" : null;
      }
    });
}

function TopRotatingTool() {
    go.RotatingTool.call(this);
}

function loadDiagramProperties(e) {
    var pos = myDiagram.model.modelData.position;
    if (pos) myDiagram.position = go.Point.parse(pos);
}

// /** @override */
TopRotatingTool.prototype.rotate = function(newangle) {
  go.RotatingTool.prototype.rotate.call(this, newangle + 90);
};
// end of TopRotatingTool class


// // Show the diagram's model in JSON format that the user may edit

function saveDiagramProperties() {
    myDiagram.model.modelData.position = go.Point.stringify(myDiagram.position);
}

function load_stream(streamValue, stream_current_id)
{   
    document.getElementById("mySavedModel").value = streamValue;
    $("#stream_current_id").val(stream_current_id);
    myDiagram.model = go.Model.fromJson(streamValue);
}

function saveStreamClick()
{
	
    saveDiagramProperties();  // do this first, before writing to JSON
	
    var myArr = $.parseJSON(myDiagram.model.toJson()); 
    var stage_duplicate = checkDuplicateStage(myArr) 
    if(stage_duplicate != "")
    {
        $('#dialog_save_error').modal("show");
        html = "<p style='color: red'>"+lib_translate("Your update is not successful. Just one stage per stream")+"</p>"
        html += "<p style='color: red'>"+lib_translate_var("stage_duplicate is duplicated", {stage_duplicate:stage_duplicate})+"</p>";
        $(".modal-body-save-error").html(html);
    }
    else
    {
        document.getElementById("mySavedModel").value = myDiagram.model.toJson();
        var stream_id = $("#stream_current_id").val();
        //$("#stream_current_id").val($("#current_stream").val());
        //load_stream_id = $("#current_stream").val();
        var streamValue = $("#mySavedModel").val();
        if(stream_id != "" && stream_id != undefined)
        {
            $.ajax({
              type: "post",
              url: "/mywork/streams" +  "/save_content",
              data:{
                //load_stream_id: load_stream_id,
                streamValue: myArr,
				stream_id: stream_id
              },
              success: function(data)
              {
                myDiagram.isModified = false;
                if($("#check_modified").val() == "create")
                {
                    setTimeout(function() {
                        $("#create_new_stream").click();
                    }, 1000);
                }
                else
                {
                    $("#button_load_stream").click();
                }
                $("#check_modified").val("load");
              },
              error: function(data)
              {
              }
            });   
        }else{
            alert("Missing stream id");
        }
    }
}

function checkDuplicateStage(myArr)
{
    var list_stage = myArr.nodeDataArray;
    if (list_stage != null)
    {
        for(var i = 0; i < list_stage.length; i++) {
            for(var j = i; j < list_stage.length; j++) {
                if(i != j && list_stage[i].value == list_stage[j].value) {
                    return list_stage[i].text;
                }
            }
        }
        return "";
    }
}

function checkModified(type_check)
{
    if (myDiagram.isModified == false) {
        if(type_check == "create")
        {
            $("#create_new_stream").click();
        }
        else
        {
            var stream_id = $("#stream_id").val()
            var current_stream = $("#current_stream").val();
            if(stream_id != "" || stream_id != undefined)
            {
                $("#button_load_stream").click();
            }   
        }
    }
    else
    {
        $("#check_modified").val(type_check);
        $("#popup_save").click();
    }
}

function close_popup_warning()
{
    if($("#check_modified").val() == "create")
    {
        $("#create_new_stream").click();
    }
    else
    {
        $("#button_load_stream").click();
    }
    $("#check_modified").val("load");
}

function reload_stage(stage_id, stage_name)
{
    var myArr = $.parseJSON(myPalette.model.toJson());
    var list_stages = myArr.nodeDataArray;
    var stage = {text: stage_name, key: stage_id, figure: 'RoundedRectangle', fill: 'lightpink', size: '97 46.6'};
    list_stages.splice(1,0,stage);
    var value ={class: "go.GraphLinksModel", 
        linkFromPortIdProperty: "fromPort", 
        linkToPortIdProperty: "toPort", 
        nodeDataArray:  list_stages, 
        linkDataArray: []};
    myPalette.model = go.Model.fromJson(value);
    myPalette.layout.sorting = go.GridLayout.Forward;
    $("#mySavedPalette").val(list_stages);
}
;
