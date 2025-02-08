defmodule Rescutex.Repo do
  use Ecto.Repo,
    otp_app: :rescutex,
    adapter: Ecto.Adapters.Postgres
end
