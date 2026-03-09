let groupCount = 0;
let deletedQuestionIds = [];
let deletedGroupIds = [];
let isUseClass = ""
if (is_use){
    isUseClass = "d-none"
}

// Lựa chọn mặc định cố định
const DEFAULT_OPTIONS = [
  "Không hài lòng",
  "Bình thường",
  "Hài lòng",
  "Rất hài lòng"
];

document.addEventListener("DOMContentLoaded", function () {
  const surveyDataElement = document.getElementById('survey-data');
  if (surveyDataElement) {
    const surveyData = JSON.parse(surveyDataElement.dataset.surveyData || '{}');
    groupCount = surveyData.groups ? surveyData.groups.length : 0;
    loadSurveyData(surveyData);
  } else {
    console.log('Survey Data Element not found');
  }
  ensureGroupTabsExists();
  ensureGroupsContainerExists();
  updateSortable();
});

function loadSurveyData(surveyData) {
  if (!surveyData || !surveyData.groups || surveyData.groups.length === 0) {
    console.log('No groups found in survey data');
    return;
  }

  const container = document.getElementById('groups-container');
  if (!container) {
    console.log('Container not found');
    return;
  }

  container.innerHTML = '';

  surveyData.groups.forEach(group => {
    groupCount += 1;
    const groupId = `group-${group.id}`;
    const groupOptions = gsurveys.map(g => 
      `<option value="${g.id}" ${g.id === group.id ? 'selected' : ''}>${g.name}</option>`
    ).join('');

    const groupHtml = `
      <div class="mb-3 group-content" id="${groupId}" data-gsurvey-id="${group.id}">
        <div class="d-flex justify-content-between" style="background: #F9FAFD;padding-bottom: 10px;">
          <input type="hidden" class="iorder" value="${groupCount}">
          <select class="form-select group-name" style="color: white;padding: 10px 25px 10px 10px;border-radius: 10px 10px 0px 0px;width: 15%;">
            ${groupOptions}
          </select>
          <div class="d-flex justify-content-between ${isUseClass}"  style="width: 25%;">
            <button class="btn" style="background: #FDEDF0;color: #E63757;" onclick="removeGroup('${groupId}')"><span class="fas fa-trash-alt"></span></button>
            <button class="btn" style="background: #E8F1FC;color: #2C7BE5;" onclick="copyGroup('${groupId}')"><span class="fas fa-copy"></span></button>
            <button class="btn" style="background: #E8F1FC;color: #2C7BE5;" onclick="addQuestion('${groupId}')"><span class="fas fa-plus"></span> Thêm câu hỏi</button>
          </div>
        </div>
        <div class="card card-body">
          <div class="questions-container mt-3" id="questions-${groupId}"></div>
        </div>
      </div>
    `;
    container.insertAdjacentHTML('beforeend', groupHtml);

    const questionsContainer = document.getElementById(`questions-${groupId}`);
    group.questions.forEach((question, qIndex) => {
      const questionId = `question-${groupId}-${question.id}`;
      const questionHtml = `
        <div class="card mb-2 p-2 question-item" id="${questionId}" data-qsurvey-id="${question.id}">
          <input type="hidden" class="iorder" value="${question.position}">
          <div class="text-center mb-2 drag-handle" style="cursor: move;">
            <span class="text-muted">...</span>
          </div>
          <div class="d-flex justify-content-between">
            <input type="text" class="form-control w-50" value="${question.content}">
          </div>
          <div class="options-container mt-2 row" id="options-${questionId}">
            <div class="col-6 d-flex align-items-center mb-2" data-option-id="${question.options[0]?.id || ''}">
              <input type="radio" disabled class="me-2">
              <span>${DEFAULT_OPTIONS[0]}</span>
            </div>
            <div class="col-6 d-flex align-items-center mb-2" data-option-id="${question.options[1]?.id || ''}">
              <input type="radio" disabled class="me-2">
              <span>${DEFAULT_OPTIONS[1]}</span>
            </div>
            <div class="col-6 d-flex align-items-center mb-2" data-option-id="${question.options[2]?.id || ''}">
              <input type="radio" disabled class="me-2">
              <span>${DEFAULT_OPTIONS[2]}</span>
            </div>
            <div class="col-6 d-flex align-items-center mb-2" data-option-id="${question.options[3]?.id || ''}">
              <input type="radio" disabled class="me-2">
              <span>${DEFAULT_OPTIONS[3]}</span>
            </div>
          </div>
          <hr>
          <div class="d-flex justify-content-end">
            <div class="form-check form-switch d-none">
              <input class="form-check-input" type="checkbox" id="required-${questionId}" ${question.required ? 'checked' : ''}>
              <label class="form-check-label" for="required-${questionId}">Bắt buộc</label>
            </div>
            <div>
              <button class="btn d-none" style="color: #6A6E73;" onclick="copyQuestion('${questionId}', '${groupId}')"><span class="fas fa-copy"></span></button>
              <button class="btn ${isUseClass}" style="color: #E63757;" onclick="removeElement('${questionId}')"><span class="fas fa-trash-alt"></span></button>
            </div>
          </div>
        </div>
      `;
      questionsContainer.insertAdjacentHTML('beforeend', questionHtml);
    });
  });

  updateSortable();
}

