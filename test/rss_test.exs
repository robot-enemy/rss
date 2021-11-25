defmodule RSSTest do
  @moduledoc false
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mox

  @bbc_data "test/data/bbc-world-news.xml" |> Path.expand() |> File.read!()

  setup :verify_on_exit!

  describe "fetch/1" do

    test "return data from given URL" do
      url = "https://www.bbc.com/feed"

      expect(HTTPClient.Mock, :get, fn ^url, _headers, _opts ->
        {:ok, %{body: @bbc_data, headers: [], status: 200}}
      end)

      assert {:ok, feed_data} = RSS.fetch(url)
      assert %{
        title: "BBC News - World",
        summary: "BBC News - World",
        link: "https://www.bbc.co.uk/news/",
        image: "https://news.bbcimg.co.uk/nol/shared/img/bbc_news_120x60.gif",
        language: "en-gb",
        entries: entries,
      } = feed_data
      assert Enum.count(entries) == 30
      assert %{
        title: "Coronavirus delays Russian vote on Putin staying in power",
        summary: "A public ballot on constitutional change is postponed because of coronavirus concerns.",
        link: "https://www.bbc.co.uk/news/world-europe-52038814",
        id: "https://www.bbc.co.uk/news/world-europe-52038814",
        published_at: nil,
      } = List.first(entries)
    end

    test "returns error when url does not exist" do
      url = "https://www.siteisdown.com/404"
      error_reason = "Page not found (404)"

      expect(HTTPClient.Mock, :get, fn ^url, _headers, _opts ->
        {:ok, %{body: nil, headers: [], status: 404}}
      end)

      assert capture_log(fn ->
        assert {:error, %RSS.Error{id: ^url, reason: ^error_reason}} = RSS.fetch(url)
      end) =~ error_reason
    end

    test "returns error when there's an unknown problem with the http" do
      url = "https://www.siteisdown.com/500"
      error_reason = "Something died"

      expect(HTTPClient.Mock, :get, fn ^url, _headers, _opts ->
        {:error, %{reason: error_reason}}
      end)

      assert capture_log(fn ->
        assert {:error, %RSS.Error{id: ^url, reason: ^error_reason}} = RSS.fetch(url)
      end) =~ error_reason
    end

    test "returns error when url has no scheme" do
      url = "unknown.com"
      error_reason = "URL should begin with http/s, received: #{url}"

      assert capture_log(fn ->
        assert {
          :error,
          %RSS.Error{id: ^url, reason: ^error_reason}
        } = RSS.fetch(url)
      end) =~ error_reason
    end

    test "returns error when url has no host" do
      url = "https://"
      error_reason = "URL is missing a host, received: #{url}"

      assert capture_log(fn ->
        assert {
          :error,
          %RSS.Error{id: ^url, reason: ^error_reason}
        } = RSS.fetch(url)
      end) =~ error_reason
    end

    test "returns error when url has no path" do
      url = "https://www.example.com"
      error_reason = "URL requires a path, received: #{url}"

      assert capture_log(fn ->
        assert {
          :error,
          %RSS.Error{id: ^url, reason: ^error_reason}
        } = RSS.fetch(url)
      end) =~ error_reason
    end

    # TODO:
    #   find a badly formatted RSS feed.  At some point I updated the reddit rss
    #   and now it correctly parses the feed.

    # test "returns error when rss data is badly formatted and can't be read" do
    #   url = "https://www.reddit.com/r/movies.rss"
    #   error_reason = "RSS.Data.parse/1: Unable to parse RSS - (InvalidStartTag)"
    #   badly_formatted_data =
    #     "test/data/bad-formatting.xml"
    #     |> Path.expand()
    #     |> File.read!()

    #   expect(HTTPClient.Mock, :get, fn ^url, _headers, _opts ->
    #     {:ok, %{body: badly_formatted_data, headers: [], status: 200}}
    #   end)

    #   assert capture_log(fn ->
    #     assert {:error, %RSS.Error{reason: ^error_reason}} = RSS.fetch(url)
    #   end) =~ error_reason
    # end

    test "returns error if no data is given to the parse" do
      url = "https://nothing.com/feed"
      error_reason = "RSS.Data.parse/1 expected data as a binary"

      expect(HTTPClient.Mock, :get, fn ^url, _headers, _opts ->
        {:ok, %{body: nil, headers: [], status: 200}}
      end)

      assert capture_log(fn ->
        assert {:error, %RSS.Error{reason: ^error_reason}} = RSS.fetch(url)
      end) =~ error_reason
    end

    test "test" do
      # path = Path.join(File.cwd!, "test/data/bbc-world-news.xml")
      path = Path.join(File.cwd!, "test/data/variety.xml")

      RSS.Parser.parse(path)
    end

  end

end
