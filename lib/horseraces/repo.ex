defmodule Horseraces.Repo do
  use Ecto.Repo,
    otp_app: :horseraces,
    adapter: Ecto.Adapters.Postgres
end
