defmodule AwapBackend.TMA do
  @moduledoc """
  Context module for TMA (Tutor Marked Assignment) operations.

  Provides functions to:
  - Create and update TMAs
  - Query TMA status
  - Store processing results
  - Manage feedback
  """

  import Ecto.Query
  alias AwapBackend.Repo
  alias AwapBackend.Schemas.{TMA, Feedback}

  require Logger

  @doc """
  Creates a new TMA record.
  """
  @spec create_tma(map()) :: {:ok, TMA.t()} | {:error, Ecto.Changeset.t()}
  def create_tma(attrs) do
    %TMA{}
    |> TMA.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a TMA by ID.
  """
  @spec get_tma(String.t()) :: {:ok, TMA.t()} | {:error, :not_found}
  def get_tma(id) do
    case Repo.get(TMA, id) do
      nil -> {:error, :not_found}
      tma -> {:ok, tma}
    end
  end

  @doc """
  Gets a TMA with its feedback preloaded.
  """
  @spec get_tma_with_feedback(String.t()) :: {:ok, TMA.t()} | {:error, :not_found}
  def get_tma_with_feedback(id) do
    case Repo.get(TMA, id) |> Repo.preload(:feedback) do
      nil -> {:error, :not_found}
      tma -> {:ok, tma}
    end
  end

  @doc """
  Updates a TMA with processing results and feedback.
  """
  @spec update_with_feedback(String.t(), String.t(), map()) ::
          {:ok, TMA.t()} | {:error, term()}
  def update_with_feedback(tma_id, job_id, feedback_data) do
    Repo.transaction(fn ->
      with {:ok, tma} <- get_tma(tma_id),
           {:ok, tma} <- update_tma_status(tma, :completed, job_id),
           {:ok, _feedback} <- create_feedback(tma.id, feedback_data) do
        tma
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Updates a TMA with error information.
  """
  @spec update_with_error(String.t(), String.t(), term()) :: {:ok, TMA.t()} | {:error, term()}
  def update_with_error(tma_id, job_id, error_reason) do
    with {:ok, tma} <- get_tma(tma_id) do
      tma
      |> TMA.changeset(%{
        status: :failed,
        job_id: job_id,
        error_message: inspect(error_reason),
        processed_at: DateTime.utc_now()
      })
      |> Repo.update()
    end
  end

  @doc """
  Lists TMAs with optional filters.
  """
  @spec list_tmas(keyword()) :: list(TMA.t())
  def list_tmas(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    status = Keyword.get(opts, :status)

    TMA
    |> maybe_filter_by_status(status)
    |> order_by([t], desc: t.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Gets feedback for a TMA.
  """
  @spec get_feedback(String.t()) :: {:ok, Feedback.t()} | {:error, :not_found}
  def get_feedback(tma_id) do
    case Repo.get_by(Feedback, tma_id: tma_id) do
      nil -> {:error, :not_found}
      feedback -> {:ok, feedback}
    end
  end

  # Private Functions

  defp update_tma_status(tma, status, job_id) do
    tma
    |> TMA.changeset(%{
      status: status,
      job_id: job_id,
      processed_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  defp create_feedback(tma_id, feedback_data) do
    %Feedback{}
    |> Feedback.changeset(Map.put(feedback_data, :tma_id, tma_id))
    |> Repo.insert()
  end

  defp maybe_filter_by_status(query, nil), do: query

  defp maybe_filter_by_status(query, status) do
    where(query, [t], t.status == ^status)
  end
end
