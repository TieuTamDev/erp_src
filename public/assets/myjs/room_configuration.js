document.addEventListener('DOMContentLoaded', () => {
    let userData = [];
    let usersByRoom = {};
    let loadedUsers = false;
    let currentRoomId = null;

    // Tìm kiếm phòng không reload
    document.getElementById('roomSearch').addEventListener('input', function () {
        const kw = this.value.trim().toLowerCase();
        document.querySelectorAll('#roomTable tbody tr').forEach(tr => {
            tr.style.display = tr.innerText.toLowerCase().includes(kw) ? '' : 'none';
        });
    });

    // Chọn số lượng dòng/trang
    document.getElementById('perPageSelect').addEventListener('change', function () {
        const url = new URL(window.location.href);
        url.searchParams.set('per_page', this.value);
        url.searchParams.set('page', 1);
        window.location = url;
    });

    // Hàm mở modal (global để gọi từ HTML)
    window.openModal = async function (id, name) {
        // Chỉ fetch 1 lần duy nhất khi chưa có data
        if (!loadedUsers) {
            showLoadding(true);
            try {
                const res = await fetch(workshifts_get_all_users_path);
                const json = await res.json();
                userData = json.users;
                usersByRoom = json.by_room;
                loadedUsers = true;
            } catch (err) {
                showAlert('Lỗi khi tải danh sách nhân viên!', 'danger');
                return;
            }
        }

        currentRoomId = +id;
        document.getElementById('modalRoomName').textContent = name;
        renderSelected();
        initSelect2();
        showLoadding(false);
    };

    // Khởi tạo Select2 cho users
    function initSelect2() {
        $('#usersSelect').empty().select2({
            data: userData.map(u => ({ id: u.id, text: u.text })),
            dropdownParent: $('#modal-rooms'),
            width: '100%'
        });
        refreshDisabled();
    }

    // Disable các nhân viên đã thuộc phòng khác
    function refreshDisabled() {
        $('#usersSelect option').each(function () {
            const uid = +this.value;
            const u = userData.find(u => u.id === uid);
            $(this).prop('disabled', !!u.sroom);
        });
        $('#usersSelect').trigger('change.select2');
    }

    // Hiển thị danh sách nhân viên đã thêm vào phòng này
    function renderSelected() {
        const wrap = $('#selectedUsers').empty();
        const list = $('<ul class="list-group list-group-flush mb-2"></ul>');
        (usersByRoom[currentRoomId] || []).forEach(uid => {
            const u = userData.find(u => u.id === uid);
            if (u) {
                const li = $(`
        <li class="list-group-item d-flex justify-content-between align-items-center p-2">
          <span>${u.text}</span>
          <button class="btn btn-sm btn-outline-danger btn-remove-user" data-uid="${uid}" title="Xoá"><i class="fas fa-times"></i></button>
        </li>
      `);
                list.append(li);
            }
        });
        wrap.append(list);
    }

    // Thêm nhân viên từ Select2
    $('#usersSelect').on('select2:select', function (e) {
        const uid = +e.params.data.id;
        const u = userData.find(u => u.id === uid);
        // Gỡ khỏi phòng cũ nếu có
        if (u.sroom && usersByRoom[u.sroom]) {
            usersByRoom[u.sroom] = usersByRoom[u.sroom].filter(x => x !== uid);
        }
        // Thêm vào phòng hiện tại
        u.sroom = currentRoomId;
        usersByRoom[currentRoomId] = (usersByRoom[currentRoomId] || []).concat(uid);
        renderSelected();
        refreshDisabled();
        $('#usersSelect').val(null).trigger('change');
    });

    // Xoá nhân viên khỏi phòng
    $('#selectedUsers').on('click', '.btn-remove-user', function(){
        const uid = +$(this).data('uid');
        usersByRoom[currentRoomId] = usersByRoom[currentRoomId].filter(x => x !== uid);
        const u = userData.find(u => u.id === uid);
        if (u) u.sroom = null;
        renderSelected();
        refreshDisabled();
    });

    // Lưu danh sách nhân viên của phòng hiện tại
    document.getElementById('btnSave').addEventListener('click', async function () {
        const user_ids = usersByRoom[currentRoomId] || [];
        try {
            const res = await fetch(`${ERP_PATH}/workshifts/${currentRoomId}/update_sroom_users`, {
                method: 'PATCH',
                headers     : {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                },
                credentials : 'same-origin',
                body: JSON.stringify({ user_ids })
            });
            if (!res.ok) throw new Error();
            $('#modal-rooms').modal('hide');
            showAlert('Lưu thành công!', 'success');
        } catch (err) {
            showAlert('Có lỗi xảy ra khi lưu!', 'danger');
        }
    });
});
