defmodule Mailer.Email do
  @moduledoc """
  The mode that represents an email.

  We add some metadata in order to track its status:

  * :pending: the email was queued for delivery
  * :processing: the email is being processed
  * :sent: the email was actually sent using our email provider
  * :error: there was an error while trying to send the email
    through the email gateway
  * :processed: that the mailer is running in debug mode,
    the email was not actually sent, but it is considered to
    be fully processed

  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "emails" do
    field(:data, :map)
    field(:error, :string)

    field(:status, Ecto.Enum,
      values: [:pending, :processing, :sent, :error, :processed],
      default: :pending
    )

    timestamps()
  end

  @doc false
  def changeset(email, params) do
    email
    |> cast(params, [:id, :status, :data])
    |> validate_required([:id, :status, :data])
    |> unique_constraint(:id, name: :emails_pkey, message: "conflict")
  end

  @doc false
  def update_changeset(email, params) do
    email
    |> cast(params, [:status, :error])
    |> validate_required([:status])
  end

  @doc """
  Create a new email struct.

  The email will have a new random uuid
  as its id. If a default sender was configured in the Mailer
  application environment, it will be used.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      status: :pending,
      data: %{
        "to" => [],
        "values" => %{},
        "attachments" => []
      }
    }
    |> with_default_sender()
  end

  defp with_default_sender(email) do
    with_default_sender(email, Application.get_env(:mailer, Mailer)[:sender])
  end

  defp with_default_sender(email, nil), do: email

  defp with_default_sender(%{data: data} = email, sender) do
    data = Map.put(data, "from", %{"name" => sender[:name], "email" => sender[:email]})
    %{email | data: data}
  end

  @doc """
  Sets the `from` field
  """
  @spec from(t(), Keyword.t()) :: t()
  def from(%{data: data} = email, name: name, email: from) do
    data = Map.put(data, "from", %{"name" => name, "email" => from})
    %{email | data: data}
  end

  @doc """
  Sets the `subject` field
  """
  @spec subject(t(), String.t()) :: t()
  def subject(%{data: data} = email, subject) do
    data = Map.put(data, "subject", subject)
    %{email | data: data}
  end

  @doc """
  Sets the `template` field
  """
  @spec template(t(), String.t()) :: t()
  def template(%{data: data} = email, template) do
    data = Map.put(data, "template", template)
    %{email | data: data}
  end

  @doc """
  Adds a `to` field
  """
  @spec to(t(), Keyword.t()) :: t()
  def to(%{data: %{"to" => to} = data} = email, name: name, email: from) do
    to = [%{"name" => name, "email" => from} | to]
    data = Map.put(data, "to", to)
    %{email | data: data}
  end

  @doc """
  Adds a `value` field
  """
  @spec value(t(), String.t(), any()) :: t()
  def value(%{data: %{"values" => values} = data} = email, name, value) do
    values = Map.put(values, name, value)
    data = Map.put(data, "values", values)
    %{email | data: data}
  end
end
