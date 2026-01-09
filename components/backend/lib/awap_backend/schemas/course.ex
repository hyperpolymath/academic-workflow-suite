defmodule AwapBackend.Schemas.Course do
  @moduledoc """
  Course schema for Moodle LMS integration.

  Represents a course that is being synced from Moodle and contains
  assignments that need to be processed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          moodle_id: integer(),
          name: String.t(),
          short_name: String.t() | nil,
          description: String.t() | nil,
          sync_enabled: boolean(),
          last_synced_at: DateTime.t() | nil,
          sync_interval_minutes: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "courses" do
    field :moodle_id, :integer
    field :name, :string
    field :short_name, :string
    field :description, :string
    field :sync_enabled, :boolean, default: true
    field :last_synced_at, :utc_datetime
    field :sync_interval_minutes, :integer, default: 15

    has_many :tmas, AwapBackend.Schemas.TMA, foreign_key: :course_id, references: :moodle_id

    timestamps()
  end

  @doc """
  Changeset for creating and updating courses.
  """
  def changeset(course, attrs) do
    course
    |> cast(attrs, [
      :moodle_id,
      :name,
      :short_name,
      :description,
      :sync_enabled,
      :last_synced_at,
      :sync_interval_minutes
    ])
    |> validate_required([:moodle_id, :name])
    |> validate_number(:moodle_id, greater_than: 0)
    |> validate_number(:sync_interval_minutes, greater_than: 0)
    |> unique_constraint(:moodle_id)
  end

  @doc """
  Changeset for updating sync timestamp.
  """
  def sync_changeset(course) do
    course
    |> change(%{last_synced_at: DateTime.utc_now()})
  end
end
