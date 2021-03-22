defmodule Mailer.TestAdapter do
  @moduledoc """
  A test adapter for emails during tests

  Depending on the email being sent, we will
  simulate different scenarios that will allow us
  to test the behaviour of our Mailer
  pipeline
  """

  def send(%{"subject" => "connect error" = subject}) do
    {:error, subject}
  end

  def send(_email), do: :ok
end
