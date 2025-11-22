// Academic Workflow Suite - Demo Web App

const API_URL = 'http://localhost:8080';

let currentResults = null;

// Initialize
document.getElementById('upload-form').addEventListener('submit', handleSubmit);

async function handleSubmit(e) {
    e.preventDefault();

    const studentId = document.getElementById('student-id').value;
    const rubric = document.getElementById('rubric').value;
    const file = document.getElementById('file').files[0];

    if (!file) {
        alert('Please select a file');
        return;
    }

    // Show status section
    showSection('status-section');
    updateStatus('Uploading assignment...', 10);

    try {
        // Upload TMA
        const tmaId = await uploadTMA(file, studentId, rubric);
        updateStatus('Assignment uploaded. Submitting for marking...', 30);

        // Submit for marking
        const jobId = await submitForMarking(tmaId, rubric);
        updateStatus('Marking in progress...', 50);

        // Wait for completion
        const results = await waitForResults(jobId, tmaId);

        // Show results
        displayResults(results);

    } catch (error) {
        console.error('Error:', error);
        alert('An error occurred: ' + error.message);
        showSection('upload-section');
    }
}

async function uploadTMA(file, studentId, rubric) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('student_id', studentId);
    formData.append('rubric', rubric);

    const response = await fetch(`${API_URL}/api/v1/tma/upload`, {
        method: 'POST',
        body: formData
    });

    if (!response.ok) {
        throw new Error('Upload failed');
    }

    const data = await response.json();
    return data.tma_id;
}

async function submitForMarking(tmaId, rubric) {
    const response = await fetch(`${API_URL}/api/v1/tma/${tmaId}/mark`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            rubric: rubric,
            auto_feedback: true
        })
    });

    if (!response.ok) {
        throw new Error('Marking submission failed');
    }

    const data = await response.json();
    return data.job_id;
}

async function waitForResults(jobId, tmaId) {
    const maxAttempts = 60;
    let attempts = 0;

    while (attempts < maxAttempts) {
        const response = await fetch(`${API_URL}/api/v1/jobs/${jobId}`);
        const status = await response.json();

        if (status.status === 'completed') {
            updateStatus('Marking completed! Loading results...', 90);

            // Get results
            const resultsResponse = await fetch(`${API_URL}/api/v1/tma/${tmaId}/results`);
            return await resultsResponse.json();

        } else if (status.status === 'failed') {
            throw new Error('Marking failed: ' + (status.error || 'Unknown error'));
        }

        // Update progress
        const progress = 50 + (attempts / maxAttempts) * 40;
        updateStatus('Marking in progress...', progress);

        await sleep(5000);
        attempts++;
    }

    throw new Error('Timeout: Marking took too long');
}

function displayResults(results) {
    currentResults = results;

    // Update score and grade
    document.getElementById('score').textContent = results.score;
    document.getElementById('grade').textContent = results.grade;

    // Update feedback
    document.getElementById('feedback-summary').textContent = results.feedback.summary;

    // Update strengths
    const strengthsList = document.getElementById('strengths-list');
    strengthsList.innerHTML = '';
    results.feedback.strengths.forEach(strength => {
        const li = document.createElement('li');
        li.textContent = strength;
        strengthsList.appendChild(li);
    });

    // Update improvements
    const improvementsList = document.getElementById('improvements-list');
    improvementsList.innerHTML = '';
    results.feedback.areas_for_improvement.forEach(area => {
        const li = document.createElement('li');
        li.textContent = area;
        improvementsList.appendChild(li);
    });

    updateStatus('Complete!', 100);

    setTimeout(() => {
        showSection('results-section');
    }, 500);
}

function updateStatus(text, progress) {
    document.getElementById('status-text').textContent = text;
    document.getElementById('progress').style.width = progress + '%';
}

function showSection(sectionId) {
    document.getElementById('upload-section').style.display = 'none';
    document.getElementById('status-section').style.display = 'none';
    document.getElementById('results-section').style.display = 'none';

    document.getElementById(sectionId).style.display = 'block';
}

function downloadFeedback() {
    if (!currentResults) return;

    const blob = new Blob([JSON.stringify(currentResults, null, 2)], {
        type: 'application/json'
    });

    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `feedback_${currentResults.student_id}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function submitAnother() {
    currentResults = null;
    document.getElementById('upload-form').reset();
    showSection('upload-section');
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