function ensureGroupTabsExists() {
  if (!document.getElementById("group-tabs")) {
    document.getElementById("survey-content").insertAdjacentHTML("afterbegin", '<div id="group-tabs"></div>');
  }
}

function ensureGroupsContainerExists() {
  if (!document.getElementById("groups-container")) {
    document.getElementById("survey-content").insertAdjacentHTML("beforeend", '<div id="groups-container"></div>');
  }
}

function addGroup(name = null) {
  let groupId = `group-new-${Date.now()}`;
  let groupName = name ? name : `Nhóm ${document.querySelectorAll(".group-content").length + 1}`;
  ensureGroupTabsExists();
  ensureGroupsContainerExists();

  let groupOptions = gsurveys.map(group => 
    `<option value="${group.id}">${group.name}</option>`
  ).join('');

  let groupHtml = `
    <div class="mb-3 group-content" id="${groupId}">
      <div class="d-flex justify-content-between" style="background: #F9FAFD;padding-bottom: 10px;">
        <input type="hidden" class="iorder" value="${document.querySelectorAll(".group-content").length + 1}">
        <select class="form-select group-name" style="color: white;padding: 10px 25px 10px 10px;border-radius: 10px 10px 0px 0px;width: 15%;">
          ${groupOptions}
        </select>
        <div class="d-flex justify-content-between ${isUseClass}" style="width: 25%;">
          <button class="btn" style="background: #FDEDF0;color: #E63757;" onclick="removeGroup('${groupId}')"><span class="fas fa-trash-alt"></span></button>
          <button class="btn" style="background: #E8F1FC;color: #2C7BE5;" onclick="copyGroup('${groupId}')"><span class="fas fa-copy"></span></button>
          <button class="btn" style="background: #E8F1FC;color: #2C7BE5;" onclick="addQuestion('${groupId}')"><span class="fas fa-plus"></span> Thêm câu hỏi</button>
        </div>
      </div>
      <div class="card card-body">
        <div class="questions-container mt-3" id="questions-${groupId}"></div>
      </div>
    </div>
  `;

  document.getElementById("groups-container").insertAdjacentHTML("beforeend", groupHtml);
  updateSortable();
}

