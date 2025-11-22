/**
 * Academic Workflow API JavaScript Client
 *
 * This module provides a JavaScript client for the Academic Workflow API.
 *
 * @module awap-client
 */

const fs = require('fs');
const FormData = require('form-data');
const axios = require('axios');

/**
 * Custom error class for AWAP errors
 */
class AwapError extends Error {
    constructor(message, statusCode = null) {
        super(message);
        this.name = 'AwapError';
        this.statusCode = statusCode;
    }
}

/**
 * Timeout error
 */
class AwapTimeoutError extends AwapError {
    constructor(message) {
        super(message);
        this.name = 'AwapTimeoutError';
    }
}

/**
 * Academic Workflow API Client
 *
 * @example
 * const { AwapClient } = require('awap-js-sdk');
 *
 * const client = new AwapClient({ apiUrl: 'http://localhost:8080' });
 *
 * // Mark a TMA
 * const result = await client.markTMA({
 *   filePath: 'essay.pdf',
 *   studentId: 'student001',
 *   rubric: 'default'
 * });
 *
 * console.log(`Score: ${result.score}, Grade: ${result.grade}`);
 */
class AwapClient {
    /**
     * Create a new AWAP client
     *
     * @param {Object} options - Configuration options
     * @param {string} [options.apiUrl] - API base URL (default: http://localhost:8080)
     * @param {number} [options.timeout] - Request timeout in milliseconds (default: 300000)
     * @param {boolean} [options.verifySsl] - Verify SSL certificates (default: true)
     */
    constructor(options = {}) {
        this.apiUrl = options.apiUrl || process.env.AWS_API_URL || 'http://localhost:8080';
        this.timeout = options.timeout || 300000; // 5 minutes
        this.verifySsl = options.verifySsl !== false;

        this.axios = axios.create({
            baseURL: this.apiUrl,
            timeout: 30000,
            httpsAgent: this.verifySsl ? undefined : new (require('https').Agent)({
                rejectUnauthorized: false
            })
        });
    }

    /**
     * Upload a TMA file
     *
     * @param {Object} params - Upload parameters
     * @param {string} params.filePath - Path to TMA PDF file
     * @param {string} params.studentId - Student identifier
     * @param {string} [params.rubric='default'] - Rubric to use
     * @returns {Promise<string>} TMA ID
     * @throws {AwapError} If upload fails
     */
    async uploadTMA({ filePath, studentId, rubric = 'default' }) {
        if (!fs.existsSync(filePath)) {
            throw new AwapError(`File not found: ${filePath}`);
        }

        const form = new FormData();
        form.append('file', fs.createReadStream(filePath));
        form.append('student_id', studentId);
        form.append('rubric', rubric);

        try {
            const response = await this.axios.post('/api/v1/tma/upload', form, {
                headers: form.getHeaders()
            });

            const { tma_id } = response.data;

            if (!tma_id) {
                throw new AwapError('No TMA ID returned from upload');
            }

            return tma_id;
        } catch (error) {
            if (error.response) {
                throw new AwapError(
                    `Upload failed: ${error.message}`,
                    error.response.status
                );
            }
            throw new AwapError(`Upload failed: ${error.message}`);
        }
    }

    /**
     * Submit TMA for marking
     *
     * @param {Object} params - Marking parameters
     * @param {string} params.tmaId - TMA identifier
     * @param {string} [params.rubric='default'] - Rubric to use
     * @param {boolean} [params.autoFeedback=true] - Generate automatic feedback
     * @returns {Promise<string>} Job ID
     * @throws {AwapError} If submission fails
     */
    async submitForMarking({ tmaId, rubric = 'default', autoFeedback = true }) {
        try {
            const response = await this.axios.post(`/api/v1/tma/${tmaId}/mark`, {
                rubric,
                auto_feedback: autoFeedback
            });

            const { job_id } = response.data;

            if (!job_id) {
                throw new AwapError('No job ID returned');
            }

            return job_id;
        } catch (error) {
            if (error.response) {
                throw new AwapError(
                    `Marking submission failed: ${error.message}`,
                    error.response.status
                );
            }
            throw new AwapError(`Marking submission failed: ${error.message}`);
        }
    }

    /**
     * Get job status
     *
     * @param {string} jobId - Job identifier
     * @returns {Promise<Object>} Job status
     * @throws {AwapError} If request fails
     */
    async getJobStatus(jobId) {
        try {
            const response = await this.axios.get(`/api/v1/jobs/${jobId}`);
            return response.data;
        } catch (error) {
            if (error.response) {
                throw new AwapError(
                    `Failed to get job status: ${error.message}`,
                    error.response.status
                );
            }
            throw new AwapError(`Failed to get job status: ${error.message}`);
        }
    }

    /**
     * Get marking results
     *
     * @param {string} tmaId - TMA identifier
     * @returns {Promise<Object>} Marking results
     * @throws {AwapError} If request fails
     */
    async getResults(tmaId) {
        try {
            const response = await this.axios.get(`/api/v1/tma/${tmaId}/results`);
            return response.data;
        } catch (error) {
            if (error.response) {
                throw new AwapError(
                    `Failed to get results: ${error.message}`,
                    error.response.status
                );
            }
            throw new AwapError(`Failed to get results: ${error.message}`);
        }
    }

    /**
     * Wait for job to complete
     *
     * @param {Object} params - Wait parameters
     * @param {string} params.jobId - Job identifier
     * @param {number} [params.pollInterval=5000] - Milliseconds between status checks
     * @param {number} [params.timeout] - Maximum time to wait (uses client timeout if not specified)
     * @returns {Promise<string>} Final job status
     * @throws {AwapTimeoutError} If timeout exceeded
     * @throws {AwapError} If job fails
     */
    async waitForCompletion({ jobId, pollInterval = 5000, timeout }) {
        const maxTime = timeout || this.timeout;
        const startTime = Date.now();

        while (true) {
            const elapsed = Date.now() - startTime;
            if (elapsed > maxTime) {
                throw new AwapTimeoutError(`Job did not complete within ${maxTime}ms`);
            }

            const statusData = await this.getJobStatus(jobId);
            const { status } = statusData;

            if (status === 'completed') {
                return status;
            } else if (status === 'failed') {
                const error = statusData.error || 'Unknown error';
                throw new AwapError(`Job failed: ${error}`);
            }

            await new Promise(resolve => setTimeout(resolve, pollInterval));
        }
    }

    /**
     * Mark a TMA (convenience method that handles all steps)
     *
     * @param {Object} params - Marking parameters
     * @param {string} params.filePath - Path to TMA PDF file
     * @param {string} params.studentId - Student identifier
     * @param {string} [params.rubric='default'] - Rubric to use
     * @param {boolean} [params.wait=true] - Wait for completion
     * @returns {Promise<Object>} Marking results
     * @throws {AwapError} If any step fails
     * @throws {AwapTimeoutError} If marking times out
     */
    async markTMA({ filePath, studentId, rubric = 'default', wait = true }) {
        // Upload TMA
        const tmaId = await this.uploadTMA({ filePath, studentId, rubric });

        // Submit for marking
        const jobId = await this.submitForMarking({ tmaId, rubric });

        if (!wait) {
            return {
                tmaId,
                jobId,
                status: 'submitted'
            };
        }

        // Wait for completion
        await this.waitForCompletion({ jobId });

        // Get results
        return await this.getResults(tmaId);
    }
}

// Export classes
module.exports = {
    AwapClient,
    AwapError,
    AwapTimeoutError
};
