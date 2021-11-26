defmodule RSS.Parser do
  @moduledoc false

  def parse(path) do
    initial_state = {{}, nil}
    opts = [
      event_state: initial_state,
      event_fun: &RSS.Parser.event/3,
    ]

    case :xmerl_sax_parser.file(path, opts) do
      {:ok, {_initial_state, state}, _} -> {:ok, state} |> IO.inspect()
      error -> error
    end
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
  # when item closes, add it to the "items" list
  #
  def event({:endElement, _, 'item', _}, _loc, {{stack, parent_node}, current_node}) do
    items = parent_node["channel"]["items"] || []
    items = items ++ [current_node]
    parent_node = put_in(parent_node, ["channel", "items"], items)

    {stack, parent_node}
  end

  #
  # Item Media
  #

  # defp extract_attr(html_attrs, key) do
  #   {_, _, _name, value} = Enum.find(html_attrs, fn {_, _, name, _} -> name == key end)
  #   to_string(value)
  # end

  # def event(
  #   {:startElement, _meta_terms, _tag, {'media', 'thumbnail'}, html_attrs},
  #   {_path, _file, _line_num},
  #   stack
  # ) do
  #   if get_tag(current_node) == "media" do
  #     {stack, Map.mergecurrent_node}, %{"thumbnail" => extract_attr(html_attrs, 'url')}}
  #   else
  #     {{stack, current_node}, %{"media"}}
  # end

  #
  # General
  #

  def event(
    {:startElement, _meta_terms, _tag, {_prefix, tag}, _html_attrs},
    {_path, _file, _line_num},
    stack
  ) do
    # tag = tag_name(tag_with_prefix)

    {stack, %{to_string(tag) => nil}}
  end

  def event({:characters, text}, _loc, {stack, current_node}) do
    key = get_tag(current_node)
    content = text |> to_string() |> String.trim()

    # Update content of key
    {stack, Map.put(current_node, key, content)}
  end

  #
  # If the parent element is nil, we're done.  Return the stack
  #
  def event({:endElement, _, _, _}, _, {{stack, nil}, current_node}) do
    {stack, current_node}
  end

  ##############
  #            #
  # endElement #
  #            #
  ##############

  def event(
    {:endElement, _meta_terms, _tag, {[], _tag}},
    {_path, _file, _line_num},
    {{stack, parent_node}, current_node}
  ) do
    parent_tag = get_tag(parent_node)
    parent_content = (parent_node[parent_tag] || %{}) |> Map.merge(current_node)
    parent_node = Map.put(parent_node, parent_tag, parent_content)

    {stack, parent_node}
  end

  # This is a patch for the media element, as they function differently than
  # other elements.
  def event(
    {:endElement, _meta_terms, _tag, {'media', _tag} = el},
    {_path, _file_, _line_num},
    {{{stack, grandparent_node}, parent_node}, current_node}
  ) do
    cond do
      current_node["media"] ->
        # We're currently in the "item", so just return the stack
        {{{stack, grandparent_node}, parent_node}, current_node}
      media = parent_node["media"] ->
        # The parent node is the "item", so update the "media" value
        media = Map.merge(media, current_node)
        {{stack, grandparent_node}, Map.put(parent_node, "media", media)}
      media = grandparent_node["media"] ->
        # We're two media deep, the "item" is the grandparent, so we want to
        # merge up
        media = Map.merge(media, current_node)
        {stack, Map.put(grandparent_node, "media", media)}
      true ->
        # Else we merge a new "media" into the parent
        {{stack, grandparent_node}, Map.put(parent_node, "media", current_node)}
    end
  end

  def event(
    {:endElement, _meta_terms, _tag, {prefix, tag}},
    {_path, _file, _line_num},
    {{stack, parent_node}, current_node}
  ) when prefix != [] do
    parent_tag = get_tag(parent_node)
    prefix = to_string(prefix)
    tag = to_string(tag)
    parent_node =
      if existing_node = parent_node[parent_tag][prefix] do
        put_in(parent_node, [parent_tag, prefix], Map.merge(existing_node, current_node))
      else
        put_in(parent_node, [parent_tag, prefix], current_node)
      end

    {stack, parent_node}
  end



  def event(:endDocument, _, stack), do: stack

  # def event({:ignorableWhitespace, _whitespace}, _, stack), do: stack
  # def event(:startCDATA, _, stack), do: stack
  # def event(:endCDATA, _, stack), do: stack
  def event(_identifier, {_path, _file, _line_number}, stack), do: stack

end
