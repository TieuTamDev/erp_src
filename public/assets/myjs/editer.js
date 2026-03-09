// Khởi tạo CodeMirror
let stringVars = [];
let numberVars = [];
let instanceVars = [];
var codeMirror = CodeMirror.fromTextArea(document.getElementById("code-editer"), {
        mode: "ruby",
        theme: "default",
        lineNumbers: false,
        lineWrapping: true,
        extraKeys: { "Ctrl-Space": "autocomplete" },
        hintOptions: {
            completeSingle: false,
            closeOnUnfocus: true
        }
});

// Tùy chỉnh gợi ý
CodeMirror.registerHelper("hint", "ruby", function (editor) {
    var {suggestions, cursor,current_token,isTypeDot} = GetSuggestions(editor);
    return {
        list: suggestions.map(suggestion => ({
            text: `${suggestion.text}${suggestion.suffix}`,
            render: function (element, self, data) {
                element.innerHTML = `
                    <svg style="color:${GetIconColor(suggestion.meta)}" class="suggestion-icon" width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" fill="currentColor">
                        <path d="${GetIconPath(suggestion.meta)}"/>
                    </svg>
                    <span class="suggestion-value">${suggestion.displayText}</span>
                    <span class="suggestion-meta">${suggestion.meta}</span>`;
            },
            hint: function (cm, data, completion) {
                cm.replaceRange(completion.text, data.from, data.to);
                // xử lý con trỏ với "()"
                if (completion.text.endsWith("()")) {
                    var cur = cm.getCursor();
                    cm.setCursor({ line: cur.line, ch: cur.ch - 1 });
                }
            }
        })),
        from: isTypeDot ? CodeMirror.Pos(cursor.line, current_token.end) :  CodeMirror.Pos(cursor.line, current_token.start),
        to: CodeMirror.Pos(cursor.line, current_token.end)
    };
});

codeMirror.on("inputRead", function (editor, change) {
    GetLineContent(editor);
    UpdateVariableStore(editor);
    if (change.text[0].match(/[a-zA-Z0-9@]/) || editor.getTokenAt(editor.getCursor()).string.length > 0) {
        editor.showHint({
            completeSingle: false,
            hint: CodeMirror.hint.ruby,
            completeOnSingleClick: true
        });
    }
});




