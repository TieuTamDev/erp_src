const colorsBar = {
    "Không hài lòng": "#00C200",
    "Bình thường": "#2C7BE5",
    "Hài lòng": "#E5AA2C",
    "Rất hài lòng": "#E52C2F"
};

const approval_rate_chart = $('#pieChart')[0]
if (approval_rate_chart) {
    const approval_rate = approval_rate_chart.getContext('2d');
    new Chart(approval_rate, {
        type: 'doughnut',
        data: {
            labels: gon.approval_rate["label"],
            datasets: [
                {
                    data: gon.approval_rate["data"],
                    backgroundColor: ['#BBE7FF', '#3762D0', '#C2C2C2']
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '65%',
            radius: '100%',
            layout: {
                padding: {
                    top: 20
    
                }
            },
            plugins: {
                legend: {
                    position: 'right',
                    labels: {
                        boxWidth: 30,
                        boxHeight: 30,
                        padding: 20
                    }
                }
            }
    
        }
    });
}

const approval_rate_by_group_chart = $('#barChart')[0]
if (approval_rate_by_group_chart) { 
    const approval_rate_by_group = approval_rate_by_group_chart.getContext('2d');
    new Chart(approval_rate_by_group, {
        type: 'bar',
        data: {
            labels: gon.approval_rate_by_group["label"],
            datasets: [
                {
                    label: 'Đồng ý',
                    data: gon.approval_rate_by_group["data"]?.approve,
                    backgroundColor: '#BBE7FF',
                    barThickness: 20
                }, {
                    label: 'Không đồng ý',
                    data: gon.approval_rate_by_group["data"]?.reject,
                    backgroundColor: '#3762D0',
                    barThickness: 20
                }
            ],
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100,
                    ticks: {
                        stepSize: 25,
                        callback: function (value) {
                            return value + '%'; 
                        }
                    }
                }
            }
        }
    });
}

$(document).ready(function() {
    if (gon.path_chart) {
        fetch(gon.path_chart)
            .then(response => response.json())
            .then(data => {
                data.forEach((gsurvey, index) => {
                    const ctx = document.getElementById(`chart-${index}`).getContext('2d');
    
                    new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: gsurvey.questions_multiple,
                            datasets: gsurvey.answer_labels.map(answer => ({
                                label: answer.name, 
                                barThickness: 20,
                                data: answer.count,
                                backgroundColor: colorsBar[answer.name] || "gray",
                            }))
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: {
                                    position: 'bottom',
                                    align: 'start',
                                    labels: {
                                        boxWidth: 15,
                                        boxHeight: 12,
                                        padding: 10
                                    }
                                },
                            },
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    ticks: {
                                        stepSize: 1
                                    }
                                }
                            }
                        }
                    });
                }); 
            })
            .catch(error => console.error("Error:", error));
    }
});