defmodule AwapBackend.Repo.Migrations.CreateTmas do
  @moduledoc """
  Creates the tmas table for storing TMA submissions.
  """

  use Ecto.Migration

  def change do
    create table(:tmas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :assignment_id, :string, null: false
      add :student_id, :string, null: false
      add :course_id, :string, null: false
      add :content, :map, null: false
      add :status, :string, null: false, default: "pending"
      add :job_id, :string
      add :error_message, :text
      add :submitted_at, :utc_datetime, null: false
      add :processed_at, :utc_datetime

      timestamps()
    end

    create index(:tmas, [:assignment_id])
    create index(:tmas, [:student_id])
    create index(:tmas, [:course_id])
    create index(:tmas, [:status])
    create index(:tmas, [:job_id])
    create index(:tmas, [:submitted_at])
  end
end
