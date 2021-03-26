defmodule Mailer.Migrations.V01 do
  @moduledoc false

  use Ecto.Migration

  def up do
    execute("CREATE TYPE email_status AS ENUM ('pending', 'processing', 'sent', 'error', 'processed')")

    create table(:emails, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:status, :email_status, null: false, default: "pending")
      add(:error, :string)
      add(:data, :map, null: false)
      timestamps()
    end
  end

  def down do
    drop(table(:emails))
    execute("drop type email_status")
  end
end
