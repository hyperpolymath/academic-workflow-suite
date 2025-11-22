<?php
// This file is part of Moodle - http://moodle.org/

/**
 * Academic Workflow Suite Moodle Plugin Library
 *
 * @package    local_awap
 * @copyright  2024 Academic Workflow Suite Contributors
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

/**
 * AWAP API Client for Moodle
 */
class local_awap_client {
    /** @var string API base URL */
    private $api_url;

    /** @var int Request timeout */
    private $timeout;

    /**
     * Constructor
     *
     * @param string $api_url API base URL
     * @param int $timeout Request timeout in seconds
     */
    public function __construct($api_url = null, $timeout = 300) {
        $this->api_url = $api_url ?: get_config('local_awap', 'api_url');
        $this->timeout = $timeout;
    }

    /**
     * Upload a TMA file
     *
     * @param string $filepath Path to file
     * @param string $student_id Student identifier
     * @param string $rubric Rubric name
     * @return array Response with tma_id
     * @throws moodle_exception
     */
    public function upload_tma($filepath, $student_id, $rubric = 'default') {
        if (!file_exists($filepath)) {
            throw new moodle_exception('filenotfound', 'local_awap', '', $filepath);
        }

        $url = $this->api_url . '/api/v1/tma/upload';

        $curl_file = new CURLFile($filepath, 'application/pdf', basename($filepath));

        $post_data = [
            'file' => $curl_file,
            'student_id' => $student_id,
            'rubric' => $rubric
        ];

        $response = $this->make_request($url, 'POST', $post_data, true);

        if (!isset($response['tma_id'])) {
            throw new moodle_exception('uploadfailed', 'local_awap');
        }

        return $response;
    }

    /**
     * Submit TMA for marking
     *
     * @param string $tma_id TMA identifier
     * @param string $rubric Rubric name
     * @return array Response with job_id
     * @throws moodle_exception
     */
    public function submit_for_marking($tma_id, $rubric = 'default') {
        $url = $this->api_url . '/api/v1/tma/' . $tma_id . '/mark';

        $data = [
            'rubric' => $rubric,
            'auto_feedback' => true
        ];

        $response = $this->make_request($url, 'POST', $data);

        if (!isset($response['job_id'])) {
            throw new moodle_exception('markingfailed', 'local_awap');
        }

        return $response;
    }

    /**
     * Get job status
     *
     * @param string $job_id Job identifier
     * @return array Job status
     * @throws moodle_exception
     */
    public function get_job_status($job_id) {
        $url = $this->api_url . '/api/v1/jobs/' . $job_id;
        return $this->make_request($url, 'GET');
    }

    /**
     * Get marking results
     *
     * @param string $tma_id TMA identifier
     * @return array Marking results
     * @throws moodle_exception
     */
    public function get_results($tma_id) {
        $url = $this->api_url . '/api/v1/tma/' . $tma_id . '/results';
        return $this->make_request($url, 'GET');
    }

    /**
     * Wait for job completion
     *
     * @param string $job_id Job identifier
     * @param int $poll_interval Seconds between checks
     * @return string Final status
     * @throws moodle_exception
     */
    public function wait_for_completion($job_id, $poll_interval = 5) {
        $start_time = time();

        while ((time() - $start_time) < $this->timeout) {
            $status_data = $this->get_job_status($job_id);
            $status = $status_data['status'];

            if ($status === 'completed') {
                return $status;
            } else if ($status === 'failed') {
                $error = isset($status_data['error']) ? $status_data['error'] : 'Unknown error';
                throw new moodle_exception('jobfailed', 'local_awap', '', $error);
            }

            sleep($poll_interval);
        }

        throw new moodle_exception('jobtimeout', 'local_awap');
    }

    /**
     * Make HTTP request
     *
     * @param string $url Request URL
     * @param string $method HTTP method
     * @param mixed $data Request data
     * @param bool $multipart Whether this is a multipart request
     * @return array Response data
     * @throws moodle_exception
     */
    private function make_request($url, $method = 'GET', $data = null, $multipart = false) {
        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);

