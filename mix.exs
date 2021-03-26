defmodule Mailer.MixProject do
  use Mix.Project

  def project do
    [
      app: :mailer,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix]
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  # Specifies which paths to compile per environment.    
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.4"},
      {:excoveralls, "~> 0.13", only: :test},
      {:hackney, "~> 1.8"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.0"},
      {:oban, "~> 2.5.0"},
      {:postgrex, ">= 0.0.0"},
      {:pre_commit, git: "https://github.com/dwyl/elixir-pre-commit.git", branch: "master", only: :dev},
      {:scrivener_ecto, "~> 2.0"},
      {:sentry, "~> 8.0"},
      {:sobelow, "~> 0.8", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.    
  # For example, to install project dependencies and perform other setup tasks, run:    
  #    
  #     $ mix setup    
  #    
  # See the documentation for `Mix` for more info on aliases.    
  defp aliases do
    [
      setup: ["deps.get"],
      test: ["ecto.create --quiet", "test"],
      quality: [
        "format --check-formatted",
        "credo --strict",
        "sobelow -i Config.HTTPS --exit low"
      ]
    ]
  end
end
