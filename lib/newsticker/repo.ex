defmodule Newsticker.Repo do
  use Ecto.Repo,
    otp_app: :newsticker,
    adapter: Ecto.Adapters.Postgres
end
