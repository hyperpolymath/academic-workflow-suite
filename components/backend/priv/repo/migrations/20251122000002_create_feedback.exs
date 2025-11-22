defmodule AwapBackend.Repo.Migrations.CreateFeedback do
  @moduledoc """
  Creates the feedback table for storing TMA feedback and grades.
  """

  use Ecto.Migration

  def change do
    create table(:feedback, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tma_id, references(:tmas, type: :binary_id, on_delete: :delete_all), null: false
      add :grade, :float
      add :feedback_text, :text, null: false
      add :marking_criteria, :map
      add :strengths, {:array, :text}, default: []
      add :improvements, {:array, :text}, default: []
      add :generated_at, :utc_datetime, null: false
      add :reviewed_by, :string
      add :reviewed_at, :utc_datetime

      timestamps()
    end

    create index(:feedback, [:tma_id])
    create unique_index(:feedback, [:tma_id])
    create index(:feedback, [:generated_at])
  end
end
