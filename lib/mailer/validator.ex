defmodule Mailer.Validator do
  @moduledoc """
  A provider agnostic validator for emails
  """
  alias Mailer.Email

  @doc """
  Checks that there is at least a from, to
  a subject and a template
  """
  def validate(%Email{
        data: %{
          "from" => %{"email" => _from},
          "to" => [%{"email" => _to} | _],
          "subject" => _subject,
          "template" => _template
        }
      }),
      do: :ok

  def validate(_), do: {:error, :invalid}
end