function copyGroup(groupId) {
  const originalGroup = document.getElementById(groupId);
  const selectElement = originalGroup.querySelector(".group-name");
  const newGroupId = `group-new-${Date.now()}`;

  const groupHtml = `
    <div class="mb-3 group-content" id="${newGroupId}">
      <div class="d-flex justify-content-between" style="background: #F9FAFD;padding-bottom: 10px;">
        <input type="hidden" class="iorder" value="${document.querySelectorAll(".group-content").length + 1}">
        <select class="form-select group-name" style="color: white;padding: 10px 25px 10px 10px;border-radius: 10px 10px 0px 0px;width: 15%;">
          ${selectElement.innerHTML}
        </select>
        <div class="d-flex justify-content-between ${isUseClass}" style="width: 25%;">
          <button class="btn" style="background: #FDEDF0;color: #E63757;" onclick="removeGroup('${newGroupId}')"><span class="fas fa-trash-alt"></span></button>
          <button class="btn" style="background: #E8F1FC;color: #2C7BE5;" onclick="copyGroup('${newGroupId}')"><span class="fas fa-copy"></span></button>
          <button class="btn" style="background: #E8F1FC;color: #2C7BE5;" onclick="addQuestion('${newGroupId}')"><span class="fas fa-plus"></span> Thêm câu hỏi</button>
        </div>
      </div>
      <div class="card card-body">
        <div class="questions-container mt-3" id="questions-${newGroupId}"></div>
      </div>
    </div>
  `;

  document.getElementById("groups-container").insertAdjacentHTML("beforeend", groupHtml);
  const newQuestionsContainer = document.getElementById(`questions-${newGroupId}`);

  const originalQuestions = originalGroup.querySelectorAll('.question-item');
  originalQuestions.forEach((question, qIndex) => {
    const originalQuestionText = question.querySelector('input[type="text"]').value;
    const isRequired = question.querySelector('input[type="checkbox"]').checked;
    const newQuestionId = `question-${newGroupId}-${qIndex}-${Date.now()}`;

    const questionHtml = `
      <div class="card mb-2 p-2 question-item" id="${newQuestionId}">
        <input type="hidden" class="iorder" value="${qIndex + 1}">
        <div class="text-center mb-2 drag-handle" style="cursor: move;">
          <span class="text-muted">...</span>
        </div>
        <div class="d-flex justify-content-between">
          <input type="text" class="form-control w-50" value="${originalQuestionText} (copy)">
        </div>
        <div class="options-container mt-2 row" id="options-${newQuestionId}">
          <div class="col-6 d-flex align-items-center mb-2">
            <input type="radio" disabled class="me-2">
            <span>${DEFAULT_OPTIONS[0]}</span>
          </div>
          <div class="col-6 d-flex align-items-center mb-2">
            <input type="radio" disabled class="me-2">
            <span>${DEFAULT_OPTIONS[1]}</span>
          </div>
          <div class="col-6 d-flex align-items-center mb-2">
            <input type="radio" disabled class="me-2">
            <span>${DEFAULT_OPTIONS[2]}</span>
          </div>
          <div class="col-6 d-flex align-items-center mb-2">
            <input type="radio" disabled class="me-2">
            <span>${DEFAULT_OPTIONS[3]}</span>
          </div>
        </div>
        <hr>
        <div class="d-flex justify-content-end">
          <div class="form-check form-switch d-none">
            <input class="form-check-input" type="checkbox" id="required-${newQuestionId}" ${isRequired ? 'checked' : ''}>
            <label class="form-check-label" for="required-${newQuestionId}">Bắt buộc</label>
          </div>
          <div>
            <button class="btn d-none" style="color: #6A6E73;" onclick="copyQuestion('${newQuestionId}', '${newGroupId}')"><span class="fas fa-copy"></span></button>
            <button class="btn ${isUseClass}" style="color: #E63757;" onclick="removeElement('${newQuestionId}')"><span class="fas fa-trash-alt"></span></button>
          </div>
        </div>
      </div>
    `;
    newQuestionsContainer.insertAdjacentHTML('beforeend', questionHtml);
  });

  updateSortable();
  updateOrder();
}

