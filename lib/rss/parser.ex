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

  defmodule CurrentNode do
    defstruct [id: nil]
  end
  defmodule TreeNode do
    defstruct [content: nil, id: nil, parent: nil, tag: nil]

    def fetch(map, key) do
      :maps.find(key, map)
    end
  end

  def parse(path) do
    # channel = %{"items" => [], "meta" => []}
    # current_node = nil

    opts = [
      event_state: {[], nil},
      event_fun: &RSS.Parser.event/3,
    ]

    {:ok, {result, _}, _} = :xmerl_sax_parser.file(path, opts)

    Enum.group_by(result, fn node -> node.parent end)
    |> IO.inspect()
  end

  # def event(:startDocument, _, state) do
  #   IO.puts "Begin"
  #   state
  # end

  defp find_node_by(stack, key, value) do
    Enum.find(stack, fn node -> node[key] == value end)
  end

  defp pop_node_from_stack(stack, id) do
    index = Enum.find_index(stack, fn node -> node.id == id end)
    List.pop_at(stack, index)
  end

  #
  # Item
  #

  def event({:startElement, _, 'item', _, _}, {_path, file, line_num}, {stack, active_node}) do
    {items_node, stack} =
      case find_node_by(stack, :tag, "items") do
        nil ->
          node = %TreeNode{
            content: [],
            id: "items@#{file}:#{line_num}",
            parent: active_node,
            tag: "items",
          }
          {node, stack ++ [node]}
        items_node ->
          {items_node, stack}
      end

    node_id = "item@#{file}:#{line_num}"
    node = %TreeNode{
      id: node_id,
      content: nil,
      parent: items_node[:id],
      tag: "item",
    }
    {stack ++ [node], node_id}
  end

  def event({:endElement, _, 'item', _}, _loc, {stack, active_node}) do
    items_node = find_node_by(stack, :tag, "items")
    {stack, items_node[:parent]}
  end

  #
  # General
  #

  def event({:startElement, _, tag, {prefix, tag}, _}, {_path, file, line_num}, {stack, active_node}) do
    tag = if (prefix == []), do: to_string(tag), else: Enum.join([prefix, tag], ":")
    id = "#{tag}@#{file}:#{line_num}"
    node = %TreeNode{
      id: id,
      content: nil,
      parent: active_node,
      tag: tag,
    }
    {stack ++ [node], id}
  end

  def event({:characters, text}, _loc, {stack, active_node}) do
    {node, stack} = pop_node_from_stack(stack, active_node)
    content = to_string(text) |> String.trim()
    node = Map.put(node, :content, content)

    {stack ++ [node], active_node}
  end

  def event({:endElement, _, tag, _}, _loc, {stack, active_node}) do
    node = Enum.find(stack, fn node -> node.id == active_node end)
    {stack, node.parent}
  end

  # def event({:startElement, _, tag, {prefix, tag}, _}, _, {channel, current_node} = _state)
  # when prefix != [] do
  #   IO.inspect node = %{"#{prefix}:#{tag}": nil}
  #   {channel, node}
  # end
  # def event({:characters, text}, v1, {channel, current_node} = _state) do
  #   IO.inspect v1, label: "V1"
  #   {channel, Map.put(current_node, :d, text)}
  # end

  # def event({:startElement, _v1, _tag, _v2, _v3}, _, state) do
  #   # IO.inspect [v1, tag, v2, v3], label: "START ELEMENT"
  #   # node = %TreeNode{
  #   #   content: nil,
  #   #   id: 1,
  #   #   parent: current_node[:id],
  #   #   tag: to_string(tag)
  #   # }
  #   state
  # end

  # def event({:processingInstruction, tag, params}, _, {acc, current}) do
  #   params =
  #     Regex.scan(~r/(\w+)=\"(\S+)\"/, to_string(params))
  #     |> Enum.reduce(%{}, fn [_, key, value], acc -> Map.put(acc, key, value) end)

  #   {Map.put(acc, to_string(tag), params), current}
  # end
  # def event({:startPrefixMapping, key, value}, _, {acc, current}) do
  #   xmlns = Map.put(acc["xmlns"] || %{}, key, value)
  #   {Map.put(acc, "xmlns", xmlns), current}
  # end

  # def event({:startElement, _, 'item', _, _}, _, {acc, current}) do
  #   {acc, %{'item' => %{}}}
  # end

  # def event({:startElement, _, tag, _, _}, _, {acc, %{'item' => item}}) do
  #   {acc, %{'current_tag' => tag, 'item' => Map.put(item, tag, nil)}}
  # end

  # def event({:characters, text}, _, {acc, %{'current_tag' => tag, 'item' => item}}) do
  #   {acc, %{'item' => Map.put(item, tag, text)}}
  # end

  # def event({:endElement, _, tag, _}, _, {acc, %{'current_tag' => tag, 'item' => item}}) do
  #   {acc, %{'current_tag' => nil, 'item' => item}}
  # end

  # def event({:endElement, _, 'item', _}, _, {acc, %{'item' => item}}) do
  #   items = [item | acc["items"]]
  #   {Map.put(acc, "items", items), %{}}
  # end

  # def event({:startElement, _, tag, _, _}, _, {acc, _current}) do
  #   {acc, %{"key" => tag}}
  # end
  # def event({:characters, text}, _, {acc, current}) do
  #   {acc, Map.put(current, "value", text)}
  # end
  # def event({:endElement, _, tag, _}, _, {acc, current}) do
  #   key = current["key"]
  #   value = current["value"]

  #   if key && value do
  #     {Map.put(acc, to_string(key), to_string(value)), %{}}
  #   else
  #     {acc, current}
  #   end
  # end

  # def event(:endDocument, _, {acc, _current}) do
  #   IO.inspect acc
  # end

  def event({:ignorableWhitespace, _whitespace}, _, acc), do: acc
  # def event(:startCDATA, _, acc), do: acc
  # def event(:endCDATA, _, acc), do: acc

  def event(identifier, {_path, _file, _line_number}, {acc, current}) do
    # IO.inspect identifier
    {acc, current}
  end
end
