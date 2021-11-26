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

  end

  describe "parse/1" do

    test "correctly returns the feed data" do
      path = Path.join(File.cwd!, "test/data/variety.xml")

      assert {:ok, result} = RSS.parse(path)
      assert rss = result["rss"]
      assert channel = rss["channel"]
      assert channel["title"] == "Variety"
      assert channel["description"] |> is_nil()
      assert channel["lastBuildDate"] == "Wed, 24 Nov 2021 10:59:28 +0000"
      assert channel["language"] == "en-US"
      assert channel["sy"]["updatePeriod"] == "hourly"
      assert channel["sy"]["updateFrequency"] == "1"
      assert channel["generator"] == "https://wordpress.org/?v=5.8.2"

      assert image = channel["image"]
      assert image["height"] == "32"
      assert image["link"] == "https://variety.com"
      assert image["title"] == "Variety"
      assert image["width"] == "32"
      assert image["url"] == "https://variety.com/wp-content/uploads/2018/06/variety-favicon.png?w=32"

      assert [%{"item" => first_item}|items] = channel["items"]

      assert first_item["title"] == "‘The Great British Bake-Off’ Final Nabs Sizeable Slice of Audience Share With 6.9 Million Viewers"
      assert first_item["link"] == "https://variety.com/2021/tv/news/the-great-british-bake-off-final-2021-ratings-1235118941/"
      assert first_item["comments"] == "https://variety.com/2021/tv/news/the-great-british-bake-off-final-2021-ratings-1235118941/#respond"
      assert first_item["dc"]["creator"] == "K.J. Yossman"
      assert first_item["pubDate"] == "Wed, 24 Nov 2021 10:09:31 +0000"
      assert first_item["guid"] == "https://variety.com/?p=1235118941"
      assert first_item["description"] =~ "SPOILER WARNING: Do not read this story unless you"

      assert first_item_media = first_item["media"]
      assert first_item_media["thumbnail"] == "https://variety.com/wp-content/uploads/2021/11/Bake-Off.jpeg"
      assert first_item_media["content"] == "https://variety.com/wp-content/uploads/2021/11/Bake-Off.jpeg"
      assert first_item_media["title"] == "Bake-Off"
  %{
    "channel" => %{

      "items" => [
        %{
          "categories" => [
            "Global",
            "News",
            "Dracula",
            "Hammer Films",
            "Let Me In",
            "The Woman In Black"
          ],

          "wfw:commentRss" => "https://variety.com/2021/film/global/dracula-hammer-films-network-distributing-1235117981/feed/",
          "slash:comments" => 0,
          "post-id" => 1235117981,
          "media" => %{
            "thumbnail" => "https://variety.com/wp-content/uploads/2021/11/Lady-in-Black-Dracula.jpg",
            "content" => %{
              "url" => "https://variety.com/wp-content/uploads/2021/11/Lady-in-Black-Dracula.jpg",
              "medium" => "image",
              "title" => "Lady-in-Black-Dracula",
            },
          },
        }
      ]
    }
  }
    end
  end

end
