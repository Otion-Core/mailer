import Config

config :mailer, ecto_repos: [Mailer.Repo]

# Configure your database
config :mailer, Mailer.Repo,
  username: System.get_env("DB_USER", "bite"),
  password: System.get_env("DB_PASSWORD", "bite"),
  database: System.get_env("DB_NAME", "mailer_test"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432"),
  pool: Ecto.Adapters.SQL.Sandbox

# disable plugins, enqueueing scheduled jobs and job 
# dispatching altogether when testing
config :mailer, Oban, repo: Mailer.Repo, queues: false, plugins: false

# Mailer configuration for tests
config :mailer, Mailer,
  repo: Mailer.Repo,
  adapter: Mailer.TestAdapter,
  sender: [name: "John", email: "john@farscape.com"]
