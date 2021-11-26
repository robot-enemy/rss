defmodule RSS.Data do
  @moduledoc """
  Parses and normalises the data returned from the internet.
  """

  @doc """
  Given a parsed data map, normalises the data.
  """
  @spec normalise(data :: map()) ::
          {:ok, map()} | {:error, any()}

  def normalise(data) do
    data
    |> normalise_link()
    |> Map.put(:entries, Enum.map(data.entries, &normalise_entry/1))
  end

  defp normalise_author(data) do
    Map.put(data, :author, data[:author] || data[:"rss2:dc:creator"])
  end

  defp normalise_entry(entry) do
    entry
    |> normalise_link()
    |> normalise_author()
    |> Map.put(:published_at, entry[:"rss2:pubDate"])
  end

  defp normalise_link(data) do
    Map.put(data, :link, data[:link] || data[:"rss2:link"] || data[:"atom:link"])
  end

  @doc """
  Given the data returned from a valid RSS feed, returns a parsed data structure.
  """
  @spec parse(binary()) ::
          {:error, RSS.Error.t()} | {:ok, map()}

  def parse(data) when is_binary(data) do
    case ElixirFeedParser.parse(data) do
      {:error, reason} ->
        {:error, %RSS.Error{reason: "RSS.Data.parse/1: #{reason}"}}
      ok ->
        ok
    end
  end
  def parse(_data) do
    {
      :error,
      %RSS.Error{reason: "RSS.Data.parse/1 expected data as a binary"}
    }
  end

end
