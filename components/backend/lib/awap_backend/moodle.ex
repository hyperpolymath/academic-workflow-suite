defmodule AwapBackend.Moodle do
  @moduledoc """
  Moodle LMS Integration module.

  Provides functions for:
  - OAuth2/SAML authentication with Moodle
  - Downloading TMAs via Moodle REST API
  - Uploading grades and feedback
  - Fetching assignment metadata

  ## Configuration

  Configure in config/config.exs:

      config :awap_backend, AwapBackend.Moodle,
        base_url: "https://moodle.example.edu",
        client_id: "your_client_id",
        client_secret: "your_client_secret",
        token_endpoint: "/oauth2/token",
        api_endpoint: "/webservice/rest/server.php"

  ## Authentication

  Moodle supports both OAuth2 and SAML. This module provides stub implementations
  that can be extended based on your institution's authentication setup.
  """

  require Logger

  @type assignment :: %{
          id: integer(),
          course_id: integer(),
          name: String.t(),
          description: String.t(),
          due_date: DateTime.t() | nil,
          allow_submissions_from: DateTime.t() | nil
        }

  @type submission :: %{
          id: integer(),
          assignment_id: integer(),
          user_id: integer(),
          submitted_at: DateTime.t(),
          status: String.t(),
          files: list(map())
        }

  @type grade :: %{
          submission_id: integer(),
          grade: float(),
          feedback: String.t(),
          graded_at: DateTime.t()
        }

  # Client API

  @doc """
  Authenticates with Moodle using OAuth2.

  Returns an access token that can be used for subsequent API calls.
  """
  @spec authenticate_oauth2(String.t(), String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def authenticate_oauth2(username, password) do
    config = Application.get_env(:awap_backend, __MODULE__)
    base_url = Keyword.fetch!(config, :base_url)
    client_id = Keyword.fetch!(config, :client_id)
    client_secret = Keyword.fetch!(config, :client_secret)
    token_endpoint = Keyword.get(config, :token_endpoint, "/oauth2/token")

    url = "#{base_url}#{token_endpoint}"

    body = %{
      grant_type: "password",
      client_id: client_id,
      client_secret: client_secret,
      username: username,
      password: password
    }

    case http_client().post(url, body) do
      {:ok, %{status: 200, body: response_body}} ->
        token = Map.get(response_body, "access_token")
        Logger.info("Successfully authenticated with Moodle for user #{username}")
        {:ok, token}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Moodle OAuth2 authentication failed: #{status} - #{inspect(body)}")
        {:error, {:authentication_failed, status, body}}

      {:error, reason} ->
        Logger.error("Moodle OAuth2 request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Authenticates with Moodle using SAML.

  This is a stub implementation. Actual SAML integration would require
  additional libraries and configuration.
  """
  @spec authenticate_saml(String.t()) :: {:ok, String.t()} | {:error, term()}
  def authenticate_saml(saml_response) do
    # TODO: Implement SAML authentication
    Logger.warn("SAML authentication not yet implemented")
    {:error, :not_implemented}
  end

  @doc """
  Fetches all assignments for a given course.
  """
  @spec get_assignments(String.t(), integer()) ::
          {:ok, list(assignment())} | {:error, term()}
  def get_assignments(token, course_id) do
    params = %{
      wstoken: token,
      wsfunction: "mod_assign_get_assignments",
      moodlewsrestformat: "json",
      courseids: [course_id]
    }

    case api_request(params) do
      {:ok, response} ->
        assignments = parse_assignments(response)
        {:ok, assignments}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Downloads a TMA submission from Moodle.
  """
  @spec download_submission(String.t(), integer()) ::
          {:ok, submission()} | {:error, term()}
  def download_submission(token, submission_id) do
    params = %{
      wstoken: token,
      wsfunction: "mod_assign_get_submission_status",
      moodlewsrestformat: "json",
      assignid: submission_id
    }

    case api_request(params) do
      {:ok, response} ->
        submission = parse_submission(response)
        {:ok, submission}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Downloads all submissions for an assignment.
  """
  @spec download_submissions(String.t(), integer()) ::
          {:ok, list(submission())} | {:error, term()}
  def download_submissions(token, assignment_id) do
    params = %{
      wstoken: token,
      wsfunction: "mod_assign_get_submissions",
      moodlewsrestformat: "json",
      assignmentids: [assignment_id]
    }

    case api_request(params) do
      {:ok, response} ->
        submissions = parse_submissions(response)
        {:ok, submissions}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Uploads a grade and feedback for a submission.
  """
  @spec upload_grade(String.t(), grade()) :: :ok | {:error, term()}
  def upload_grade(token, grade) do
    params = %{
      wstoken: token,
      wsfunction: "mod_assign_save_grade",
      moodlewsrestformat: "json",
      assignmentid: grade.submission_id,
      userid: grade.user_id,
      grade: grade.grade,
      attemptnumber: -1,
      addattempt: 0,
      workflowstate: "graded",
      plugindata: %{
        assignfeedbackcomments_editor: %{
          text: grade.feedback,
          format: 1
        }
      }
    }

    case api_request(params) do
      {:ok, _response} ->
        Logger.info("Successfully uploaded grade for submission #{grade.submission_id}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to upload grade: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private Functions

  defp api_request(params) do
    config = Application.get_env(:awap_backend, __MODULE__)
    base_url = Keyword.fetch!(config, :base_url)
    api_endpoint = Keyword.get(config, :api_endpoint, "/webservice/rest/server.php")

    url = "#{base_url}#{api_endpoint}"

    case http_client().get(url, params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Moodle API request failed: #{status} - #{inspect(body)}")
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_assignments(response) do
    # Parse Moodle API response into assignment structs
    # This is a simplified version - actual implementation would handle
    # all assignment fields
    courses = Map.get(response, "courses", [])

    Enum.flat_map(courses, fn course ->
      assignments = Map.get(course, "assignments", [])

      Enum.map(assignments, fn assignment ->
        %{
          id: Map.get(assignment, "id"),
          course_id: Map.get(assignment, "course"),
          name: Map.get(assignment, "name"),
          description: Map.get(assignment, "intro"),
          due_date: parse_timestamp(Map.get(assignment, "duedate")),
          allow_submissions_from: parse_timestamp(Map.get(assignment, "allowsubmissionsfromdate"))
        }
      end)
    end)
  end

  defp parse_submission(response) do
    # Parse single submission
    %{
      id: Map.get(response, "id"),
      assignment_id: Map.get(response, "assignment"),
      user_id: Map.get(response, "userid"),
      submitted_at: parse_timestamp(Map.get(response, "timemodified")),
      status: Map.get(response, "status"),
      files: Map.get(response, "plugins", [])
    }
  end

  defp parse_submissions(response) do
    assignments = Map.get(response, "assignments", [])

    Enum.flat_map(assignments, fn assignment ->
      submissions = Map.get(assignment, "submissions", [])
      Enum.map(submissions, &parse_submission/1)
    end)
  end

  defp parse_timestamp(nil), do: nil
  defp parse_timestamp(0), do: nil

  defp parse_timestamp(unix_timestamp) when is_integer(unix_timestamp) do
    DateTime.from_unix!(unix_timestamp)
  end

  defp http_client do
    # Use HTTPoison, Tesla, or similar HTTP client
    # This is a stub that would be replaced with actual HTTP client
    AwapBackend.Moodle.HTTPClient
  end
end
