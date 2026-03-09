document.addEventListener("DOMContentLoaded", function () {
  const appointsurveyId = document.getElementById('appointsurvey-id').value;
  if (appointsurveyId) {
    fetchSurveyData(appointsurveyId);
  }

  const style = document.createElement('style');
  style.innerHTML = `
    .options-shared, .options-container {
      display: flex;
      justify-content: space-between;
      align-items: center;
      height: 40px;
    }
    .options-shared .form-check-inline,
    .options-container .form-check-inline {
      margin: 0;
      text-align: center;
      flex: 1;
    }
    .options-container {
      padding-left: 15px;
    }
    .options-container .form-check-input {
      margin-top: 0;
    }
    .card .row {
      align-items: center;
    }
  `;
  document.head.appendChild(style);
});

function toggleConclusionNote() {
  const conclusionNo = document.getElementById('conclusion-no');
  const conclusionNoteContainer = document.getElementById('conclusion-note-container');
  if (conclusionNo && conclusionNoteContainer) {
    conclusionNoteContainer.style.display = conclusionNo.checked ? 'block' : 'none';
  }
}

function fetchSurveyData(appointsurveyId) {
  showLoadding(true);
  fetch(root_path + 'survey/load_survey', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({ appointsurvey_id: appointsurveyId })
  })
  .then(response => response.json())
  .then(data => {
    showLoadding(false);
    if (data.success) {
      loadSurvey(data.survey_data);
    } else {
      console.error('Error:', data.errors);
      alert('Không thể tải khảo sát: ' + data.errors);
    }
  })
  .catch(error => {
    console.error('Fetch error:', error);
    alert('Có lỗi xảy ra khi tải khảo sát!');
  });
}

function loadSurvey(surveyData) {
  const container = document.getElementById('survey-container');
  if (!container || !surveyData.groups) {
    console.log('No survey data or container found');
    return;
  }

  container.innerHTML = '';

  surveyData.groups.forEach((group, index) => {
    const groupHtml = `
      <div style="background:#5797EA; width: 100px; color: #FFFFFF; padding: 10px; align-items: center; display: flex; border-radius: 10px 10px 0px 0px; justify-content: center;font-weight: 600;">
        Phần ${index + 1}
      </div>
      <div class="mb-4 group-section card card-body">
        <h5 class="mb-3">${group.name || 'Nhóm câu hỏi'}<span style="color:red">*</span></h5>
        <div class="row mb-3">
          <div class="col-6"></div>
          <div class="col-6 options-shared">
            ${group.options.map(option => `
              <div class="form-check form-check-inline">
                <label class="form-check-label">${option.content}</label>
              </div>
            `).join('')}
          </div>
        </div>
        <div class="questions-container" id="group-${group.id}">
          ${group.questions.map(question => `
            <div class="mb-3 p-3" style="background: #F4F7F8;border-radius: 8px;" data-qsurvey-id="${question.id}">
              <div class="row">
                <div class="col-6">
                  <p class="mb-0">${question.content}</p>
                </div>
                <div class="col-6 options-container">
                  ${question.option_ids.map((option_id, index) => {
                    const isChecked = String(question.selected_answer) === String(option_id);
                    return `
                      <div class="form-check-inline">
                        <input class="form-check-input" type="radio" name="question-${question.id}" value="${option_id}" id="option-${option_id}"
                          onchange="saveAnswer(${question.id}, '${option_id}')" style="border: 1px solid #5272E9; margin-left: 40px;"
                          ${isChecked ? 'checked' : ''}>
                      </div>
                    `;
                  }).join('')}
                </div>
              </div>
            </div>
          `).join('')}
        </div>
        <div class="mt-3">
          <label for="note-${group.id}" class="form-label">Ý kiến khác:</label>
          <textarea class="form-control" id="note-${group.id}" rows="3" placeholder="Nhập ý kiến của bạn (nếu có)">${group.note || ''}</textarea>
        </div>
      </div>
    `;
    container.insertAdjacentHTML('beforeend', groupHtml);
  });

  const conclusionHtml = `
    <div style="background:#5797EA; width: 100px; color: #FFFFFF; padding: 10px; align-items: center; display: flex; border-radius: 10px 10px 0px 0px; justify-content: center;font-weight: 600;">
     Phần ${surveyData.groups.length + 1}
    </div>
    <div class="mb-4 group-section card card-body">
      <h5 class="mb-3">Kết luận chung<span style="color:red">*</span></h5>
      <div class="row mb-3">
        <div class="col-12">
          <div class="form-check">
            <input class="form-check-input" type="radio" name="conclusion" id="conclusion-yes" value="approved">
            <label class="form-check-label" for="conclusion-yes">Đồng ý bổ nhiệm</label>
          </div>
          <div class="form-check">
            <input class="form-check-input" type="radio" name="conclusion" id="conclusion-no" value="rejected">
            <label class="form-check-label" for="conclusion-no">Không đồng ý bổ nhiệm</label>
          </div>
        </div>
      </div>
      <div id="conclusion-note-container" style="display: none;">
        <label for="conclusion-note" class="form-label">ĐỀ XUẤT ỨNG VIÊN PHÙ HỢP, NẾU CÓ (Ứng viên ? Lý do đề xuất, lý do cụ thể)</label>
        <textarea class="form-control" id="conclusion-note" rows="3" placeholder="Vui lòng nhập"></textarea>
      </div>
    </div>
  `;
  container.insertAdjacentHTML('beforeend', conclusionHtml);

  container.insertAdjacentHTML('beforeend', `
    <div class="text-end mt-4">
      <button class="btn" style="background: #2C7BE5; color: white;" onclick="submitAllAnswers()">Gửi khảo sát </button>
    </div>
  `);

  // Gắn sự kiện change Police cho radio buttons
  const conclusionYes = document.getElementById('conclusion-yes');
  const conclusionNo = document.getElementById('conclusion-no');
  if (conclusionYes && conclusionNo) {
    conclusionYes.addEventListener('change', toggleConclusionNote);
    conclusionNo.addEventListener('change', toggleConclusionNote);
  }

  // Gọi toggleConclusionNote để đảm bảo trạng thái ban đầu
  toggleConclusionNote();
}

