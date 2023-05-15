defmodule NervousBot.Repo do
  use Ecto.Repo,
    otp_app: :nervous_bot,
    adapter: Ecto.Adapters.SQLite3
end