        if ($method === 'POST') {
            curl_setopt($ch, CURLOPT_POST, true);

            if ($data) {
                if ($multipart) {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
                } else {
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                    curl_setopt($ch, CURLOPT_HTTPHEADER, [
                        'Content-Type: application/json'
                    ]);
                }
            }
        }

        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);

        curl_close($ch);

        if ($error) {
            throw new moodle_exception('requesterror', 'local_awap', '', $error);
        }

        if ($http_code < 200 || $http_code >= 300) {
            throw new moodle_exception('requestfailed', 'local_awap', '', "HTTP $http_code");
        }

        $decoded = json_decode($response, true);

        if ($decoded === null) {
            throw new moodle_exception('invalidresponse', 'local_awap');
        }

        return $decoded;
    }
}

/**
 * Process assignment submission with AWAP
 *
 * @param object $submission Assignment submission object
 * @param string $rubric Rubric to use
 * @return array Marking results
 */
function local_awap_process_submission($submission, $rubric = 'default') {
    global $DB, $CFG;

    require_once($CFG->dirroot . '/mod/assign/locallib.php');

    // Get submission files
    $fs = get_file_storage();
    $files = $fs->get_area_files(
        $submission->assignment,
        'mod_assign',
        'submission_files',
        $submission->id,
        'timemodified',
        false
    );

    if (empty($files)) {
        throw new moodle_exception('nofiles', 'local_awap');
    }

    // Process first PDF file
    $file = null;
    foreach ($files as $f) {
        if ($f->get_mimetype() === 'application/pdf') {
            $file = $f;
            break;
        }
    }

    if (!$file) {
        throw new moodle_exception('nopdffile', 'local_awap');
    }

    // Save file temporarily
    $tempdir = make_temp_directory('awap');
    $tempfile = $tempdir . '/' . $file->get_filename();
    $file->copy_content_to($tempfile);

    // Create AWAP client
    $client = new local_awap_client();

    try {
        // Upload TMA
        $upload_result = $client->upload_tma(
            $tempfile,
            'moodle_user_' . $submission->userid,
            $rubric
        );

        $tma_id = $upload_result['tma_id'];

        // Submit for marking
        $mark_result = $client->submit_for_marking($tma_id, $rubric);
        $job_id = $mark_result['job_id'];

        // Wait for completion
        $client->wait_for_completion($job_id);

        // Get results
        $results = $client->get_results($tma_id);

        // Clean up temp file
        unlink($tempfile);

        return $results;

    } catch (Exception $e) {
        // Clean up temp file on error
        if (file_exists($tempfile)) {
            unlink($tempfile);
        }
        throw $e;
    }
}

/**
 * Apply AWAP results to Moodle assignment
 *
 * @param int $assignment_id Assignment ID
 * @param int $user_id User ID
 * @param array $results AWAP results
 * @return bool Success
 */
function local_awap_apply_grade($assignment_id, $user_id, $results) {
    global $DB, $CFG;

    require_once($CFG->dirroot . '/mod/assign/locallib.php');

    $cm = get_coursemodule_from_instance('assign', $assignment_id);
    $context = context_module::instance($cm->id);
    $assignment = new assign($context, $cm, null);

    // Convert percentage to grade
    $grade_item = $assignment->get_grade_item();
    $max_grade = $grade_item->grademax;
    $grade = ($results['score'] / 100) * $max_grade;

    // Format feedback
    $feedback_text = "# Automated Feedback\n\n";
    $feedback_text .= "**Score:** " . $results['score'] . "/100\n";
    $feedback_text .= "**Grade:** " . $results['grade'] . "\n\n";
    $feedback_text .= "## Summary\n\n";
    $feedback_text .= $results['feedback']['summary'] . "\n\n";
    $feedback_text .= "## Strengths\n\n";

    foreach ($results['feedback']['strengths'] as $strength) {
        $feedback_text .= "- " . $strength . "\n";
    }

    $feedback_text .= "\n## Areas for Improvement\n\n";

    foreach ($results['feedback']['areas_for_improvement'] as $area) {
        $feedback_text .= "- " . $area . "\n";
    }

    // Set grade and feedback
    $grade_data = (object) [
        'userid' => $user_id,
        'grade' => $grade,
        'attemptnumber' => -1
    ];

    $feedback_data = (object) [
        'assignfeedbackcomments_editor' => [
            'text' => $feedback_text,
            'format' => FORMAT_MARKDOWN
        ]
    ];

    return $assignment->save_grade($user_id, $grade_data);
}
