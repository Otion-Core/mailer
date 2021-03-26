defmodule Mailer.Telemetry do
  @moduledoc """
  Implements telemetry events for emails
  """

  require Logger

  @doc """
  Attaches telemetry handlers for emails
  """
  @spec attach() :: :ok
  def attach do
    events = [
      [:mailer, :email, :pending],
      [:mailer, :email, :processing],
      [:mailer, :email, :processed],
      [:mailer, :email, :sent],
      [:mailer, :email, :error]
    ]

    :ok =
      :telemetry.attach_many(
        "analytic-emails-handler",
        events,
        &handle_event/4,
        nil
      )
  end

  @doc """
  Publishes a telemetry event.

  The event might have an optional measurements map.
  """
  @spec execute(atom(), map(), map()) :: :ok
  def execute(event, email, measurements \\ %{}) do
    :telemetry.execute([:mailer, :email, event], measurements, email)
  end

  @doc """
  Handles an email telemetry event.

  For now, we are only interested in errors
  """
  @spec handle_event(Keyword.t(), map(), map(), map()) :: :ok
  def handle_event([_, _, :error], _, meta, _) do
    Logger.error(meta)
  end

  def handle_event(_, _, _, _), do: :ok
end