function addQuestion(groupId, questionText = "Câu hỏi") {
  let questionContainer = document.getElementById(`questions-${groupId}`);
  let questionCount = questionContainer.querySelectorAll(".question-item").length + 1;
  let questionId = `question-${groupId}-${questionCount}-${Date.now()}`;
  let questionHtml = `
    <div class="card mb-2 p-2 question-item" id="${questionId}">
      <input type="hidden" class="iorder" value="${questionCount}">
      <div class="text-center mb-2 drag-handle" style="cursor: move;">
        <span class="text-muted">...</span>
      </div>
      <div class="d-flex justify-content-between">
        <input type="text" class="form-control w-50" value="${questionText}">
      </div>
      <div class="options-container mt-2 row" id="options-${questionId}">
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[0]}</span>
        </div>
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[1]}</span>
        </div>
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[2]}</span>
        </div>
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[3]}</span>
        </div>
      </div>
      <hr>
      <div class="d-flex justify-content-end">
        <div class="form-check form-switch d-none">
          <input class="form-check-input" type="checkbox" id="required-${questionId}">
          <label class="form-check-label" for="required-${questionId}">Bắt buộc</label>
        </div>
        <div>
          <button class="btn d-none" style="color: #6A6E73;" onclick="copyQuestion('${questionId}', '${groupId}')"><span class="fas fa-copy"></span></button>
          <button class="btn ${isUseClass}" style="color: #E63757;" onclick="removeElement('${questionId}')"><span class="fas fa-trash-alt"></span></button>
        </div>
      </div>
    </div>
  `;
  questionContainer.insertAdjacentHTML("beforeend", questionHtml);
  updateSortable();
}

function copyQuestion(questionId, groupId) {
  const originalQuestion = document.getElementById(questionId);
  const newQuestionText = originalQuestion.querySelector("input[type=text]").value + " - copy";
  const isRequired = originalQuestion.querySelector('input[type="checkbox"]').checked;
  
  let questionContainer = document.getElementById(`questions-${groupId}`);
  let questionCount = questionContainer.querySelectorAll(".question-item").length + 1;
  let newQuestionId = `question-${groupId}-${questionCount}-${Date.now()}`;
  
  const questionHtml = `
    <div class="card mb-2 p-2 question-item" id="${newQuestionId}">
      <input type="hidden" class="iorder" value="${questionCount}">
      <div class="text-center mb-2 drag-handle" style="cursor: move;">
        <span class="text-muted">...</span>
      </div>
      <div class="d-flex justify-content-between">
        <input type="text" class="form-control w-50" value="${newQuestionText}">
      </div>
      <div class="options-container mt-2 row" id="options-${newQuestionId}">
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[0]}</span>
        </div>
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[1]}</span>
        </div>
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[2]}</span>
        </div>
        <div class="col-6 d-flex align-items-center mb-2">
          <input type="radio" disabled class="me-2">
          <span>${DEFAULT_OPTIONS[3]}</span>
        </div>
      </div>
      <hr>
      <div class="d-flex justify-content-end">
        <div class="form-check form-switch d-none">
          <input class="form-check-input" type="checkbox" id="required-${newQuestionId}" ${isRequired ? 'checked' : ''}>
          <label class="form-check-label" for="required-${newQuestionId}">Bắt buộc</label>
        </div>
        <div>
          <button class="btn d-none" style="color: #6A6E73;" onclick="copyQuestion('${newQuestionId}', '${groupId}')"><span class="fas fa-copy"></span></button>
          <button class="btn ${isUseClass}" style="color: #E63757;" onclick="removeElement('${newQuestionId}')"><span class="fas fa-trash-alt"></span></button>
        </div>
      </div>
    </div>
  `;
  questionContainer.insertAdjacentHTML("beforeend", questionHtml);
  updateSortable();
  updateOrder();
}

