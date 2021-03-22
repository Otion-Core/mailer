defmodule Mailer.TestCase do
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using _ do
    quote do
      @repo Application.compile_env(:mailer, Mailer)[:repo]
      use ExUnit.Case, async: false
      use Oban.Testing, repo: @repo
      import Ecto.Query
    end
  end

  setup do
    repo = Application.get_env(:mailer, Mailer)[:repo]
    :ok = Sandbox.checkout(repo)

    oban_opts = Application.get_env(:mailer, Oban)
    start_supervised!({Oban, oban_opts})

    :ok
  end
end

repo = Application.get_env(:mailer, Mailer)[:repo]
Mailer.Repo.start_link()

Ecto.Migrator.up(repo, 20_080_906_120_000, Oban.Migrations)
Ecto.Migrator.up(repo, 20_080_906_120_001, Mailer.Migrations)

ExUnit.start()
