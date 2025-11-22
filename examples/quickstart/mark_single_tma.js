#!/usr/bin/env node
/**
 * Quick Start: Mark a Single TMA using Node.js
 * This script demonstrates how to submit a TMA for automated marking using JavaScript.
 */

const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
const axios = require('axios');

// Configuration
const API_URL = process.env.AWS_API_URL || 'http://localhost:8080';
const TIMEOUT = 300000; // 5 minutes in milliseconds

// ANSI color codes
const Colors = {
    GREEN: '\x1b[0;32m',
    BLUE: '\x1b[0;34m',
    RED: '\x1b[0;31m',
    YELLOW: '\x1b[1;33m',
    NC: '\x1b[0m', // No Color
};

/**
 * Print a colored step message
 */
function printStep(stepNum, message) {
    console.log(`${Colors.GREEN}Step ${stepNum}:${Colors.NC} ${message}`);
}

/**
 * Print a colored error message
 */
function printError(message) {
    console.error(`${Colors.RED}Error: ${message}${Colors.NC}`);
}

/**
 * Print a colored success message
 */
function printSuccess(message) {
    console.log(`${Colors.GREEN}✓ ${message}${Colors.NC}`);
}

/**
 * Upload a TMA file to the API
 */
async function uploadTMA(filePath, studentId, rubric = 'default') {
    printStep(1, 'Uploading TMA...');

    const form = new FormData();
    form.append('file', fs.createReadStream(filePath));
    form.append('student_id', studentId);
    form.append('rubric', rubric);

    try {
        const response = await axios.post(
            `${API_URL}/api/v1/tma/upload`,
            form,
            { headers: form.getHeaders() }
        );

        const { tma_id } = response.data;

        if (!tma_id) {
            throw new Error('No TMA ID returned from upload');
        }

        printSuccess('TMA uploaded successfully');
        console.log(`  TMA ID: ${tma_id}`);
        return tma_id;
    } catch (error) {
        throw new Error(`Upload failed: ${error.message}`);
    }
}

/**
 * Submit a TMA for marking
 */
async function submitForMarking(tmaId, rubric = 'default') {
    printStep(2, 'Submitting for marking...');

    try {
        const response = await axios.post(
            `${API_URL}/api/v1/tma/${tmaId}/mark`,
            { rubric, auto_feedback: true }
        );

        const { job_id } = response.data;

        printSuccess('Marking job submitted');
        console.log(`  Job ID: ${job_id}`);
        return job_id;
    } catch (error) {
        throw new Error(`Submission failed: ${error.message}`);
    }
}

/**
 * Wait for marking to complete and retrieve results
 */
async function waitForResults(jobId, tmaId) {
    printStep(3, 'Waiting for results...');

    const startTime = Date.now();

    while (Date.now() - startTime < TIMEOUT) {
        try {
            const statusResponse = await axios.get(`${API_URL}/api/v1/jobs/${jobId}`);
            const { status } = statusResponse.data;

            if (status === 'completed') {
                printSuccess('Marking completed!\n');

                // Get detailed results
                const resultsResponse = await axios.get(`${API_URL}/api/v1/tma/${tmaId}/results`);
                return resultsResponse.data;
            } else if (status === 'failed') {
                const errorMsg = statusResponse.data.error || 'Unknown error';
                throw new Error(`Marking failed: ${errorMsg}`);
            }

            process.stdout.write('.');
            await new Promise(resolve => setTimeout(resolve, 5000));
        } catch (error) {
            if (error.response) {
                throw new Error(`API error: ${error.message}`);
            }
            throw error;
        }
    }

    throw new Error('Marking took too long (timeout)');
}

/**
 * Display and optionally save results
 */
function displayResults(results, outputFile = null) {
    console.log(`\n${Colors.BLUE}Results:${Colors.NC}`);
    console.log('='.repeat(50));

    // Display summary
    console.log(`\nScore: ${results.score || 'N/A'}`);
    console.log(`Grade: ${results.grade || 'N/A'}`);

    const feedback = results.feedback || {};

    console.log(`\n${Colors.BLUE}Feedback Summary:${Colors.NC}`);
    console.log(feedback.summary || 'No summary available');

    console.log(`\n${Colors.GREEN}Strengths:${Colors.NC}`);
    (feedback.strengths || []).forEach(strength => {
        console.log(`  • ${strength}`);
    });

    console.log(`\n${Colors.YELLOW}Areas for Improvement:${Colors.NC}`);
    (feedback.areas_for_improvement || []).forEach(area => {
        console.log(`  • ${area}`);
    });

    // Save to file if requested
    if (outputFile) {
        fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));
        console.log(`\n${Colors.GREEN}Full feedback saved to:${Colors.NC} ${outputFile}`);
    }
}

/**
 * Main function
 */
async function main() {
    const args = process.argv.slice(2);

    if (args.length < 1) {
        printError('Usage: node mark_single_tma.js <tma_file.pdf> [rubric] [student_id]');
        process.exit(1);
    }

    const tmaFile = args[0];
    const rubric = args[1] || 'default';
    const studentId = args[2] || 'student001';

    // Check file exists
    if (!fs.existsSync(tmaFile)) {
        printError(`TMA file not found: ${tmaFile}`);
        process.exit(1);
    }

    console.log(`${Colors.BLUE}Academic Workflow Suite - Quick Start${Colors.NC}`);
    console.log(`${Colors.BLUE}======================================${Colors.NC}\n`);

    try {
        // Step 1: Upload TMA
        const tmaId = await uploadTMA(tmaFile, studentId, rubric);

        // Step 2: Submit for marking
        const jobId = await submitForMarking(tmaId, rubric);

        // Step 3: Wait for and retrieve results
        const results = await waitForResults(jobId, tmaId);

        // Display results
        const outputFile = tmaFile.replace(/\.pdf$/, '.feedback.json');
        displayResults(results, outputFile);

    } catch (error) {
        printError(error.message);
        process.exit(1);
    }
}

// Run main function
main();
