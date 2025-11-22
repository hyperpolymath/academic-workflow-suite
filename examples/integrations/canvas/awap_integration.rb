# Academic Workflow Suite - Canvas LMS Integration
# This is a Canvas external tool integration for AWAP

require 'httparty'
require 'json'

module AWAP
  # Canvas LMS Integration Client
  class CanvasClient
    include HTTParty

    def initialize(api_url: ENV['AWAP_API_URL'] || 'http://localhost:8080')
      @api_url = api_url
      @timeout = 300
    end

    # Upload a submission file
    def upload_submission(file_path, student_id, rubric: 'default')
      url = "#{@api_url}/api/v1/tma/upload"

      response = self.class.post(
        url,
        body: {
          file: File.new(file_path),
          student_id: student_id,
          rubric: rubric
        },
        timeout: 30
      )

      raise "Upload failed: #{response.code}" unless response.success?

      JSON.parse(response.body)
    end

    # Submit for marking
    def submit_for_marking(tma_id, rubric: 'default')
      url = "#{@api_url}/api/v1/tma/#{tma_id}/mark"

      response = self.class.post(
        url,
        body: {
          rubric: rubric,
          auto_feedback: true
        }.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 30
      )

      raise "Marking failed: #{response.code}" unless response.success?

      JSON.parse(response.body)
    end

    # Get job status
    def get_job_status(job_id)
      url = "#{@api_url}/api/v1/jobs/#{job_id}"
      response = self.class.get(url, timeout: 30)

      raise "Status check failed: #{response.code}" unless response.success?

      JSON.parse(response.body)
    end

    # Wait for completion
    def wait_for_completion(job_id, poll_interval: 5)
      start_time = Time.now

      loop do
        elapsed = Time.now - start_time
        raise "Timeout: Job did not complete" if elapsed > @timeout

        status_data = get_job_status(job_id)
        status = status_data['status']

        return status if status == 'completed'
        raise "Job failed: #{status_data['error']}" if status == 'failed'

        sleep poll_interval
      end
    end

    # Get results
    def get_results(tma_id)
      url = "#{@api_url}/api/v1/tma/#{tma_id}/results"
      response = self.class.get(url, timeout: 30)

      raise "Failed to get results: #{response.code}" unless response.success?

      JSON.parse(response.body)
    end

    # Process a Canvas submission
    def process_canvas_submission(submission, rubric: 'default')
      # Download submission attachment
      attachment = submission.attachments.first
      raise "No attachment found" unless attachment

      # Download file
      temp_file = download_attachment(attachment)

      begin
        # Upload to AWAP
        upload_result = upload_submission(
          temp_file,
          "canvas_user_#{submission.user_id}",
          rubric: rubric
        )

        # Submit for marking
        mark_result = submit_for_marking(
          upload_result['tma_id'],
          rubric: rubric
        )

        # Wait for completion
        wait_for_completion(mark_result['job_id'])

        # Get results
        results = get_results(upload_result['tma_id'])

        results
      ensure
        File.delete(temp_file) if temp_file && File.exist?(temp_file)
      end
    end

    # Apply AWAP results to Canvas assignment
    def apply_grade_to_canvas(assignment, user_id, results)
      # Calculate grade based on assignment points possible
      score = (results['score'] / 100.0) * assignment.points_possible

      # Format feedback comment
      feedback = format_feedback(results)

      # Submit grade to Canvas
      assignment.grade_student(
        user_id,
        grade: score,
        comment: feedback
      )
    end

    private

    def download_attachment(attachment)
      temp_file = "/tmp/canvas_attachment_#{attachment.id}.pdf"

      File.open(temp_file, 'wb') do |file|
        file.write(HTTParty.get(attachment.url).body)
      end

      temp_file
    end

    def format_feedback(results)
      feedback = "# Automated Feedback\n\n"
      feedback += "**Score:** #{results['score']}/100\n"
      feedback += "**Grade:** #{results['grade']}\n\n"
      feedback += "## Summary\n\n"
      feedback += "#{results['feedback']['summary']}\n\n"
      feedback += "## Strengths\n\n"

      results['feedback']['strengths'].each do |strength|
        feedback += "- #{strength}\n"
      end

      feedback += "\n## Areas for Improvement\n\n"

      results['feedback']['areas_for_improvement'].each do |area|
        feedback += "- #{area}\n"
      end

      feedback
    end
  end
end

# Example usage:
#
# client = AWAP::CanvasClient.new
#
# # Process a submission
# results = client.process_canvas_submission(submission, rubric: 'essay')
#
# # Apply grade to Canvas
# client.apply_grade_to_canvas(assignment, user_id, results)
