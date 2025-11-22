#!/usr/bin/env node
/**
 * Example: Mark a TMA using the AWAP JavaScript SDK
 *
 * This demonstrates the simplest way to use the SDK to mark a TMA.
 */

const fs = require('fs');
const path = require('path');
const { AwapClient, AwapError } = require('../src/awap-client');

async function main() {
    const args = process.argv.slice(2);

    if (args.length < 1) {
        console.log('Usage: node mark-tma.js <tma_file.pdf> [student_id] [rubric]');
        process.exit(1);
    }

    const tmaFile = args[0];
    const studentId = args[1] || 'student001';
    const rubric = args[2] || 'default';

    console.log('Academic Workflow Suite - JavaScript SDK Example');
    console.log('='.repeat(50));
    console.log();

    // Create client
    const client = new AwapClient();

    try {
        console.log(`Marking TMA: ${tmaFile}`);
        console.log(`Student ID: ${studentId}`);
        console.log(`Rubric: ${rubric}`);
        console.log();

        // Mark TMA (upload, submit, wait, get results - all in one call)
        const result = await client.markTMA({
            filePath: tmaFile,
            studentId: studentId,
            rubric: rubric
        });

        // Display results
        console.log('Results:');
        console.log('='.repeat(50));
        console.log(`Score: ${result.score}`);
        console.log(`Grade: ${result.grade}`);
        console.log();

        console.log('Feedback Summary:');
        console.log(result.feedback.summary);
        console.log();

        console.log('Strengths:');
        result.feedback.strengths.forEach(strength => {
            console.log(`  • ${strength}`);
        });
        console.log();

        console.log('Areas for Improvement:');
        result.feedback.areas_for_improvement.forEach(area => {
            console.log(`  • ${area}`);
        });
        console.log();

        // Save feedback to file
        const outputFile = tmaFile.replace(/\.pdf$/, '.feedback.json');
        fs.writeFileSync(outputFile, JSON.stringify(result, null, 2));

        console.log(`Full feedback saved to: ${outputFile}`);

    } catch (error) {
        if (error instanceof AwapError) {
            console.error(`Error: ${error.message}`);
            if (error.statusCode) {
                console.error(`Status code: ${error.statusCode}`);
            }
        } else {
            console.error(`Unexpected error: ${error.message}`);
        }
        process.exit(1);
    }
}

main();
