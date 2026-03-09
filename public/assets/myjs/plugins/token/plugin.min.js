// Author: H.Vu
(function () {
  'use strict';

  var g_pluginManager = tinymce.util.Tools.resolve('tinymce.PluginManager');

  var g_DOMUtils = tinymce.util.Tools.resolve('tinymce.dom.DOMUtils');

  var g_tools = tinymce.util.Tools.resolve('tinymce.util.Tools');

  const openDialogInsertToken = (editor) => {
    editor.windowManager.open({
      title: 'Chèn token',
      body: {
        type: 'panel',
        items: [
          {
            type: 'listbox',
            name: 'default_token_list',
            label: 'Chọn token mặc định',
            items: [{text: 'Chọn token',value:''},...getDefaultToken(editor)]
          },
          {
            type: 'label', // component type
            label: '----- Hoặc -----', // text for the group label
            items: [] // array of panel components
          },
          {
            type: 'input',
            name: 'token_name',
            label: 'Token tùy chỉnh',
            inputMode: 'text'
          },
        ]
      },
      buttons: [
        {
          type: 'cancel',
          text: 'Đóng'
        },
        {
          type: 'submit',
          text: 'Chèn',
          buttonType: 'primary'
        }
      ],
      onSubmit: (api) => {
        const data = api.getData();
        if (data.token_name.trim().length > 0){
          insertToken(editor,data.token_name);
        }
      },
      onChange: function (dialogApi, details) {
        if (details.name == "default_token_list"){
          let value = dialogApi.getData().default_token_list;
          insertToken(editor,value);
        }
      },
    });
  }
  
  var insertToken = function (editor,token_name){
    token_name = token_name.trim();
    if(token_name.length == 0){
      return;
    }

    let wrap_token = $('<span></span>');
    wrap_token.attr("contenteditable","false");
    wrap_token.attr("data-token-name",token_name);
    let token_display = $('<span></span>');
    token_display.attr('class', 'token-display');
    token_display.text(token_name);
    wrap_token.append(token_display);
    editor.insertContent(wrap_token.prop('outerHTML'));
    editor.windowManager.close();
  }

  var register_commands = function (editor) {
    editor.addCommand('mceInsertToken', function () {
      openDialogInsertToken(editor);
    });
  };

  var register_controls = function (editor) {
    editor.ui.registry.addButton('token', {
      icon: 'token',
      tooltip: 'Token',
      text: 'Tokens',
      onAction: function () {
        return editor.execCommand('mceInsertToken');
      }
    });
  };

  var getDefaultToken = function (editor){
    return editor.getParam('default_tokens') || []
  }

  // Register plugin
  function Plugin () {
    g_pluginManager.add('token', function (editor) {
      register_controls(editor);
      register_commands(editor);
    });
  }

  Plugin();

}());
