$(document).ready(function () {
    initFileFond();
});
$("#id_cancel_add_singnature").on("click", function () {
    $("#id_add_singnature").css("display", "block");
    $("#id_cancel_add_singnature").css("display", "none");
})
function openFormAddSignature() {
    $("#note_singnature").val("");
    $("#name_singnature").val("");
    $("#render_image").hide();
    $("#form_singnature").attr("action", `/mywork/singnature/create`);
    $("#render_uploadfile_singnture").show();
    $("#singnature_status_active").prop("checked", true);
    $("#isdefault").prop("checked", true);
    $("#label_singnature").html("Thêm chữ ký");
    $("#name-btn-singature").html("Thêm chữ ký");
    $("#id_add_singnature").css("display", "none");
    $("#id_cancel_add_singnature").css("display", "block");
}
function onClickChangeDefault(id) {
    $("#change_id_signature").val(id);
    $("#form_change_default").submit();
}

function openFormUpdateSignature(id, name, url, isdefault, status, note) {
    $("html, body").animate({ scrollTop: 0 }, 100);
    $("#render_uploadfile_singnture").hide();
    $("#form_singnature").attr("action", `/mywork/singnature/update/${id}`);
    $("#render_image").show();
    $("#collapse_signature").addClass("show");
    $("#id_add_singnature").css("display", "none");
    $("#id_cancel_add_singnature").css("display", "block");
    $("#image_singnature").prop("src", "https://capp.bmtu.edu.vn/mdata/hrm/" + url);
    $("#label_singnature").html("Cập nhật chữ ký");
    $("#name-btn-singature").html("Cập nhật chữ ký");

    if (status == "ACTIVE") {
        $("#singnature_status_active").prop("checked", true)
    } else {
        $("#singnature_status_inactive").prop("checked", true)
    }

    if (isdefault == "true") {
        $("#isdefault").prop("checked", true)
    } else {
        $("#isdefault").prop("checked", false)
    }

    $("#note_singnature").val(note);
    $("#name_singnature").val(name);

}



// ============================ Cấu hình upload files ============================
// Autor: Lê Ngọc huy

/**
 * Load thư viện upload hình ảnh
 * @param {Array} resources 
 */
var resources = [
    'filepond.css',
    'filepond.js',

    'filepond-plugin-file-encode.min.js',

    'filepond-plugin-file-validate-type.min.js',
    'filepond-plugin-file-validate-size.min.js',

    'filepond-plugin-image-exif-orientation.min.js',
    'filepond-plugin-image-preview.min.css',
    'filepond-plugin-image-preview.min.js',
    'filepond-plugin-image-crop.min.js',
    'filepond-plugin-image-resize.min.js',
    'filepond-plugin-image-transform.min.js',

    // for use with Pintura Image Editor
    'filepond-plugin-file-poster.min.css',
    'filepond-plugin-file-poster.min.js',
    'filepond-plugin-image-editor.min.js',

].map(function (resource) { return '/mywork/assets/lib_file/' + resource });

/**
 * Load thư viện chỉnh sửa hình ảnh
 * @param {Array} pintura 
 */
var loadPintura = (pintura) => {
    var pondMultiple = FilePond.find(document.querySelector(`#filepond_multiple`));

    // register plugins to use
    pintura.setPlugins(
        pintura.plugin_crop,
        pintura.plugin_finetune,
        pintura.plugin_filter,
    );

    // not needed when using Pintura Image Editor
    pondMultiple.allowImagePreview = false;
    pondMultiple.allowImageTransform = false;
    pondMultiple.allowImageResize = false;
    pondMultiple.allowImageCrop = false;
    pondMultiple.allowImageExifOrientation = false;

    // set Pintura Image Editor props
    pondMultiple.allowFilePoster = true;
    pondMultiple.allowImageEditor = true;
    // pondMultiple.imageEditorInstantEdit = true;

    // FilePond generic properties
    pondMultiple.filePosterMaxHeight = 256;
    pondMultiple.imageEditor = {
        legacyDataToImageState: pintura.legacyDataToImageState,
        createEditor: pintura.openEditor,
        imageReader: [pintura.createDefaultImageReader],
        imageWriter: [
            pintura.createDefaultImageWriter,
            {
                targetSize: {
                    width: 300,
                    height: 300,
                },
            },
        ],
        imageProcessor: pintura.processImage,
        editorOptions: {
            ...pintura.getEditorDefaults(),
            imageCropAspectRatio: 16 / 9,
            cropEnableButtonRotateRight: true,
            cropEnableButtonFlipVertical: true,
            cropSelectPresetOptions: [
                [undefined, 'Custom'],
                [1, 'Square'],

                // shown when cropSelectPresetFilter is set to 'landscape'
                [2 / 1, '2:1'],
                [3 / 2, '3:2'],
                [4 / 3, '4:3'],
                [16 / 10, '16:10'],
                [16 / 9, '16:9'],

                // shown when cropSelectPresetFilter is set to 'portrait'
                [1 / 2, '1:2'],
                [2 / 3, '2:3'],
                [3 / 4, '3:4'],
                [10 / 16, '10:16'],
                [9 / 16, '9:16'],
            ],
        },
    };
}

