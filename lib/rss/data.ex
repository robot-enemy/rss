defmodule RSS.Data do
  @moduledoc """
  Parses and normalises the data returned from the internet.
  """
  import Util.Map, only: [convert_string_keys_to_atoms: 1]

  @doc """
  Given a parsed data map, normalises the data.
  """
  @spec normalise(data :: map()) ::
          {:ok, map()} | {:error, any()}

  def normalise(data) do
    data = convert_string_keys_to_atoms(data)
    normalised =
      data
      |> Map.put(:last_built_at, format_date(data[:last_build_date]))
      |> Map.put(:published_at, format_date(data[:pub_date]))
      |> Map.put(:items, Enum.map(data.items, &normalise_item/1))

    {:ok, normalised}
  end

  def normalise_item(item) do
    item
    |> Map.put(:published_at, format_date(item.pub_date))
  end

  defp format_date(date_str) when is_binary(date_str) do
    case DateTimeParser.parse_datetime(date_str) do
      {:ok, datetime} -> datetime
      _error -> nil
    end
  end
  defp format_date(_), do: nil

  @doc """
  Given the data returned from a valid RSS feed, returns a parsed data structure.
  """
  @spec parse(binary()) ::
          {:error, RSS.Error.t()} | {:ok, map()}

  def parse(data) when is_binary(data) do
    case FastRSS.parse(data) do
      {:error, reason} ->
        {:error, %RSS.Error{reason: "RSS.Data.parse/1: #{reason}"}}
      ok ->
        ok
    end
  end
  def parse(_data) do
    {
      :error,
      %RSS.Error{reason: "RSS.Data.parse/1 expected data as a string"}
    }
  end

end
