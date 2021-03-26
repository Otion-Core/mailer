defmodule Mailer.SendGrid do
  @moduledoc """
  A simpler mailer adapter that uses SendGrid's
  REST api
  """
  @behaviour Mailer.Adapter

  @doc """
  Sends the email using SendGrid. Any response that does
  not contain a 202 status code will be considered as an error
  """
  @spec send(map()) :: :ok | {:error, term()}
  @impl Mailer.Adapter
  def send(%{"from" => from, "to" => to, "subject" => subject, "template" => template, "values" => values}) do
    api_token = System.fetch_env!("SENDGRID_TOKEN")
    url = "https://api.sendgrid.com/v3/mail/send"

    body =
      Jason.encode!(%{
        "template_id" => template,
        "from" => from,
        "subject" => subject,
        "personalizations" => [
          %{
            "to" => to,
            "dynamic_template_data" => values
          }
        ]
      })

    headers = [{"Content-Type", "application/json"}, {"Authorization", "Bearer " <> api_token}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 202}} ->
        :ok

      {:ok, %HTTPoison.Response{body: body}} ->
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