function UpdateVariableStore(editor) {
    
    stringVars = [];
    numberVars = [];
    instanceVars = [];

    // Regex để nhận diện biến và hàm
    const varRegex = /^(\s*@?\w+)\s*=\s*([^\n]+)/; // Nhận diện biến và giá trị trong một dòng

    // Tách mã nguồn thành từng dòng
    const lines = editor.getValue().split("\n").slice(0,editor.getCursor().line);
    
    // Phân tích biến từng dòng
    lines.forEach(line => {
        const varMatch = line.match(varRegex);
        if (varMatch) {
            const varName = varMatch[1].trim();
            const value = varMatch[2].trim();
            if (varName.startsWith("@")) {
                instanceVars.push(varName);
            } else if (value.match(/^['"].*['"]$/)) {
                stringVars.push(varName);
            } else if (value.match(/^\d+(\.\d+)?$/)) {
                numberVars.push(varName);
            }
        }
    });
}

function GetLineContent(editor) {

    let beginToken = null;
    let nearFuncToken = null;

    let cursor = editor.getCursor();
    let tokens = editor.getLineTokens(cursor.line);
    let index = tokens.findIndex(token=>{ return token.start <= cursor.ch && token.end >= cursor.ch});

    let operators = ["=", "+" , "-" , "*", "/", "=="];
    let objects = ["class", "model"];

    // trạng thái chấm:
    let current_token = editor.getTokenAt(cursor);
    let isTypeDot = current_token.string == ".";
    let prevToken = editor.getTokenAt({ line: cursor.line, ch: current_token.start });
    let isTypeDotFunc = prevToken.string == ".";

    // Tìm token đầu
    for (let i = index; i >= 0 ; i--) {

        // get begin token
        let checkToken = tokens[i];
        if(operators.includes(checkToken.string)){
            beginToken = CloneObject(tokens[i+1]);
            break;
        }else if (i == 0 || checkToken.string == " " || objects.includes(checkToken.type) || checkToken.type == "variable" && !isTypeDotFunc){
            beginToken = CloneObject(checkToken);
            break;
        }
        // get pre token
        if(!nearFuncToken){
            checkToken = tokens[i-1];
            if(checkToken.type == "function"){
                nearFuncToken = CloneObject(checkToken);
            }
        }
    }

    return { beginToken ,nearFuncToken ,current_token, isTypeDot,isTypeDotFunc,cursor}
    
}

function GetSuggestions(editor) {
    var {beginToken,nearFuncToken,current_token,isTypeDot,isTypeDot,isTypeDotFunc,cursor} = GetLineContent(editor);

    let current_value = current_token.string.trim();
    if(isTypeDot){
        current_value = "";
    }


    if (isTypeDot || isTypeDotFunc) {
        // Gợi ý các hàm cho biến || class || object
        if (["string","number","model"].includes(beginToken.type)){
            suggestions = MakeToSuggesList(SuggestionsFunction[beginToken.type],"method");
        }else if(beginToken.type == "variable"){
            if(stringVars.includes(beginToken.string)){
                suggestions = MakeToSuggesList(stringVars,"variable");
            }else if(numberVars.includes(beginToken.string)){
                suggestions = MakeToSuggesList(numberVars,"variable");
            }
        }else{
            suggestions = MakeToSuggesList(SuggestionsFunction[beginToken.string],beginToken.type);
        }
    }
    else{
        // gợi ý các tên biến, class, model
        suggestions = [
            ...MakeToSuggesList(stringVars,"variable"),
            ...MakeToSuggesList(numberVars,"variable"),
            ...MakeToSuggesList(instanceVars,"variable"),
            ...MakeToSuggesList(SuggestionsObject.class,"class"),
            ...MakeToSuggesList(SuggestionsObject.model,"model"),
        ];
    }

    if(suggestions.length == 0){
        console.warn(`không tìm thấy functions cho begin_type:${beginToken.type} searchValue: ${current_value}`);
    }
    
    // Lọc gợi ý
    if(current_value.length > 0){
        suggestions = suggestions.filter(s => s.displayText.startsWith(current_token.string));
    }

    return {suggestions,cursor,current_token,isTypeDot};
}

function MakeToSuggesList(datas,meta) {
    if(!datas){
        return [];
    }
    let result = datas.map(data=>({
        text: data.name || data,
        displayText: data.name || data,
        meta:meta,
        suffix: data.suffix || ""
    }));
    return result.sort((a, b) => a.text.length - b.text.length);
}

function GetIconPath(meta) {
    switch (meta) {
        case "method":
            return "M13.51 4l-5-3h-1l-5 3-.49.86v6l.49.85 5 3h1l5-3 .49-.85v-6L13.51 4zm-6 9.56l-4.5-2.7V5.7l4.5 2.45v5.41zM3.27 4.7l4.74-2.84 4.74 2.84-4.74 2.59L3.27 4.7zm9.74 6.16l-4.5 2.7V8.15l4.5-2.45v5.16z";
        case "variable":
            return "M2 5h2V4H1.5l-.5.5v8l.5.5H4v-1H2V5zm12.5-1H12v1h2v7h-2v1h2.5l.5-.5v-8l-.5-.5zm-2.74 2.57L12 7v2.51l-.3.45-4.5 2h-.46l-2.5-1.5-.24-.43v-2.5l.3-.46 4.5-2h.46l2.5 1.5zM5 9.71l1.5.9V9.28L5 8.38v1.33zm.58-2.15l1.45.87 3.39-1.5-1.45-.87-3.39 1.5zm1.95 3.17l3.5-1.56v-1.4l-3.5 1.55v1.41z";
        case "class":
            return "M11.34 9.71h.71l2.67-2.67v-.71L13.38 5h-.7l-1.82 1.81h-5V5.56l1.86-1.85V3l-2-2H5L1 5v.71l2 2h.71l1.14-1.15v5.79l.5.5H10v.52l1.33 1.34h.71l2.67-2.67v-.71L13.37 10h-.7l-1.86 1.85h-5v-4H10v.48l1.34 1.38zm1.69-3.65l.63.63-2 2-.63-.63 2-2zm0 5l.63.63-2 2-.63-.63 2-2zM3.35 6.65l-1.29-1.3 3.29-3.29 1.3 1.29-3.3 3.3z";
        case "model":
            return "M13.5 2h-12l-.5.5v11l.5.5h12l.5-.5v-11l-.5-.5zM2 3h11v1H2V3zm7 4H6V5h3v2zm0 1v2H6V8h3zM2 5h3v2H2V5zm0 3h3v2H2V8zm0 5v-2h3v2H2zm4 0v-2h3v2H6zm7 0h-3v-2h3v2zm0-3h-3V8h3v2zm-3-3V5h3v2h-3z"
        default:
        return "";
    }
}

function GetIconColor(meta) {
    switch (meta) {

    case "method":
        return "#b180d7";
    case "variable":
        return "#75beff";
    case "model":
        return "39a0cc";
    case "class":
        return "#ee9d28";
    default:
        return "unset"
    }
}

function CloneObject(object) {
    if(!object){
        return null;
    }
    return JSON.parse(JSON.stringify(object));
}