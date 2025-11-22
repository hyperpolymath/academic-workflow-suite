defmodule AwapBackend.Repo.Migrations.CreateAuditLog do
  @moduledoc """
  Creates the audit_log table for tracking system actions and events.

  This provides an application-level audit trail in addition to the
  event store used by the Rust core engine.
  """

  use Ecto.Migration

  def change do
    create table(:audit_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :binary_id
      add :actor_id, :string
      add :actor_type, :string
      add :metadata, :map, default: %{}
      add :ip_address, :string
      add :user_agent, :string
      add :result, :string
      add :error_message, :text

      add :timestamp, :utc_datetime, null: false
    end

    create index(:audit_log, [:action])
    create index(:audit_log, [:resource_type])
    create index(:audit_log, [:resource_id])
    create index(:audit_log, [:actor_id])
    create index(:audit_log, [:timestamp])
    create index(:audit_log, [:resource_type, :resource_id])
  end
end