function updateSortable() {
  document.querySelectorAll(".questions-container").forEach(container => {
    new Sortable(container, {
      animation: 150,
      onEnd: updateOrder,
      handle: '.drag-handle' // Chỉ kéo thả khi nhấn vào khu vực có class drag-handle
    });
  });
}
function updateOrder() {
  document.querySelectorAll(".group-content").forEach((group, index) => {
    group.querySelector(".iorder").value = index + 1;
  });
  document.querySelectorAll(".questions-container").forEach(container => {
    container.querySelectorAll(".question-item").forEach((question, index) => {
      question.querySelector(".iorder").value = index + 1;
    });
  });
}

function removeGroup(groupId) {
  const groupElement = document.getElementById(groupId);
  if (groupElement) {
    if (!confirm('Bạn có chắc chắn muốn xóa nhóm này không? Tất cả câu hỏi trong nhóm sẽ bị xóa.')) {
      return;
    }
    const gsurveyId = groupElement.dataset.gsurveyId;
    if (gsurveyId) {
      deletedGroupIds.push(gsurveyId);
    }
    groupElement.querySelectorAll('.question-item').forEach(question => {
      const qsurveyId = question.dataset.qsurveyId;
      if (qsurveyId) {
        deletedQuestionIds.push(qsurveyId);
      }
    });
    groupElement.remove();
    updateOrder();
  }
}

function removeElement(elementId) {
  const element = document.getElementById(elementId);
  if (element) {
    if (!confirm('Bạn có chắc chắn muốn xóa câu hỏi này không?')) {
      return;
    }
    if (element.dataset.qsurveyId) {
      deletedQuestionIds.push(element.dataset.qsurveyId);
    }
    element.remove();
    updateOrder();
  }
}

function saveSurvey() {
  const groups = [];
  let hasError = false;

  document.querySelectorAll('.group-content').forEach(groupElement => {
    const groupId = groupElement.id.replace('group-', '');
    const groupSelect = groupElement.querySelector('.group-name');
    const questions = [];

    if (!groupSelect.value) {
      showErrorMessage('Vui lòng chọn một nhóm cho tất cả các nhóm!');
      hasError = true;
      return;
    }

    groupElement.querySelectorAll('.question-item').forEach(questionElement => {
      const questionDomId = questionElement.id;
      const questionText = questionElement.querySelector('input[type="text"]').value.trim();

      if (!questionText) {
        showErrorMessage('Vui lòng nhập nội dung cho tất cả các câu hỏi!');
        hasError = true;
        return;
      }

      const options = DEFAULT_OPTIONS.map((opt, index) => ({
        id: questionElement.querySelectorAll('.options-container > div')[index]?.dataset.optionId || null,
        temp_id: `option-${questionDomId}-${index}`,
        content: opt
      }));

      questions.push({
        id: questionElement.dataset.qsurveyId || null,
        temp_id: questionDomId,
        position: questionElement.querySelector('.iorder').value,
        content: questionText,
        type: 'multiple_choice',
        options: options
      });
    });

    groups.push({
      id: groupSelect.value,
      questions: questions
    });
  });

  if (hasError) return;

  const payload = {
    survey_id: surveyId,
    groups: groups,
    deleted_question_ids: deletedQuestionIds,
    deleted_group_ids: deletedGroupIds
  };


  showLoadding(true);

  fetch(root_path + 'survey/update_detail', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify(payload)
  })
  .then(response => {
    return response.json();
  })
  .then(data => {
    showLoadding(false);
    if (data.success) {
      showSuccessMessage('Lưu thành công!');
      deletedQuestionIds = [];
      deletedGroupIds = [];
      loadSurveyData(data.survey_data);
    } else {
      showErrorMessage(data.errors ? data.errors.join(', ') : 'Lưu thất bại!');
    }
  })
  .catch(error => {
    showLoadding(false);
    showErrorMessage('Có lỗi xảy ra khi lưu dữ liệu!');
    console.error('Error:', error);
  });
}

function showSuccessMessage(message) {
  alert(message);
}

function showErrorMessage(message) {
  alert(message);
}

