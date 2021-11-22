defmodule RSS.Behaviour do
  @moduledoc """
  Behaviour for the RSS module, making it easily mockable.

  The behaviour can easily be used in any module by adding `use RSS.Behaviour`.
  """

  @callback fetch(url :: binary()) ::
              {:ok, map()} | {:error, RSS.Error.t()}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

end
