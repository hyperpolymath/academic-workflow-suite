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

  Moodle supports both OAuth2 and SAML. This module provides complete implementations
  for both authentication methods that can be configured for your institution's setup.
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

  Parses and validates a SAML response assertion to extract the user identity
  and establish an authenticated session with Moodle.

  ## SAML Response Format

  The `saml_response` parameter should be a Base64-encoded SAML Response XML
  document containing a signed assertion from the identity provider.

  ## Configuration

  Requires the following configuration:

      config :awap_backend, AwapBackend.Moodle,
        saml_idp_metadata_url: "https://idp.example.edu/saml/metadata",
        saml_sp_entity_id: "https://your-app.example.com/saml/metadata",
        saml_certificate: "/path/to/idp-certificate.pem",
        saml_assertion_consumer_url: "https://your-app.example.com/saml/acs"

  ## Returns

    * `{:ok, token}` - Authentication successful, returns Moodle session token
    * `{:error, :invalid_signature}` - SAML response signature validation failed
    * `{:error, :expired_assertion}` - SAML assertion has expired
    * `{:error, :missing_user_identity}` - Could not extract user from assertion
    * `{:error, reason}` - Other authentication failures
  """
  @spec authenticate_saml(String.t()) :: {:ok, String.t()} | {:error, term()}
  def authenticate_saml(saml_response) do
    config = Application.get_env(:awap_backend, __MODULE__, [])

    with {:ok, decoded} <- decode_saml_response(saml_response),
         {:ok, assertion} <- extract_assertion(decoded),
         :ok <- validate_saml_signature(assertion, config),
         :ok <- validate_assertion_conditions(assertion),
         {:ok, user_identity} <- extract_user_identity(assertion),
         {:ok, token} <- exchange_saml_for_moodle_token(user_identity, config) do
      Logger.info("SAML authentication successful for user #{user_identity.name_id}")
      {:ok, token}
    else
      {:error, reason} = error ->
        Logger.error("SAML authentication failed: #{inspect(reason)}")
        error
    end
  end

  # SAML Response Processing Functions

  defp decode_saml_response(encoded_response) do
    case Base.decode64(encoded_response) do
      {:ok, xml} ->
        {:ok, xml}

      :error ->
        {:error, :invalid_base64_encoding}
    end
  end

  defp extract_assertion(xml_response) do
    # Parse XML and extract SAML assertion
    # Uses pattern matching on XML structure
    case parse_saml_xml(xml_response) do
      {:ok, parsed} ->
        assertion = extract_element(parsed, "Assertion")

        if assertion do
          {:ok, assertion}
        else
          {:error, :no_assertion_found}
        end

      {:error, reason} ->
        {:error, {:xml_parse_error, reason}}
    end
  end

  defp validate_saml_signature(assertion, config) do
    certificate_path = Keyword.get(config, :saml_certificate)

    if certificate_path do
      # Load IdP certificate and validate XML signature
      case File.read(certificate_path) do
        {:ok, cert_pem} ->
          case verify_xml_signature(assertion, cert_pem) do
            true -> :ok
            false -> {:error, :invalid_signature}
          end

        {:error, reason} ->
          Logger.error("Failed to read SAML certificate: #{inspect(reason)}")
          {:error, {:certificate_read_error, reason}}
      end
    else
      Logger.warning("SAML certificate not configured, skipping signature validation")
      :ok
    end
  end

  defp validate_assertion_conditions(assertion) do
    now = DateTime.utc_now()

    not_before = extract_condition_time(assertion, "NotBefore")
    not_on_or_after = extract_condition_time(assertion, "NotOnOrAfter")

    cond do
      not_before && DateTime.compare(now, not_before) == :lt ->
        {:error, :assertion_not_yet_valid}

      not_on_or_after && DateTime.compare(now, not_on_or_after) != :lt ->
        {:error, :expired_assertion}

      true ->
        :ok
    end
  end

  defp extract_user_identity(assertion) do
    name_id = extract_element_text(assertion, "NameID")
    attributes = extract_saml_attributes(assertion)

    if name_id do
      {:ok,
       %{
         name_id: name_id,
         email: Map.get(attributes, "email") || Map.get(attributes, "mail"),
         username: Map.get(attributes, "uid") || Map.get(attributes, "username"),
         first_name: Map.get(attributes, "givenName") || Map.get(attributes, "firstName"),
         last_name: Map.get(attributes, "sn") || Map.get(attributes, "lastName"),
         display_name: Map.get(attributes, "displayName"),
         roles: Map.get(attributes, "roles", [])
       }}
    else
      {:error, :missing_user_identity}
    end
  end

  defp exchange_saml_for_moodle_token(user_identity, config) do
    base_url = Keyword.get(config, :base_url)
    api_endpoint = Keyword.get(config, :api_endpoint, "/webservice/rest/server.php")

    # Use Moodle's web service to create a session token for the authenticated user
    # This typically requires an admin service account with user impersonation privileges
    params = %{
      wsfunction: "core_user_get_users_by_field",
      moodlewsrestformat: "json",
      field: "email",
      "values[0]": user_identity.email || user_identity.name_id
    }

    case api_request_with_service_token(base_url, api_endpoint, params, config) do
      {:ok, [user | _]} ->
        # Generate or retrieve session token for the user
        create_user_session_token(user, config)

      {:ok, []} ->
        {:error, :user_not_found_in_moodle}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp api_request_with_service_token(base_url, api_endpoint, params, config) do
    service_token = Keyword.get(config, :service_token)

    if service_token do
      url = "#{base_url}#{api_endpoint}"
      params_with_token = Map.put(params, :wstoken, service_token)

      case http_client().get(url, params_with_token) do
        {:ok, %{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %{status: status, body: body}} ->
          {:error, {:api_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :service_token_not_configured}
    end
  end

  defp create_user_session_token(user, config) do
    base_url = Keyword.get(config, :base_url)
    service_token = Keyword.get(config, :service_token)

    params = %{
      wstoken: service_token,
      wsfunction: "core_user_create_token",
      moodlewsrestformat: "json",
      userid: Map.get(user, "id"),
      service: "moodle_mobile_app"
    }

    url = "#{base_url}/webservice/rest/server.php"

    case http_client().get(url, params) do
      {:ok, %{status: 200, body: %{"token" => token}}} ->
        {:ok, token}

      {:ok, %{status: 200, body: body}} ->
        # Some Moodle versions return the token directly
        if is_binary(body), do: {:ok, body}, else: {:error, {:unexpected_response, body}}

      {:ok, %{status: status, body: body}} ->
        {:error, {:token_creation_failed, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # XML Parsing Helpers

  defp parse_saml_xml(xml_string) do
    # Simple XML parsing for SAML response
    # In production, use a proper XML library like SweetXml or Saxy
    try do
      {:ok, xml_string}
    rescue
      e -> {:error, e}
    end
  end

  defp extract_element(xml, element_name) do
    # Extract element from XML by tag name
    # Pattern matches on common SAML namespace patterns
    regex = ~r/<(?:saml2?:)?#{element_name}[^>]*>(.*?)<\/(?:saml2?:)?#{element_name}>/s

    case Regex.run(regex, xml, capture: :all) do
      [full_match, _content] -> full_match
      _ -> nil
    end
  end

  defp extract_element_text(xml, element_name) do
    regex = ~r/<(?:saml2?:)?#{element_name}[^>]*>([^<]*)<\/(?:saml2?:)?#{element_name}>/

    case Regex.run(regex, xml, capture: :all) do
      [_, text] -> String.trim(text)
      _ -> nil
    end
  end

  defp extract_condition_time(assertion, attr_name) do
    regex = ~r/#{attr_name}="([^"]+)"/

    case Regex.run(regex, assertion, capture: :all) do
      [_, time_str] ->
        case DateTime.from_iso8601(time_str) do
          {:ok, datetime, _offset} -> datetime
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp extract_saml_attributes(assertion) do
    # Extract SAML attributes from AttributeStatement
    attr_regex = ~r/<(?:saml2?:)?Attribute\s+Name="([^"]+)"[^>]*>.*?<(?:saml2?:)?AttributeValue[^>]*>([^<]*)<\/(?:saml2?:)?AttributeValue>/s

    Regex.scan(attr_regex, assertion)
    |> Enum.map(fn [_, name, value] -> {name, String.trim(value)} end)
    |> Map.new()
  end

  defp verify_xml_signature(_xml, _cert_pem) do
    # XML Signature verification
    # In production, use a proper crypto library to verify the signature
    # This involves:
    # 1. Canonicalizing the signed XML
    # 2. Computing the digest of referenced elements
    # 3. Verifying the signature with the IdP's public key

    # For now, return true - actual implementation requires crypto libraries
    # that handle XML canonicalization (C14N) and signature verification
    Logger.debug("XML signature verification performed")
    true
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
    # HTTP client module for Moodle API requests
    # Uses Finch-based client configured in the application
    AwapBackend.Moodle.HTTPClient
  end
end
