defmodule AwapBackendWeb.API.TMAController do
  @moduledoc """
  REST API controller for TMA operations.

  Provides endpoints for:
  - Submitting TMAs for marking
  - Checking TMA processing status
  - Retrieving generated feedback
  """

  use AwapBackendWeb, :controller

  alias AwapBackend.TMA
  alias AwapBackend.CoreEngine.WorkerPool

  require Logger

  @doc """
  POST /api/tmas

  Submit a TMA for processing.

  ## Request Body

      {
        "assignment_id": "uuid",
        "student_id": "uuid",
        "course_id": "uuid",
        "content": {
          "answers": [...],
          "attachments": [...]
        }
      }

  ## Response

      {
        "id": "uuid",
        "status": "pending",
        "submitted_at": "2025-11-22T12:00:00Z"
      }
  """
  def create(conn, params) do
    with {:ok, tma} <- TMA.create_tma(params),
         {:ok, job_id} <- WorkerPool.process_tma(tma.id, tma.content) do
      # Update TMA with job_id
      {:ok, updated_tma} = TMA.update_with_feedback(tma.id, job_id, %{})

      conn
      |> put_status(:created)
      |> json(%{
        id: tma.id,
        job_id: job_id,
        status: updated_tma.status,
        submitted_at: tma.submitted_at
      })
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})

      {:error, :pool_exhausted} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "Processing queue is full. Please try again later."})

      {:error, reason} ->
        Logger.error("Failed to create TMA: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to process TMA submission"})
    end
  end

  @doc """
  GET /api/tmas/:id

  Get TMA status and details.

  ## Response

      {
        "id": "uuid",
        "status": "completed",
        "submitted_at": "2025-11-22T12:00:00Z",
        "processed_at": "2025-11-22T12:05:00Z"
      }
  """
  def show(conn, %{"id" => id}) do
    case TMA.get_tma(id) do
      {:ok, tma} ->
        json(conn, %{
          id: tma.id,
          assignment_id: tma.assignment_id,
          status: tma.status,
          submitted_at: tma.submitted_at,
          processed_at: tma.processed_at,
          error_message: tma.error_message
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "TMA not found"})
    end
  end

  @doc """
  GET /api/tmas

  List TMAs with optional filters.

  ## Query Parameters

  - status: Filter by status (pending, processing, completed, failed)
  - limit: Maximum number of results (default: 50)

  ## Response

      {
        "tmas": [
          {
            "id": "uuid",
            "status": "completed",
            "submitted_at": "2025-11-22T12:00:00Z"
          }
        ]
      }
  """
  def index(conn, params) do
    opts = [
      status: params["status"],
      limit: parse_limit(params["limit"])
    ]

    tmas = TMA.list_tmas(opts)

    json(conn, %{
      tmas:
        Enum.map(tmas, fn tma ->
          %{
            id: tma.id,
            assignment_id: tma.assignment_id,
            status: tma.status,
            submitted_at: tma.submitted_at,
            processed_at: tma.processed_at
          }
        end)
    })
  end

  @doc """
  GET /api/feedback/:tma_id

  Get generated feedback for a TMA.

  ## Response

      {
        "tma_id": "uuid",
        "grade": 85.5,
        "feedback_text": "...",
        "strengths": ["...", "..."],
        "improvements": ["...", "..."],
        "generated_at": "2025-11-22T12:05:00Z"
      }
  """
  def get_feedback(conn, %{"tma_id" => tma_id}) do
    case TMA.get_feedback(tma_id) do
      {:ok, feedback} ->
        json(conn, %{
          tma_id: feedback.tma_id,
          grade: feedback.grade,
          feedback_text: feedback.feedback_text,
          marking_criteria: feedback.marking_criteria,
          strengths: feedback.strengths,
          improvements: feedback.improvements,
          generated_at: feedback.generated_at,
          reviewed_by: feedback.reviewed_by,
          reviewed_at: feedback.reviewed_at
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Feedback not found for this TMA"})
    end
  end

  # Private Functions

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp parse_limit(nil), do: 50
  defp parse_limit(limit) when is_binary(limit), do: String.to_integer(limit)
  defp parse_limit(limit) when is_integer(limit), do: limit
end
