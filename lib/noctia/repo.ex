defmodule Noctia.Repo do
  use Ecto.Repo,
    otp_app: :noctia,
    adapter: Ecto.Adapters.Postgres
end
