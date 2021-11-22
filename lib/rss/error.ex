defmodule RSS.Error do
  @moduledoc false

  @type t :: %__MODULE__{id: reference, reason: any}

  defexception id: nil, reason: nil

  def message(%__MODULE__{id: nil, reason: reason}), do: inspect(reason)
  def message(%__MODULE__{id: id, reason: reason}) do
    "[Ref: #{id} - #{inspect(reason)}"
  end
end
