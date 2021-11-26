defmodule RSS.Parser do
  @moduledoc """
  This was a quick attempt to create an parser, but ultimately reverted to a
  third party library.

  I'm leaving it here in case I ever need to come back to it.

  Things that it needs: a Tree module that would traverse the nodes, there's
  potential errors here where returning the wrong nodes could mess up the tree;
  dealing with categories; general cleanup.
  """

  def parse(path) do
    initial_state = {{}, nil}
    opts = [
      event_state: initial_state,
      event_fun: &RSS.Parser.event/3,
    ]

    case :xmerl_sax_parser.file(path, opts) do
      {:ok, {_initial_state, state}, _} -> {:ok, state}
      error -> error
    end
  end

  defp extract_attr(html_attrs, key) do
    {_, _, _name, value} = Enum.find(html_attrs, fn {_, _, name, _} -> name == key end)
    to_string(value)
  end

  defp find_item_node({stack, %{"item" => _} = node}), do: {stack, node}
  defp find_item_node({nil, _node}), do: nil
  defp find_item_node({stack, _node}), do: find_item_node(stack)

  defp get_tag(node), do: node |> Map.keys() |> List.first()

  defp tag_name({prefix, tag}) when prefix == [], do: to_string(tag)
  defp tag_name({prefix, tag}), do: Enum.join([prefix, tag], ":")

  ################
  #              #
  # startElement #
  #              #
  ################

  def event(
    {:startElement, _meta_terms, _tag, {'media', 'content'}, html_attrs},
    {_path, _file, _line_num},
    stack
  ) do
    {stack, %{"content" => extract_attr(html_attrs, 'url')}}
  end

  def event(
    {:startElement, _meta_terms, _tag, {'media', 'thumbnail'}, html_attrs},
    {_path, _file, _line_num},
    stack
  ) do
    {stack, %{"thumbnail" => extract_attr(html_attrs, 'url')}}
  end

  def event(
    {:startElement, _meta_terms, _tag, {_prefix, tag}, _html_attrs},
    {_path, _file, _line_num},
    stack
  ) do
    {stack, %{to_string(tag) => nil}}
  end

  def event({:characters, text}, _loc, {stack, current_node}) do
    key = get_tag(current_node)
    content = text |> to_string() |> String.trim()

    # Update content of key
    {stack, Map.put(current_node, key, content)}
  end

  ##############
  #            #
  # endElement #
  #            #
  ##############

  #
  # when item closes, add it to the "items" list
  #
  def event({:endElement, _, 'item', _}, _loc, {{stack, parent_node}, current_node}) do
    items = parent_node["channel"]["items"] || []
    items = items ++ [current_node]
    parent_node = put_in(parent_node, ["channel", "items"], items)

    {stack, parent_node}
  end

  # This is a patch for the media element, as they function differently than
  # other elements.
  def event(
    {:endElement, _meta_terms, _tag, {'media', _tag} = el},
    {_path, _file_, _line_num},
    {stack, current_node}
  ) do
    if current_node["item"] do
      {stack, current_node}
    else
      {stack, item_node} = find_item_node({stack, current_node})

      if media = item_node["item"]["media"] do
        {stack, put_in(item_node, ["item", "media"], Map.merge(media, current_node))}
      else
        {stack, put_in(item_node, ["item", "media"], current_node)}
      end
    end
  end

  #
  # If the parent element is nil, we're done.  Return the stack
  #
  def event({:endElement, _, _, _}, _, {{stack, nil}, current_node}) do
    {stack, current_node}
  end

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
