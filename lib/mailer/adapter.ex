defmodule Mailer.Adapter do
  @moduledoc """
  A simple behaviour to be implemented by email
  adapters
  """

  @callback send(map()) :: :ok | {:error, term()}
end
