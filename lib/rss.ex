defmodule RSS do
  @moduledoc """
  Documentation for `RSS`.
  """
  use RSS.Behaviour
  require Logger

  @doc """
  Given a valid RSS feed url, returns the formatted data.
  """
  @impl RSS.Behaviour

  def fetch(url) when is_binary(url) do
    with {:ok, url}  <- is_valid_url?(url),
         {:ok, data} <- RSS.HTTP.get(url),
         {:ok, data} <- RSS.Data.parse(data)
    do
      RSS.Data.normalise(data)
    else
      {:error, error} ->
        Logger.error RSS.Error.message(error)
        {:error, error}
    end
  end

  @doc """
  Given the path to an RSS feed, returns the raw data in a map.
  """
  def parse(path) when is_binary(path) do
    RSS.Parser.parse(path)
  end

  # This is an imperfect way of checking the URL is valid, but it'll do for our
  # purposes, as the URLs should be getting checked as they're being added to
  # the DB, and regular users don't have access to that.
  defp is_valid_url?(url) do
    case URI.parse(url) do
      %URI{scheme: nil, host: nil} ->
        {:error, %RSS.Error{reason: "URL should begin with http/s, received: #{url}", id: url}}
      %URI{host: ""} ->
        {:error, %RSS.Error{reason: "URL is missing a host, received: #{url}", id: url}}
      %URI{path: nil} ->
        {:error, %RSS.Error{reason: "URL requires a path, received: #{url}", id: url}}
      url ->
        {:ok, URI.to_string(url)}
    end
  end

end
