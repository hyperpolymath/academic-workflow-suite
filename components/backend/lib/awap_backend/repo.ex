defmodule AwapBackend.Repo do
  @moduledoc """
  PostgreSQL repository for the AWAP backend.

  Configured to use binary UUIDs as primary keys for better distribution
  and obfuscation of record counts.
  """

  use Ecto.Repo,
    otp_app: :awap_backend,
    adapter: Ecto.Adapters.Postgres
end
