defmodule Rescutex.AI.Error do
  @moduledoc """
  This struct is used to communicate errors related to IA.

  TODO: Need to explore other implementations to have a more generic error handling.
  """

  defexception [:reason_code, :reason, :message, :details]

  @type t :: %__MODULE__{
          reason: atom(),
          reason_code: integer() | nil,
          message: String.t() | nil,
          details: any() | nil
        }

  @spec new(
          reason :: atom(),
          reason_code :: integer() | nil,
          message :: String.t() | nil,
          details :: any() | nil
        ) :: t()
  def new(reason, reason_code \\ nil, message \\ nil, details \\ nil) do
    %__MODULE__{reason: reason, reason_code: reason_code, message: message, details: details}
  end
end