/**
 * Khởi tạo cấu hình upload và chỉnh sửa hình ảnh
 */
function initFileFond() {
    loadResources(resources).then(function () {

        // register plugins
        FilePond.registerPlugin(
            FilePondPluginFileEncode,
            FilePondPluginFileValidateType,
            FilePondPluginFileValidateSize,
            FilePondPluginImageExifOrientation,
            FilePondPluginImagePreview,
            FilePondPluginImageCrop,
            FilePondPluginImageResize,
            FilePondPluginImageTransform,
            FilePondPluginFilePoster,
            FilePondPluginImageEditor /* for use with Pintura */
        );

        // override default options
        FilePond.setOptions({
            dropOnPage: true,
            dropOnElement: true,
            labelIdle: '<div class="d-flex flex-column align-items-center"><span class="fas fa-plus mb-2"></span><span class="filepond--label-action">Nhấn để thêm hoặc kéo thả chữ ký vào đây</span></div>',
            labelInvalidField: 'Trường chứa các tệp không hợp lệ',
            labelFileWaitingForSize: 'Chờ kích thước',
            labelFileSizeNotAvailable: 'Kích thước không khả dụng',
            labelFileLoading: 'Đang tải...',
            labelFileLoadError: 'Lỗi trong quá trình tải',
            labelFileProcessing: 'Đang tải lên...',
            labelFileProcessingComplete: 'Tải lên hoàn chỉnh',
            labelFileProcessingAborted: 'Tải lên bị hủy',
            labelFileProcessingError: 'Lỗi trong quá trình tải lên',
            labelFileProcessingRevertError: 'Lỗi trong quá trình hoàn nguyên',
            labelFileRemoveError: 'Lỗi trong khi loại bỏ',
            labelTapToCancel: 'Nhấn để hủy',
            labelTapToRetry: 'Nhấn để thử lại',
            labelTapToUndo: 'Nhấn để hoàn tác',
            labelButtonRemoveItem: 'Xóa',
            labelButtonAbortItemLoad: 'Hủy bỏ',
            labelButtonRetryItemLoad: 'Thử lại',
            labelButtonAbortItemProcessing: 'Hủy',
            labelButtonUndoItemProcessing: 'Hoàn tác',
            labelButtonRetryItemProcessing: 'Thử lại',
            labelButtonProcessItem: 'Tải lên',
        });

        // create splash file pond element
        var fields = [].slice.call(document.querySelectorAll('input[name="filepond"]'));
        var ponds = fields.map(function (field, index) {
            return FilePond.create(field, {
                credits: false,
                server: {
                    process: (fieldName, file, metadata, load, error, progress, abort, transfer, options) => {
                        const formData = new FormData();
                        formData.append('image_file', file);
                        formData.append('size', 'auto');

                        fetch('https://api.remove.bg/v1.0/removebg', {
                            method: 'POST',
                            headers: {
                                'X-Api-Key': 'JV53k84EcwK9SzSXrCD1dS5Q', // Replace with your Remove.bg API key
                            },
                            body: formData,
                        })
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('Failed to remove background');
                            }
                            return response.blob();
                        })
                        .then(newFile => {
                            // Create a URL for the new file blob
                            const newFileUrl = URL.createObjectURL(newFile); 
                            $('.filepond--file .filepond--file-poster img').prop('src', newFileUrl)
                            // Append the new file to the form data to send it to your server
                            const uploadFormData = new FormData();
                            uploadFormData.append(fieldName, newFile, file.name);
                            uploadFormData.append('authenticity_token', $('meta[name="csrf-token"]').attr('content'));

                            const request = new XMLHttpRequest();
                            request.open('POST', `/mywork/singnature/upload_file`);
                            request.upload.onprogress = (e) => {
                                progress(e.lengthComputable, e.loaded, e.total);
                            };

                            request.onload = function () {
                                if (request.status >= 200 && request.status < 300) {
                                    load(request.responseText);
                                    if (request.response) {
                                        const data = JSON.parse(request.response);
                                        $('ul#render_file').append(`<input name="media_ids" value="${data.file.id}" style="display: none">`);
                                    }
                                } else {
                                    error('Error');
                                }
                            };

                            request.send(uploadFormData);
                        })
                        .catch(err => {
                            // Append the new file to the form data to send it to your server
                            const uploadFormData = new FormData();
                            uploadFormData.append(fieldName, file, file.name);
                            uploadFormData.append('authenticity_token', $('meta[name="csrf-token"]').attr('content'));

                            const request = new XMLHttpRequest();
                            request.open('POST', `/mywork/singnature/upload_file`);
                            request.upload.onprogress = (e) => {
                                progress(e.lengthComputable, e.loaded, e.total);
                            };

                            request.onload = function () {
                                if (request.status >= 200 && request.status < 300) {
                                    load(request.responseText);
                                    if (request.response) {
                                        const data = JSON.parse(request.response);
                                        $('ul#render_file').append(`<input name="media_ids" value="${data.file.id}" style="display: none">`);
                                    }
                                } else {
                                    error('Error');
                                }
                            };

                            request.send(uploadFormData);
                        });

                        return {
                            abort: () => {
                                request.abort();
                                abort();
                            },
                        };
                    },

                    revert: (uniqueFileId, load, error) => {
                        const formData = new FormData();
                        if (uniqueFileId != undefined && uniqueFileId != null && uniqueFileId != "") {
                            var data = JSON.parse(uniqueFileId);
                            formData.append('id_mediafile', data.file.id);
                            formData.append('authenticity_token', $('meta[name="csrf-token"]').attr('content'));
                        }
                        const request = new XMLHttpRequest();
                        request.open('DELETE', `/mywork/singnature/remove_file`);

                        request.onload = function () {
                            if (request.status >= 200 && request.status < 300) {
                                load(request.responseText);
                                if (request.response != undefined && request.response != null && request.response != "") {
                                    var data = JSON.parse(request.response);
                                }
                            } else {
                                error('Error');
                            }
                        };

                        request.send(formData);
                        error('Error');
                        load();
                    },
                    remove: (source, load, error) => {
                        error('Error');
                        load();
                    },
                },
                allowFilePoster: false,
                allowImageEditor: false,
            });
        });

        // add warning to multiple files pond
        var pondDemoMultiple = ponds[0];
        var pondMultipleTimeout;
        if (pondDemoMultiple && pondDemoMultiple.element) {
            pondDemoMultiple.onwarning = function () {
                var container = pondDemoMultiple.element.parentNode;
                var error = container.querySelector('p.filepond--warning');
                if (!error) {
                    error = document.createElement('p');
                    error.className = 'filepond--warning';
                    error.textContent = 'The maximum number of files is 3';
                    container.appendChild(error);
                }
                requestAnimationFrame(function () {
                    error.dataset.state = 'visible';
                });
                clearTimeout(pondMultipleTimeout);
                pondMultipleTimeout = setTimeout(function () {
                    error.dataset.state = 'hidden';
                }, 10000);
            };
            pondDemoMultiple.onaddfile = function () {
                clearTimeout(pondMultipleTimeout);
                var container = pondDemoMultiple.element.parentNode;
                var error = container.querySelector('p.filepond--warning');
                if (error) {
                    error.dataset.state = 'hidden';
                }
            };
        }

        // set top pond
        pond = ponds[0];
        document.dispatchEvent(new CustomEvent('filepond:ready'))
    });

    loadResources(['/mywork/assets/lib_file/pintura.css']).then(function () {
        import('/mywork/assets/lib_file/pintura.js').then(pintura => {
            if (window.pond) return loadPintura(pintura);
            else {
                document.addEventListener('filepond:ready', () => {
                    loadPintura(pintura)
                })
            }
        })
    });
}