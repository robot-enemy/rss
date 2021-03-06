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
    |> normalise_guid()
    |> normalise_link()
    |> normalise_updated()
    |> Map.put(:entries, Enum.map(data.entries, &normalise_entry/1))
  end

  defp normalise_author(data) do
    Map.put(data, :author, data[:author] || data[:"rss2:dc:creator"])
  end

  defp normalise_entry(entry) do
    entry
    |> normalise_guid()
    |> normalise_link()
    |> normalise_author()
    |> Map.put(:published_at, entry[:"rss2:pubDate"])
  end

  def normalise_guid(data),
    do: Map.put(data, :guid, data[:guid] || data[:"rss2:guid"])

  defp normalise_link(data),
    do: Map.put(data, :link, data[:link] || data[:"atom:link"] || data[:"rss2:link"])

  defp normalise_updated(%{updated: nil} = data),
    do: Map.put(data, :updated, data[:"rss2:lastBuildDate"] || data[:"rss2:pubDate"])
  defp normalise_updated(data), do: data

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
