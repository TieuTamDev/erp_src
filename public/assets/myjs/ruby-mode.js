// IIFE để hỗ trợ CommonJS, AMD, hoặc global CodeMirror
(function(mod) {
  if (typeof exports === "object" && typeof module === "object") { // CommonJS
    mod(require("../../lib/codemirror"));
  } else if (typeof define === "function" && define.amd) { // AMD
    define(["../../lib/codemirror"], mod);
  } else { // Global (browser)
    mod(CodeMirror);
  }
})(function(CodeMirror) {
  "use strict";

  // Hàm tạo object từ mảng từ khóa, gán giá trị true
  function createKeywordMap(words) {
    const map = {};
    for (let i = 0; i < words.length; ++i) {
      map[words[i]] = true;
    }
    return map;
  }

  // Danh sách từ khóa Ruby
  const keywords = [
    "alias", "and", "BEGIN", "begin", "break", "case", "class", "def", "defined?",
    "do", "else", "elsif", "END", "end", "ensure", "false", "for", "if", "in",
    "module", "next", "not", "or", "redo", "rescue", "retry", "return", "self",
    "super", "then", "true", "undef", "unless", "until", "when", "while", "yield",
    "nil", "raise", "throw", "catch", "fail", "loop", "callcc", "caller", "lambda",
    "proc", "public", "protected", "private", "require", "load", "require_relative",
    "extend", "autoload", "__END__", "__FILE__", "__LINE__", "__dir__"
  ];

  const railsModelsSet = new Set(SuggestionsObject.model.map(item=>{return item.name}));
  const railsClassSet = new Set(SuggestionsObject.class.map(item=>{return item.name}));
  const railsFunctionSet = new Set(Object.keys(SuggestionsFunction).map(key=>{return SuggestionsFunction[key].map(item=>{return item.name})}).flat());

  // Từ khóa ảnh hưởng thụt lề
  const indentKeywords = createKeywordMap([
    "def", "class", "case", "for", "while", "until", "module", "catch", "loop",
    "proc", "begin"
  ]);

  // Từ khóa giảm thụt lề
  const dedentKeywords = createKeywordMap(["end", "until"]);

  // Cặp dấu ngoặc
  const matchingBrackets = { "[": "]", "{": "}", "(": ")" };
  const closingToOpening = { "]": "[", "}": "{", ")": "(" };

  // Biến lưu dấu hiện tại (dùng trong tokenizer)
  let currentSymbol;

  // Mode Ruby
  CodeMirror.defineMode("ruby", function(config) {
    // Hàm đẩy tokenizer mới vào stack
    function pushTokenizer(tokenizer, stream, state) {
      state.tokenize.push(tokenizer);
      return tokenizer(stream, state);
    }

    // Xử lý comment dạng =begin ... =end
    function blockComment(stream, state) {
      if (stream.sol() && stream.match("=end") && stream.eol()) {
        state.tokenize.pop();
      }
      stream.skipToEnd();
      return "comment";
    }

    // Xử lý chuỗi (string, regexp, atom)
    function readQuoted(quote, style, interpolate) {
      return function(stream, state) {
        let escaped = false;
        let ch;

        // Nếu đang trong trạng thái tạm dừng do interpolation
        if (state.context.type === "read-quoted-paused") {
          state.context = state.context.prev;
          stream.eat("}");
        }

        while ((ch = stream.next()) != null) {
          if (ch === quote && (interpolate || !escaped)) {
            state.tokenize.pop();
            break;
          }

          if (interpolate && ch === "#" && !escaped) {
            if (stream.eat("{")) {
              if (quote === "}") {
                state.context = { prev: state.context, type: "read-quoted-paused" };
              }
              state.tokenize.push(interpolateBlock());
              break;
            }
            if (/[@$]/.test(stream.peek())) {
              state.tokenize.push(interpolateVariable());
              break;
            }
          }
          escaped = !escaped && ch === "\\";
        }
        return style;
      };
    }

    // Xử lý interpolation trong #{...}
    function interpolateBlock(count) {
      count = count || 1;
      return function(stream, state) {
        if (stream.peek() === "}") {
          if (count === 1) {
            state.tokenize.pop();
            return state.tokenize[state.tokenize.length - 1](stream, state);
          }
          state.tokenize[state.tokenize.length - 1] = interpolateBlock(count - 1);
        } else if (stream.peek() === "{") {
          state.tokenize[state.tokenize.length - 1] = interpolateBlock(count + 1);
        }
        return tokenBase(stream, state);
      };
    }

    // Xử lý biến trong interpolation (@var, $var)
    function interpolateVariable() {
      let first = true;
      return function(stream, state) {
        if (first) {
          first = false;
          return tokenBase(stream, state);
        }
        state.tokenize.pop();
        return state.tokenize[state.tokenize.length - 1](stream, state);
      };
    }

    // Tokenizer chính
    function tokenBase(stream, state) {
      currentSymbol = null;

      if (stream.sol() && stream.match("=begin") && stream.eol()) {
        return pushTokenizer(blockComment, stream, state);
      }

      if (stream.eatSpace()) return null;

      const ch = stream.next();

      // Chuỗi, lệnh shell, hoặc atom
      if (ch === "`" || ch === "'" || ch === '"') {
        return pushTokenizer(readQuoted(ch, "string", ch === '"' || ch === "`"), stream, state);
      }

      // Biểu thức chính quy
      if (ch === "/") {
        if (isRegex(stream)) {
          return pushTokenizer(readQuoted(ch, "string-2", true), stream, state);
        }
        return "operator";
      }

      // Chuỗi đặc biệt (%q, %Q, %r, etc.)
      if (ch === "%") {
        let style = "string";
        let interpolate = true;

        if (stream.eat("s")) style = "atom";
        else if (stream.eat(/[WQ]/)) style = "string";
        else if (stream.eat(/[r]/)) style = "string-2";
        else if (stream.eat(/[wxq]/)) {
          style = "string";
          interpolate = false;
        }

        const delim = stream.eat(/[^\w\s=]/);
        if (!delim) return "operator";

        const closingDelim = matchingBrackets.hasOwnProperty(delim) ? matchingBrackets[delim] : delim;
        return pushTokenizer(readQuoted(closingDelim, style, interpolate, true), stream, state);
      }

      // comment
      if (ch === "#") {
        stream.skipToEnd();
        return "comment";
      }

      // Heredoc
      let match = [];
      if (ch === "<" && (match = stream.match(/^<([-~])([`"']?)([a-zA-Z_?]\w*)\2(?:;|$)/))) {
        const heredocName = match[3];
        const indentMarker = match[1];
        return pushTokenizer(readHeredoc(heredocName, indentMarker), stream, state);
      }

      // Number
      if (ch === "0") {
        if (stream.eat("x")) stream.eatWhile(/[\da-fA-F]/);
        else if (stream.eat("b")) stream.eatWhile(/[01]/);
        else stream.eatWhile(/[0-7]/);
        return "number";
      }
      if (/\d/.test(ch)) {
        stream.match(/^[\d_]*(?:\.[\d_]+)?(?:[eE][+\-]?[\d_]+)?/);
        return "number";
      }

      // Atom hoặc ký tự
      if (ch === "?") {
        stream.eat("\\") && stream.eatWhile(/\w/);
        return "string";
      }

      // Biến, từ khóa, hoặc ký hiệu
      if (ch === ":") {
        if (stream.eat("'")) return pushTokenizer(readQuoted("'", "atom", false), stream, state);
        if (stream.eat('"')) return pushTokenizer(readQuoted('"', "atom", true), stream, state);
        if (stream.eat(/[\<\>]/)) {
          stream.eat(/[\<\>]/);
          return "atom";
        }
        if (stream.eat(/[\+\-\*\/\&\|\:\!]/)) return "atom";
        if (stream.eat(/[a-zA-Z$@_\xa1-\uffff]/)) {
          stream.eatWhile(/[\w$\xa1-\uffff]/);
          stream.eat(/[\?\!\=]/);
          return "atom";
        }
        return "operator";
      }

      if (ch === "@" && stream.match(/^@?[a-zA-Z_\xa1-\uffff]/)) {
        stream.eat("@");
        stream.eatWhile(/[\w\xa1-\uffff]/);
        return "variable-2";
      }

      if (ch === "$") {
        if (stream.eat(/[a-zA-Z_]/)) stream.eatWhile(/[\w]/);
        else if (stream.eat(/\d/)) stream.eat(/\d/);
        else stream.next();
        return "variable-3";
      }

      if (/[a-zA-Z_\xa1-\uffff]/.test(ch)) {
        stream.eatWhile(/[\w\xa1-\uffff]/);
        stream.eat(/[\?\!]/);
        if (stream.eat(":")) return "atom";
        const word = stream.current();
        if (railsModelsSet.has(word)) {
            return "model";
        }
        if (railsClassSet.has(word)) {
            return "class";
        }

        return "ident";
      }

      if (ch === "|" && !state.varList && state.lastTok !== "{" && state.lastTok !== "do") {
        currentSymbol = "|";
        return null;
      }

      if (/[\(\)\[\]{}\\;]/.test(ch)) {
        currentSymbol = ch;
        return null;
      }

      if (ch === "-" && stream.eat(">")) return "arrow";

      if (/[=+\-\/*:\.^%<>~|]/.test(ch)) {
        const more = stream.eatWhile(/[=+\-\/*:\.^%<>~|]/);
        if (ch === "." && !more) currentSymbol = ".";
        return "operator";
      }

      return null;
    }

    // Kiểm tra xem có phải regex không
    function isRegex(stream) {
      let pos = stream.pos;
      let depth = 0;
      let escaped = false;
      let found = false;

      let ch;
      while ((ch = stream.next()) != null) {
        if (escaped) {
          escaped = false;
        } else {
          if ("[{(".indexOf(ch) !== -1) depth++;
          else if ("]})".indexOf(ch) !== -1) {
            if (--depth < 0) break;
          } else if (ch === "/" && depth === 0) {
            found = true;
            break;
          }
          escaped = ch === "\\";
        }
      }

      stream.backUp(stream.pos - pos);
      return found;
    }

    // Xử lý heredoc
    function readHeredoc(name, indentMarker) {
      return function(stream, state) {
        if (indentMarker && stream.eatSpace()) {}
        if (stream.match(name)) {
          state.tokenize.pop();
        } else {
          stream.skipToEnd();
        }
        return "string";
      };
    }

    return {
      startState: function() {
        return {
          tokenize: [tokenBase],
          indented: 0,
          context: { type: "top", indented: -config.indentUnit },
          continuedLine: false,
          lastTok: null,
          varList: false
        };
      },

      token: function(stream, state) {
        currentSymbol = null;
        if (stream.sol()) state.indented = stream.indentation();

        const style = state.tokenize[state.tokenize.length - 1](stream, state);
        let currentToken = currentSymbol;

        if (style === "ident") {
          const word = stream.current();
          let newStyle;
          if (currentToken === "." && keywords.hasOwnProperty(word)) {
            newStyle = "property";
          } else if (keywords.hasOwnProperty(word)) {
            newStyle = "keyword";
          } else if (/^[A-Z]/.test(word)) {
            newStyle = "tag";
          } else if (state.lastTok === "def" || state.lastTok === "class" || state.varList) {
            newStyle = "def";
          } else if(railsFunctionSet.has(word)){
            newStyle = "function";
        }else{
            newStyle = "variable";
          }

          let action;
          if (indentKeywords.hasOwnProperty(word)) {
            action = "indent";
          } else if (dedentKeywords.hasOwnProperty(word)) {
            action = "dedent";
          } else if ((word === "if" || word === "unless") && stream.column() === stream.indentation() ||
                    (word === "do" && state.context.indented < state.indented)) {
            action = "indent";
          }

          if (currentToken || (style && style !== "comment")) {
            state.lastTok = currentToken || word;
          }

          if (currentToken === "|") {
            state.varList = !state.varList;
          }

          if (action === "indent" || /[\(\[\{]/.test(currentToken)) {
            state.context = {
              prev: state.context,
              type: currentToken || style,
              indented: state.indented
            };
          } else if (action === "dedent" || /[\)\]\}]/.test(currentToken)) {
            if (state.context.prev) {
              state.context = state.context.prev;
            }
          }

          if (stream.eol()) {
            state.continuedLine = currentToken === "\\" || style === "operator";
          }

          return newStyle;
        }

        if (currentToken || (style && style !== "comment")) {
          state.lastTok = currentToken;
        }

        if (currentToken === "|") {
          state.varList = !state.varList;
        }

        if (style === "indent" || /[\(\[\{]/.test(currentToken)) {
          state.context = {
            prev: state.context,
            type: currentToken || style,
            indented: state.indented
          };
        } else if ((style === "dedent" || /[\)\]\}]/.test(currentToken)) && state.context.prev) {
          state.context = state.context.prev;
        }

        if (stream.eol()) {
          state.continuedLine = currentToken === "\\" || style === "operator";
        }

        return style;
      },

      indent: function(state, textAfter) {
        if (state.tokenize[state.tokenize.length - 1] !== tokenBase) {
          return CodeMirror.Pass;
        }

        const firstChar = textAfter && textAfter.charAt(0);
        const context = state.context;
        const closing = context.type === closingToOpening[firstChar] ||
                       context.type === "keyword" && /^(?:end|until|else|elsif|when|rescue)\b/.test(textAfter);

        return context.indented + (closing ? 0 : config.indentUnit) +
               (state.continuedLine ? config.indentUnit : 0);
      },

      electricInput: /^\s*(?:end|rescue|elsif|else|\})$/,
      lineComment: "#",
      fold: "indent"
    };
  });

  CodeMirror.defineMIME("text/x-ruby", "ruby");

  // Đăng ký từ khóa cho gợi ý
  CodeMirror.registerHelper("hintWords", "ruby", keywords);
});