defmodule Mailer.Migrations do
  @moduledoc """
  Migrations create and modify the database tables Mailer needs
  to function.

  ## Usage
  To use migrations in your application you'll need to 
  generate an `Ecto.Migration` that wraps
  calls to `Mailer.Migrations`:

  ```bash
  mix ecto.gen.migration add_mailer
  ```

  Open the generated migration in your editor and call the `up` 
  and `down` functions on `Mailer.Migrations`:

  ```elixir
  defmodule MyApp.Repo.Migrations.AddMailer do
    use Ecto.Migration
    def up, do: Mailer.Migrations.up()
    def down, do: Mailer.Migrations.down()
  end

  ```
  This will run all of Mailer's versioned migrations for your database. 

  Now, run the migration to create the table:

  ```bash
  mix ecto.migrate
  ```
  """

  use Ecto.Migration

  @migrations [
    Mailer.Migrations.V01
  ]

  def up do
    Enum.each(@migrations, fn m ->
      m.up()
    end)
  end

  def down do
    Enum.each(@migrations, fn m ->
      m.down()
    end)
  end
end