function saveAnswer(qsurveyId, answer) {
  const appointsurveyId = document.getElementById('appointsurvey-id').value;
  fetch(root_path + 'survey/submit_answer', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({
      appointsurvey_id: appointsurveyId,
      qsurvey_id: qsurveyId,
      answer: answer
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      
    } else {
      console.error('Error:', data.errors);
      alert('Không thể lưu đáp án: ' + data.errors);
    }
  })
  .catch(error => {
    console.error('Fetch error:', error);
    alert('Có lỗi xảy ra khi lưu đáp án!');
  });
}

function submitAllAnswers() {
  if (!window.confirm('Xác nhận gửi khảo sát')) {
    return;
  }

  const appointsurveyId = document.getElementById('appointsurvey-id').value;
  const answers = [];
  const notes = [];
  let conclusion = null;

  let allQuestionsAnswered = true;
  document.querySelectorAll('.questions-container').forEach(container => {
    const questionElements = container.querySelectorAll('div.mb-3.p-3');
    questionElements.forEach(questionElement => {
      const qsurveyId = questionElement.getAttribute('data-qsurvey-id');
      const radioButtons = questionElement.querySelectorAll('.options-container input[type="radio"]');
      let hasSelected = false;
      radioButtons.forEach(radio => {
        if (radio.checked) {
          hasSelected = true;
          answers.push({
            qsurvey_id: qsurveyId,
            answer: radio.value,
            dtanswer: new Date().toISOString()
          });
        }
      });
      if (!hasSelected) {
        allQuestionsAnswered = false;
      }
    });
  });

  if (!allQuestionsAnswered) {
    alert('Vui lòng chọn đáp án cho tất cả các câu hỏi trong mỗi phần!');
    return;
  }

  document.querySelectorAll('.group-section').forEach(group => {
    const questionsContainer = group.querySelector('.questions-container');
    if (questionsContainer && questionsContainer.id) {
      const gsurveyId = questionsContainer.id.replace('group-', '');
      const noteElement = group.querySelector(`#note-${gsurveyId}`);
      if (noteElement) {
        const note = noteElement.value.trim();
        if (note) {
          notes.push({
            gsurvey_id: gsurveyId,
            note: note
          });
        }
      }
    }
  });

  const conclusionElement = document.querySelector('input[name="conclusion"]:checked');
  if (!conclusionElement) {
    alert('Vui lòng chọn Kết luận chung (Đồng ý hoặc Không đồng ý bổ nhiệm)!');
    return;
  }
  conclusion = conclusionElement.value;

  let conclusionNote = '';
  if (conclusion === 'rejected') {
    const conclusionNoteElement = document.getElementById('conclusion-note');
    conclusionNote = conclusionNoteElement.value.trim();
    if (!conclusionNote) {
      alert('Vui lòng nhập lý do từ chối!');
      return;
    }
  }

  const payload = {
    appointsurvey_id: appointsurveyId,
    answers: answers,
    notes: notes,
    conclusion: conclusion,
    conclusion_note: conclusionNote
  };

  showLoadding(true);
  fetch(root_path + 'survey/submit_all_answers', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify(payload)
  })
  .then(response => response.json())
  .then(data => {
    showLoadding(false);
    if (data.success) {
      alert('Đã lưu toàn bộ đáp án và ý kiến thành công!');
      window.location.replace(root_path);
    } else {
      alert('Lỗi: ' + (data.errors || 'Không thể lưu toàn bộ'));
    }
  })
  .catch(error => {
    console.error('Fetch error:', error);
    alert('Có lỗi xảy ra khi lưu toàn bộ!');
  });
}