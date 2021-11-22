defmodule RSS.Parsers.FeederEx do
  @moduledoc false

  def parse(data) do
    case FeederEx.parse(data) do
      {:ok, feed, _} ->
        {:ok, strip_structs(feed)}
      error ->
        error
    end
  end

  defp strip_structs(%FeederEx.Feed{} = feed) do
    feed
    |> Map.from_struct()
    |> Map.put(:entries, Enum.map(feed.entries, &Map.from_struct/1))
  end

end
