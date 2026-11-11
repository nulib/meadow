defmodule Meadow.TranscriptionBench.Parser do
  @moduledoc """
  Reads a model's output into text and regions, whatever shape a variant asked for.

  Any array of objects that carry a text is a level of regions, named by its key
  (`lines`, `words`); an array nested in a region is a level under it. A region's box is
  read in the order and units the variant states and kept as `[x, y, width, height]` in
  fractions of the image.

  The result is a map with string keys, as it is sent to the dashboard:

      %{
        "text" => "...",
        "regions" => [
          %{"index" => 0, "level" => "lines", "text" => "...", "box" => [x, y, w, h] | nil,
            "rawBox" => term, "parent" => index | nil}
        ],
        "levels" => ["lines", "words"],
        "languages" => ["en"],
        "structured" => true,
        "warnings" => []
      }
  """

  alias Jason.OrderedObject

  @text_keys ~w(text word content transcription value)
  @box_keys ~w(box bbox bounding_box boundingBox box_2d coordinates region quad polygon)
  @whole_text_keys ~w(transcribed_text transcription text)
  @language_keys ~w(detected_languages languages)
  @blank_page "[blank page]"

  @stringified_array "An array arrived as a JSON string."
  @salvaged_array "An array arrived as a string that is not valid JSON; " <>
                    "its regions were recovered by pattern."

  @fenced ~r/```(?:json)?\s*(.*?)```/s
  @item ~r/\{\s*"text"\s*:\s*"(.*?)"\s*,\s*"(?:box|bbox)"\s*:\s*\[([^\]]*)\]\s*\}/s

  @type format :: %{order: String.t(), units: String.t()}
  @type size :: {pos_integer(), pos_integer()} | nil

  @doc """
  Turn what the model returned into a transcription. `size` is the image the model saw,
  which pixel boxes are read against.
  """
  @spec parse(String.t() | nil, format(), size()) :: map()
  def parse(raw, format, size) do
    raw = raw || ""

    case read_json(raw) do
      nil ->
        %{
          "text" => String.trim(raw),
          "regions" => [],
          "levels" => [],
          "languages" => [],
          "structured" => false,
          "warnings" => []
        }

      json ->
        parse_json(json, raw, format, size)
    end
  end

  defp parse_json(json, raw, format, size) do
    state = %{regions: [], levels: [], warnings: [], saw_array: false, format: format, size: size}

    state =
      if is_list(json) do
        Enum.reduce(json, %{state | saw_array: true}, &walk(&1, "regions", nil, &2))
      else
        walk(json, "", nil, state)
      end

    regions = Enum.reverse(state.regions)
    levels = Enum.reverse(state.levels)
    root = if object?(json), do: json, else: OrderedObject.new([])

    %{
      "text" => text_of(regions, levels, root, state.saw_array, raw),
      "regions" => regions,
      "levels" => levels,
      "languages" => languages(root),
      "structured" => true,
      "warnings" => state.warnings |> Enum.reverse() |> Enum.uniq()
    }
  end

  defp text_of([_ | _] = regions, [outermost | _], _root, _saw_array, _raw) do
    regions
    |> Enum.filter(&(&1["level"] == outermost))
    |> Enum.map_join("\n", & &1["text"])
  end

  defp text_of(_regions, _levels, root, saw_array, raw) do
    whole =
      case first_key(root, @whole_text_keys) do
        nil -> nil
        key -> get(root, key)
      end

    cond do
      is_binary(whole) -> String.trim(whole)
      saw_array -> @blank_page
      true -> String.trim(raw)
    end
  end

  defp languages(root) do
    with key when is_binary(key) <- first_key(root, @language_keys),
         {items, _warning} when is_list(items) <- as_array(get(root, key)) do
      Enum.filter(items, &is_binary/1)
    else
      _ -> []
    end
  end

  defp walk(node, level, parent, state) do
    if object?(node) do
      {self, state} = add_region(node, level, parent, state)
      Enum.reduce(node.values, state, &walk_entry(&1, level, self, &2))
    else
      state
    end
  end

  defp walk_entry({key, _value}, _level, _self, state)
       when key in @language_keys or key in @box_keys,
       do: state

  defp walk_entry({key, value}, level, self, state),
    do: walk_value(key, value, level, self, state)

  defp walk_value(key, value, level, self, state) do
    case as_array(value) do
      {items, warning} when is_list(items) ->
        state = if warning, do: %{state | warnings: [warning | state.warnings]}, else: state

        cond do
          Enum.any?(items, &object?/1) ->
            Enum.reduce(items, %{state | saw_array: true}, &walk(&1, key, self, &2))

          items == [] ->
            %{state | saw_array: true}

          true ->
            state
        end

      _ ->
        if object?(value), do: walk(value, level, self, state), else: state
    end
  end

  # A node of a level that carries a text is a region; its index is the parent of
  # whatever is nested in it.
  defp add_region(_node, "", parent, state), do: {parent, state}

  defp add_region(node, level, parent, state) do
    with key when is_binary(key) <- first_key(node, @text_keys),
         value when is_binary(value) <- get(node, key),
         text when text != "" <- collapse(value) do
      raw_box =
        case first_key(node, @box_keys) do
          nil -> nil
          box_key -> get(node, box_key)
        end

      index = length(state.regions)

      region = %{
        "index" => index,
        "level" => level,
        "text" => text,
        "box" => normalize_box(raw_box, state.format, state.size),
        "rawBox" => raw_box,
        "parent" => parent
      }

      levels = if level in state.levels, do: state.levels, else: [level | state.levels]
      {index, %{state | regions: [region | state.regions], levels: levels}}
    else
      _ -> {parent, state}
    end
  end

  @doc """
  JSON from a tool input, a bare JSON answer, or one wrapped in prose or a code fence.
  Objects are `Jason.OrderedObject`s, so levels keep the order the model gave them.
  """
  def read_json(raw) do
    text = String.trim(raw || "")

    fenced =
      case Regex.run(@fenced, text) do
        [_, inner] -> [String.trim(inner)]
        _ -> []
      end

    ([text] ++ fenced ++ between(text, "{", "}") ++ between(text, "[", "]"))
    |> Enum.find_value(fn candidate ->
      case decode(candidate) do
        {:ok, value} when is_list(value) or is_struct(value, OrderedObject) -> value
        _ -> nil
      end
    end)
  end

  defp between(text, open, close) do
    with {start, _} <- :binary.match(text, open),
         [_ | _] = closes <- :binary.matches(text, close),
         {finish, _} when finish > start <- List.last(closes) do
      [binary_part(text, start, finish - start + 1)]
    else
      _ -> []
    end
  end

  defp decode(""), do: :error
  defp decode(text), do: Jason.decode(text, objects: :ordered_objects)

  # Models occasionally send a nested array as a JSON string, and now and then as one
  # that is not valid JSON (unescaped quotes in a text, or cut off).
  defp as_array(value) when is_list(value), do: {value, nil}

  defp as_array(value) when is_binary(value) do
    if value |> String.trim_leading() |> String.starts_with?("["), do: decode_array(value)
  end

  defp as_array(_), do: nil

  defp decode_array(value) do
    case decode(value) do
      {:ok, decoded} when is_list(decoded) -> {decoded, @stringified_array}
      _ -> salvage_array(value)
    end
  end

  defp salvage_array(value) do
    case salvage(value) do
      [] -> nil
      items -> {items, @salvaged_array}
    end
  end

  defp salvage(value) do
    @item
    |> Regex.scan(value)
    |> Enum.map(fn [_, text, box] ->
      numbers = box |> String.split(",") |> Enum.map(&parse_number/1)
      OrderedObject.new([{"text", unescape(text)}, {"box", numbers}])
    end)
  end

  defp unescape(text) do
    text
    |> String.replace("\\n", "\n")
    |> String.replace("\\\"", "\"")
    |> String.replace("\\\\", "\\")
  end

  defp parse_number(text) do
    case Float.parse(String.trim(text)) do
      {number, ""} -> number
      _ -> nil
    end
  end

  @doc """
  A model's box as `[x, y, width, height]` in fractions of the image, or nil when it is
  unusable. Eight numbers are the four corners of a quadrilateral, read as x, y pairs.
  """
  def normalize_box(box, %{order: order, units: units}, size) do
    with {xs, ys} <- corners(numbers_of(box), order),
         {width, height} <- extents(units, size) do
      clamp = fn value, extent -> (value / extent) |> max(0.0) |> min(1.0) end
      {x0, x1} = xs |> Enum.map(&clamp.(&1, width)) |> Enum.min_max()
      {y0, y1} = ys |> Enum.map(&clamp.(&1, height)) |> Enum.min_max()

      if x1 > x0 and y1 > y0,
        do: Enum.map([x0, y0, x1 - x0, y1 - y0], &Float.round(&1, 5)),
        else: nil
    else
      _ -> nil
    end
  end

  defp extents("frac", _size), do: {1, 1}
  defp extents("1000", _size), do: {1000, 1000}

  defp extents(_px, {width, height})
       when is_number(width) and is_number(height) and width > 0 and height > 0,
       do: {width, height}

  defp extents(_units, _size), do: nil

  defp corners({:corners, x0, y0, x1, y1}, _order), do: {[x0, x1], [y0, y1]}
  defp corners([a, b, c, d], "xywh"), do: {[a, a + c], [b, b + d]}
  defp corners([a, b, c, d], "yxyx"), do: {[b, d], [a, c]}
  defp corners([a, b, c, d], _xyxy), do: {[a, c], [b, d]}

  defp corners([_, _, _, _, _, _, _, _] = numbers, order) do
    xs = Enum.take_every(numbers, 2)
    ys = numbers |> Enum.drop(1) |> Enum.take_every(2)
    if order == "yxyx", do: {ys, xs}, else: {xs, ys}
  end

  defp corners(_numbers, _order), do: nil

  defp numbers_of(box) when is_list(box) do
    flat = List.flatten(box)
    if Enum.all?(flat, &is_number/1), do: flat, else: nil
  end

  defp numbers_of(%OrderedObject{} = box) do
    pick = fn keys -> Enum.find_value(keys, &number(get(box, &1))) end
    x0 = pick.(~w(x_min xmin x0 left x))
    y0 = pick.(~w(y_min ymin y0 top y))
    x1 = pick.(~w(x_max xmax x1 right))
    y1 = pick.(~w(y_max ymax y1 bottom))
    width = pick.(~w(width w))
    height = pick.(~w(height h))

    cond do
      is_nil(x0) or is_nil(y0) -> nil
      x1 && y1 -> {:corners, x0, y0, x1, y1}
      width && height -> {:corners, x0, y0, x0 + width, y0 + height}
      true -> nil
    end
  end

  defp numbers_of(_), do: nil

  defp number(value) when is_number(value), do: value
  defp number(_), do: nil

  defp object?(value), do: is_struct(value, OrderedObject)

  defp get(%OrderedObject{values: values}, key) do
    case List.keyfind(values, key, 0) do
      {_, value} -> value
      nil -> nil
    end
  end

  defp first_key(%OrderedObject{values: values}, keys),
    do: Enum.find(keys, &List.keymember?(values, &1, 0))

  defp collapse(text), do: text |> String.split() |> Enum.join(" ")
end
