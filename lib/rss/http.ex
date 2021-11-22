defmodule RSS.HTTP do
  @moduledoc """
  Retrieve the RSS feed via HTTP.
  """
  @headers [
    {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"},
    {"accept-language", "en-GB,en-US;q=0.9,en;q=0.8"},
    {"User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36 OPR/67.0.3575.97"}
  ]
  @http_adapter Application.get_env(:rss, :http_adapter, HTTPClient)
  @opts [
    follow_redirect: true,
    max_redirect: 5,
    recv_timeout: 6_000,
    timeout: 10_000,
  ]

  @doc """
  Given a valid URL, returns the associated data.
  """
  @spec get(url :: binary()) ::
          {:ok, binary()} | {:error, atom() | list()}

  def get(url) do
    case @http_adapter.get(url, @headers, @opts) do
      {:ok, %{body: data, status: 200}} -> {:ok, data}
      {:ok, %{status: 403}} -> {:error, %RSS.Error{id: url, reason: "Blocked (403)"}}
      {:ok, %{status: 404}} -> {:error, %RSS.Error{id: url, reason: "Page not found (404)"}}
      {:error, %{reason: reason}} ->
        {:error, %RSS.Error{id: url, reason: reason}}
      {:error, reason} ->
        {:error, %RSS.Error{id: url, reason: reason}}
    end
  end

end
