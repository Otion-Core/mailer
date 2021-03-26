defmodule Mailer do
  @moduledoc """
  A simple api to send emails and to keep track of success/failures.

  The default adapter is SendGrid. You will need to configure the
  `SENDGRID_TOKEN` environment variable in order to authenticate your requests.

  By default, sending emails is disabled. To enable this, you need
  to set the `ENABLE_EMAILS` to `true`.

  Usage:

  1. Compose your email:

  ```
  alias Mailer
  alias Mailer.Email

  email = Email.new()
    |> Email.from(name: "Mrs Foo", email: "foo@foo.com")
    |> Email.to(name: "Mrs Bar", email: "bar@bar.com")
    |> Email.to(name: "Mr Baz", email: "baz@baz.com")
    |> Email.subject("Hello")
    |> Email.template("...")
    |> Email.value("some_value", "value")
    |> Email.value("some_other", "value")

  ```

  2. Send it:

  ```
  :ok = Mailer.send(email)
  ```

  3. Check its status:

  ```
  {:ok, email} = Mailer.get(email.id)
  IO.puts(email.status)
  ```

  4. Find emails by status:

  ```
  %{entries: entries} = Mailer.find_by(status: :sent)
  ```

  5. Delete old emails

  ```
  :ok = Mailer.prune()
  ```
  """

  require Logger

  alias Mailer.Backlog
  alias Mailer.Email
  alias Mailer.Telemetry
  alias Mailer.Validator

  @doc """
  Prints out a warning message if emails are enabled
  and if the application env `warn_if_enabled` is also enabled
  """
  @spec warn_if_enabled() :: :ok
  def warn_if_enabled do
    if Application.get_env(:mailer, Mailer)[:warn_if_enabled] && "true" == System.get_env("ENABLE_EMAILS") do
      Logger.warn("CAUTION: Environment variable ENABLE_EMAILS is set and emails are enabled")
    end

    :ok
  end

  @doc """
  Returns the repo configured for the mailer
  """
  @spec repo() :: module()
  def repo do
    Application.get_env(:mailer, Mailer)[:repo] ||
      raise """
      Please specify a repo for the Mailer under the :repo key
      """
  end

  import Ecto.Query

  @doc """
  Sends the given email.

  This is a two-phase operation where:

  1. We create the email by validating it and adding an entry
     into our database.

  2. We add it to the backlog for later delivery
  """
  @spec send(Email.t()) :: :ok | {:error, term()}
  def send(email) do
    with :ok <- Validator.validate(email),
         {:ok, email} <- schedule(email) do
      Telemetry.execute(:pending, email)
    else
      {:error, e} = err ->
        Telemetry.execute(:error, %{email: email, error: e})
        err
    end
  end

  @doc """
  Returns the status of a given email, given its id.

  """
  @spec get(String.t()) :: {:ok, map()} | {:error, term()}
  def get(id) do
    case repo().get(Email, id) do
      nil ->
        {:error, :not_found}

      email ->
        {:ok, email}
    end
  end

  @doc """
  Updates the given email.

  Uses a special changeset so that only the status
  and optionnaly the error information can be modified
  """
  @spec update(Email.t(), map()) :: {:ok, Email.t()} | {:error, term()}
  def update(email, params) do
    email
    |> Email.update_changeset(params)
    |> repo().update()
  end

  @doc """
  Returns ranges of emails

  This is useful for eg fetching emails by status. It is possible
  to specify a :page, and a :page_size, eg:

  ```
  %Scrivener.Page{entries: ...}
    = Mailer.find_by(status: :error, page: 1, page_size: 20)
  ```
  """
  @spec find_by(Keyword.t()) :: Scrivener.Page.t()
  def find_by(opts) do
    page = opts[:page] || 1
    page_size = opts[:page_size] || 10
    opts = Keyword.drop(opts, [:page, :page_size])

    Email
    |> where(^opts)
    |> order_by(desc: :inserted_at)
    |> repo().paginate(page: page, page_size: page_size)
  end

  @doc """
  Prunes old emails that have been processed

  Only deletes emails that are either :processed,
  :sent or in :error
  """
  @spec prune() :: :ok
  def prune do
    from(e in Email,
      where: e.status in [:processed, :sent, :error]
    )
    |> repo().delete_all()

    :ok
  end

  # Insert the email and enqueue it in oban all
  # in the same database transaction
  defp schedule(email) do
    repo().transaction(fn ->
      with {:ok, email} <- insert(email),
           :ok <- Backlog.add(email) do
        email
      end
    end)
  end

  defp insert(email) do
    params =
      email
      |> Map.from_struct()
      |> Map.put(:status, :pending)

    %Email{}
    |> Email.changeset(params)
    |> repo().insert()
  end
end
