defmodule AwapBackend.Schemas.Submission do
  @moduledoc """
  Submission schema for Moodle assignment submissions.

  Represents a student's submission downloaded from Moodle that needs
  to be converted into a TMA for processing.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          moodle_submission_id: integer(),
          moodle_assignment_id: integer(),
          moodle_user_id: integer(),
          course_id: Ecto.UUID.t(),
          status: atom(),
          submitted_at: DateTime.t(),
          grade: float() | nil,
          graded_at: DateTime.t() | nil,
          files: list(map()),
          raw_data: map(),
          tma_id: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "submissions" do
    field :moodle_submission_id, :integer
    field :moodle_assignment_id, :integer
    field :moodle_user_id, :integer
    field :status, Ecto.Enum,
      values: [:new, :downloaded, :processing, :graded, :uploaded, :failed],
      default: :new
    field :submitted_at, :utc_datetime
    field :grade, :float
    field :graded_at, :utc_datetime
    field :files, {:array, :map}, default: []
    field :raw_data, :map, default: %{}

    belongs_to :course, AwapBackend.Schemas.Course
    belongs_to :tma, AwapBackend.Schemas.TMA

    timestamps()
  end

  @doc """
  Changeset for creating submissions from Moodle sync.
  """
  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [
      :moodle_submission_id,
      :moodle_assignment_id,
      :moodle_user_id,
      :course_id,
      :status,
      :submitted_at,
      :grade,
      :graded_at,
      :files,
      :raw_data,
      :tma_id
    ])
    |> validate_required([:moodle_submission_id, :moodle_assignment_id, :moodle_user_id])
    |> validate_number(:moodle_submission_id, greater_than: 0)
    |> validate_number(:moodle_assignment_id, greater_than: 0)
    |> validate_number(:moodle_user_id, greater_than: 0)
    |> validate_number(:grade, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint([:moodle_submission_id, :moodle_assignment_id])
  end

  @doc """
  Changeset for updating submission status.
  """
  def status_changeset(submission, status) do
    submission
    |> change(%{status: status})
    |> validate_inclusion(:status, [:new, :downloaded, :processing, :graded, :uploaded, :failed])
  end

  @doc """
  Changeset for marking a submission as graded.
  """
  def grade_changeset(submission, grade) do
    submission
    |> change(%{
      grade: grade,
      graded_at: DateTime.utc_now(),
      status: :graded
    })
    |> validate_number(:grade, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
