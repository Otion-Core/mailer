defmodule Mailer.Repo do
  use Ecto.Repo, otp_app: :mailer, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 5, max_page_size: 10
end
