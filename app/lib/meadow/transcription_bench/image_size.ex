defmodule Meadow.TranscriptionBench.ImageSize do
  @moduledoc """
  The size Claude processes an image at, which is the space its pixel coordinates are in.

  Claude resizes an image that exceeds its model's limits before reading it: neither
  side over a maximum edge, and no more than a number of 28 pixel patches (visual
  tokens). A coordinate it returns is a pixel of that resized image, not of the image
  sent. See https://platform.claude.com/docs/en/build-with-claude/vision-coordinates,
  whose reference implementation `resized/3` follows.

  Two tiers of limits exist: `:high` for Claude 4.7 and later models (2576 px, 4784
  tokens) and `:standard` for all others (1568 px, 1568 tokens).
  """

  @patch 28
  @limits %{standard: {1568, 1568}, high: {2576, 4784}}

  @type size :: {pos_integer(), pos_integer()}
  @type tier :: :standard | :high

  @doc """
  The tier a variant reads a model's images at: the variant's `imageTier` ("standard" or
  "high") when it sets one, and otherwise the model's own.
  """
  @spec tier(String.t(), map()) :: tier()
  def tier(_model, %{"imageTier" => "standard"}), do: :standard
  def tier(_model, %{"imageTier" => "high"}), do: :high
  def tier(model, _variant), do: tier(model)

  @doc """
  The tier of a model id: high for Claude 4.7 and later, standard before that and for
  an id that cannot be read.
  """
  @spec tier(String.t()) :: tier()
  def tier(model) do
    case Regex.run(~r/claude-[a-z]+-(\d+)(?:-(\d)(?!\d))?/, model) do
      [_, major, minor] -> version_tier(String.to_integer(major), String.to_integer(minor))
      [_, major] -> version_tier(String.to_integer(major), 0)
      _ -> :standard
    end
  end

  defp version_tier(major, minor) when major > 4 or (major == 4 and minor >= 7), do: :high
  defp version_tier(_major, _minor), do: :standard

  @doc "Visual tokens an image costs: one for each 28 x 28 pixel patch."
  @spec tokens(size()) :: pos_integer()
  def tokens({width, height}), do: ceil(width / @patch) * ceil(height / @patch)

  @doc """
  The size Claude resizes an image to (before it pads it): the largest size of the same
  aspect ratio within the tier's limits. An image that already fits is returned as is.
  """
  @spec resized(size(), tier()) :: size()
  def resized({width, height} = size, tier) do
    limits = Map.fetch!(@limits, tier)

    cond do
      fits?(size, limits) ->
        size

      height > width ->
        {resized_height, resized_width} = resized({height, width}, tier)
        {resized_width, resized_height}

      true ->
        aspect = width / height
        long = search(1, width, aspect, limits)
        {long, short_edge(long, aspect)}
    end
  end

  defp fits?({width, height} = size, {max_edge, max_tokens}) do
    ceil(width / @patch) * @patch <= max_edge and ceil(height / @patch) * @patch <= max_edge and
      tokens(size) <= max_tokens
  end

  # Binary search along the long edge: `low` always fits, `high` never does.
  defp search(low, high, _aspect, _limits) when low + 1 >= high, do: low

  defp search(low, high, aspect, limits) do
    middle = div(low + high, 2)

    if fits?({middle, short_edge(middle, aspect)}, limits),
      do: search(middle, high, aspect, limits),
      else: search(low, middle, aspect, limits)
  end

  defp short_edge(long, aspect), do: max(round_half_even(long / aspect), 1)

  # The API rounds a tie to the even number, which round/1 does not.
  defp round_half_even(value) do
    floor = Float.floor(value)

    cond do
      value - floor != 0.5 -> round(value)
      rem(trunc(floor), 2) == 0 -> trunc(floor)
      true -> trunc(floor) + 1
    end
  end
end
