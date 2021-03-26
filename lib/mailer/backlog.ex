defmodule Mailer.Backlog do
  @moduledoc """
  Implements a backlog of emails to be delivered

  This implementation is based on Oban

  """
  use Oban.Worker,
    queue: :emails,
    max_attempts: 3

  alias Mailer
  alias Mailer.{Delivery, Email, Telemetry}
  require Logger

  @doc """
  Add the email to the backlog, for later delivery

  """
  @spec add(Email.t()) :: :ok | {:error, term()}
  def add(%Email{id: id}) do
    with {:ok, _} <-
           %{id: id}
           |> new()
           |> Oban.insert() do
      :ok
    end
  end

  @doc """
  This is the callback that Oban will invoke in order
  to process actually process an email.

  If the email is not found, then we simply log a telemetry
  event but we will not retry the job
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    case Mailer.get(id) do
      {:ok, email} ->
        Delivery.deliver(email)

      {:error, :not_found} ->
        Telemetry.execute(:error, %{email: id, error: :not_found})
        :ok
    end
  end
end
