defmodule Mailer.Delivery do
  @moduledoc """
  Implements the delivery of emails

  This is implemented in a separate module in case
  we want to do immediate delivery of emails without
  using Oban.
  """

  alias Mailer
  alias Mailer.{Email, Telemetry}
  require Logger

  @doc """
  Returns the adapter module that talks to the actual
  mail provider
  """
  @spec adapter() :: module()
  def adapter do
    Application.get_env(:mailer, Mailer)[:adapter] ||
      raise """
        Please configure a mailer adapter by setting
        the :adapter key in the Mailer application env
      """
  end

  @doc """
  Deliver an email, tracking its status

  """
  @spec deliver(Email.t()) :: {:ok, Email.t()} | {:error, term()}
  def deliver(email) do
    with {:ok, email} <- Mailer.update(email, %{status: :processing}),
         {:ok, result} <- send_email(email),
         {:ok, email} <- Mailer.update(email, %{status: result}),
         :ok <- Telemetry.execute(result, email) do
      {:ok, email}
    else
      {:error, e} = err ->
        Mailer.update(email, %{status: :error, error: "#{inspect(e)}"})
        Telemetry.execute(:error, %{email: email, error: e})
        err
    end
  end

  defp send_email(email) do
    enabled = System.get_env("ENABLE_EMAILS", "false") == "true"
    send_email(email, enabled)
  end

  defp send_email(_, false), do: {:ok, :processed}

  defp send_email(%{data: data}, true) do
    with :ok <- adapter().send(data) do
      {:ok, :sent}
    end
  end
end
