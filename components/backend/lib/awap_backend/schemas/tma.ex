defmodule AwapBackend.Schemas.TMA do
  @moduledoc """
  TMA (Tutor Marked Assignment) schema.

  Represents a submitted assignment that needs to be processed and marked.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          assignment_id: String.t(),
          student_id: String.t(),
          course_id: String.t(),
          content: map(),
          status: atom(),
          job_id: String.t() | nil,
          error_message: String.t() | nil,
          submitted_at: DateTime.t(),
          processed_at: DateTime.t() | nil,
          feedback: AwapBackend.Schemas.Feedback.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tmas" do
    field :assignment_id, :string
    field :student_id, :string
    field :course_id, :string
    field :content, :map
    field :status, Ecto.Enum, values: [:pending, :processing, :completed, :failed], default: :pending
    field :job_id, :string
    field :error_message, :string
    field :submitted_at, :utc_datetime
    field :processed_at, :utc_datetime

    has_one :feedback, AwapBackend.Schemas.Feedback

    timestamps()
  end

  @doc """
  Changeset for creating and updating TMAs.
  """
  def changeset(tma, attrs) do
    tma
    |> cast(attrs, [
      :assignment_id,
      :student_id,
      :course_id,
      :content,
      :status,
      :job_id,
      :error_message,
      :submitted_at,
      :processed_at
    ])
    |> validate_required([:assignment_id, :student_id, :course_id, :content])
    |> validate_inclusion(:status, [:pending, :processing, :completed, :failed])
    |> put_submitted_at()
  end

  defp put_submitted_at(changeset) do
    case get_field(changeset, :submitted_at) do
      nil -> put_change(changeset, :submitted_at, DateTime.utc_now())
      _ -> changeset
    end
  end
end
