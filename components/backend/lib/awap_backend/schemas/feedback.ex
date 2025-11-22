defmodule AwapBackend.Schemas.Feedback do
  @moduledoc """
  Feedback schema for TMA submissions.

  Stores generated feedback, grades, and marking details.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          tma_id: Ecto.UUID.t(),
          grade: float() | nil,
          feedback_text: String.t(),
          marking_criteria: map(),
          strengths: list(String.t()),
          improvements: list(String.t()),
          generated_at: DateTime.t(),
          reviewed_by: String.t() | nil,
          reviewed_at: DateTime.t() | nil,
          tma: AwapBackend.Schemas.TMA.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "feedback" do
    field :grade, :float
    field :feedback_text, :string
    field :marking_criteria, :map
    field :strengths, {:array, :string}, default: []
    field :improvements, {:array, :string}, default: []
    field :generated_at, :utc_datetime
    field :reviewed_by, :string
    field :reviewed_at, :utc_datetime

    belongs_to :tma, AwapBackend.Schemas.TMA

    timestamps()
  end

  @doc """
  Changeset for creating and updating feedback.
  """
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [
      :tma_id,
      :grade,
      :feedback_text,
      :marking_criteria,
      :strengths,
      :improvements,
      :generated_at,
      :reviewed_by,
      :reviewed_at
    ])
    |> validate_required([:tma_id, :feedback_text])
    |> validate_number(:grade, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0)
    |> foreign_key_constraint(:tma_id)
    |> put_generated_at()
  end

  defp put_generated_at(changeset) do
    case get_field(changeset, :generated_at) do
      nil -> put_change(changeset, :generated_at, DateTime.utc_now())
      _ -> changeset
    end
  end
end
