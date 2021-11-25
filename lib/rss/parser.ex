defmodule RSS.Parser do
  @moduledoc false

  %{
    "channel" => %{
      "title" => "Variety",
      "description" => "",
      "lastBuildDate" => "Tue, 23 Nov 2021 11:12:19 +0000",
      "language" => "en-US",
      "sy:updatePeriod" => "hourly",
      "sy:updateFrequency" => "1",
      "generator" => "https://wordpress.org/?v=5.8.2",
      "image" => %{
        "url" => "https://variety.com/wp-content/uploads/2018/06/variety-favicon.png?w=32",
        "title" => "Variety",
        "link" => "https://variety.com",
        "width" => "32",
        "height" => "32",
      },
      "feedburner:browserFriendly" => "This is an XML content...",
      "items" => [
        %{
          "title" => "‘Dracula’ Producer Hammer Films Teams With Network Distributing to Form Hammer Studios (EXCLUSIVE)",
          "link" => "https://variety.com/2021/film/global/dracula-hammer-films-network-distributing-1235117981/",
          "comments" => "https://variety.com/2021/film/global/dracula-hammer-films-network-distributing-1235117981/#respond",
          "dc:creator" => "Naman Ramachandran",
          "pubDate" => "Tue, 23 Nov 2021 09:00:05 +0000",
          "categories" => [
            "Global",
            "News",
            "Dracula",
            "Hammer Films",
            "Let Me In",
            "The Woman In Black"
          ],
          "guid" => "https://variety.com/?p=1235117981",
          "description" => "The U.K.&amp;#8217;s Network Distributing has sealed...",
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

  def parse(path) do
    initial_state = {{}, nil}
    opts = [
      event_state: initial_state,
      event_fun: &RSS.Parser.event/3,
    ]

    {:ok, {_initial_state, state}, _} = :xmerl_sax_parser.file(path, opts)

    # for key <- ["atom10:link", "description", "feedburner:browserFriendly", "feedburner:info",
    #             "generator", "image", "language", "lastBuildDate", "link", "site",
    #             "sy:updateFrequency", "sy:updatePeriod", "title"] do
    #   IO.inspect %{key => state["rss"]["channel"][key]}
    # end
  end

  # def event(:startDocument, _, state) do
  #   IO.puts "Begin"
  #   state
  # end

  defp get_tag(node), do: node |> Map.keys() |> List.first()

  defp tag_name({prefix, tag}) when prefix == [], do: to_string(tag)
  defp tag_name({prefix, tag}), do: Enum.join([prefix, tag], ":")

  #
  # Item
  #

  def event(
    {:startElement, _, 'item', _tag_with_prefix, _},
    {_path, _file, _line_num},
    {stack, current_node}
  ) do
    if get_tag(current_node) == "items" do
      # The items node already exists, so just put the item node onto the stack
      {{stack, current_node}, %{"item" => nil}}
    else
      # The items node doesn't yet exist, so push an items node first
      {{{stack, current_node}, %{"items" => []}}, %{"item" => nil}}
    end
  end

  def event({:endElement, _, 'item', _}, _loc, {{stack, parent_node}, current_node}) do
    {stack, Map.put(parent_node, "items", parent_node["items"] ++ [current_node])}
  end

  #
  # General
  #

  def event(
    {:startElement, _, _tag, tag_with_prefix, _},
    {_path, _file, _line_num},
    stack
  ) do
    tag = tag_name(tag_with_prefix)
    {stack, %{tag => nil}}
  end

  def event({:characters, text}, _loc, {stack, current_node}) do
    key = get_tag(current_node)
    content = text |> to_string() |> String.trim()

    # Update content of key
    {stack, Map.put(current_node, key, content)}
  end

  def event({:endElement, _, _tag, _}, _loc, {{stack, parent_node}, current_node}) do
    parent_tag = get_tag(parent_node)
    parent_content = (parent_node[parent_tag] || %{}) |> Map.merge(current_node)
    parent_node = Map.put(parent_node, parent_tag, parent_content)

    {stack, parent_node}
  end

  def event(:endDocument, _, stack), do: stack

  def event({:ignorableWhitespace, _whitespace}, _, stack), do: stack
  def event(:startCDATA, _, stack), do: stack
  def event(:endCDATA, _, stack), do: stack
  def event(_identifier, {_path, _file, _line_number}, stack), do: stack

end
