defmodule Meadow.Embeddings.ImageInput do
  @moduledoc """
  Turns an image into the inputs EmbeddingGemma's vision encoder expects.

  This mirrors the model's own image processor, pixel for pixel: the image is
  converted to RGB, resized (ignoring small aspect ratio changes) so that both sides are
  multiples of `patch_size * pooling_kernel_size` and the patch count fits
  the soft token budget, scaled to `0..1`, and cut into `patch_size` square
  patches in row-major order. Every `pooling_kernel_size` squared patches
  become one soft token in the text model's input.
  """

  alias Vix.Vips.Image, as: Vimage
  alias Vix.Vips.{Interpolate, Operation}

  @patch_size 16
  @pooling_kernel_size 3
  @channels 3
  @side_multiple @patch_size * @pooling_kernel_size

  defstruct [:pixel_values, :position_ids, :soft_tokens, :height, :width]

  @type t :: %__MODULE__{
          pixel_values: Nx.Tensor.t(),
          position_ids: Nx.Tensor.t(),
          soft_tokens: pos_integer(),
          height: pos_integer(),
          width: pos_integer()
        }

  @doc "The number of patches the vision encoder takes for a soft token budget"
  def max_patches(max_soft_tokens), do: max_soft_tokens * @pooling_kernel_size ** 2

  @doc """
  The `{height, width}` the model resizes an image of the given size to.

      iex> Meadow.Embeddings.ImageInput.target_size(1024, 1024, 280)
      {768, 768}

      iex> Meadow.Embeddings.ImageInput.target_size(3000, 600, 280)
      {1776, 336}
  """
  @spec target_size(pos_integer(), pos_integer(), pos_integer()) ::
          {pos_integer(), pos_integer()}
  def target_size(height, width, max_soft_tokens) do
    factor = :math.sqrt(max_patches(max_soft_tokens) * @patch_size ** 2 / (height * width))
    max_side = max_soft_tokens * @side_multiple

    case {round_down(factor * height), round_down(factor * width)} do
      {0, 0} -> {@side_multiple, @side_multiple}
      {0, _} -> {@side_multiple, min(div(width, height) * @side_multiple, max_side)}
      {_, 0} -> {min(div(height, width) * @side_multiple, max_side), @side_multiple}
      size -> size
    end
  end

  defp round_down(side), do: floor(side / @side_multiple) * @side_multiple

  @doc """
  Prepare an encoded image (JPEG, PNG, TIFF, ...) for the vision encoder.

  The image is only resized when it is not already at the model's target
  size, so an image requested from the IIIF server at `target_size/3` is
  used as delivered.
  """
  @spec prepare(binary(), pos_integer()) :: {:ok, t()} | {:error, term()}
  def prepare(image_binary, max_soft_tokens) when is_binary(image_binary) do
    with {:ok, image} <- Image.from_binary(image_binary),
         {:ok, image} <- to_rgb(image),
         {height, width} = target_size(Image.height(image), Image.width(image), max_soft_tokens),
         {:ok, image} <- resize(image, height, width),
         {:ok, pixels} <- Vimage.write_to_binary(image) do
      {:ok, patchify(pixels, height, width, max_patches(max_soft_tokens))}
    end
  end

  # Decoding follows the model's reference JavaScript processor (sharp), so
  # the same file gives the same pixels, and so the same embedding, in both:
  # apply the EXIF orientation, convert an embedded ICC profile to sRGB, and
  # drop (rather than flatten) any alpha channel.
  defp to_rgb(image) do
    with {:ok, {image, _flags}} <- Image.autorotate(image),
         image = apply_icc_profile(image),
         {:ok, image} <- Image.to_colorspace(image, :srgb),
         {:ok, image} <- first_bands(image) do
      Operation.cast(image, :VIPS_FORMAT_UCHAR)
    end
  end

  defp apply_icc_profile(image) do
    with {:ok, _profile} <- Vimage.header_value(image, "icc-profile-data"),
         {:ok, converted} <-
           Operation.icc_transform(image, "srgb",
             embedded: true,
             intent: :VIPS_INTENT_PERCEPTUAL,
             depth: 8
           ) do
      converted
    else
      _ -> image
    end
  end

  defp first_bands(image) do
    if Image.bands(image) == @channels,
      do: {:ok, image},
      else: Operation.extract_band(image, 0, n: @channels)
  end

  # The reference processor resizes with a bicubic affine transform, which
  # samples the source directly instead of averaging it down first. Images
  # normally arrive from the IIIF server already at the target size, so this
  # only runs for images smaller than the target and for local files.
  defp resize(image, height, width) do
    case {Image.height(image), Image.width(image)} do
      {^height, ^width} ->
        {:ok, image}

      {source_height, source_width} ->
        with {:ok, bicubic} <- Interpolate.new("bicubic"),
             {:ok, resized} <-
               Operation.affine(
                 image,
                 [width / source_width, 0.0, 0.0, height / source_height],
                 interpolate: bicubic
               ),
             {:ok, resized} <- Operation.cast(resized, :VIPS_FORMAT_UCHAR) do
          fit(resized, height, width)
        end
    end
  end

  # Rounding inside libvips can leave the result a pixel off
  defp fit(image, height, width) do
    if {Image.height(image), Image.width(image)} == {height, width},
      do: {:ok, image},
      else: Operation.embed(image, 0, 0, width, height, extend: :VIPS_EXTEND_COPY)
  end

  defp patchify(pixels, height, width, max_patches) do
    rows = div(height, @patch_size)
    columns = div(width, @patch_size)
    patches = rows * columns
    padding = max_patches - patches

    pixel_values =
      pixels
      |> Nx.from_binary(:u8, backend: Nx.BinaryBackend)
      |> Nx.reshape({rows, @patch_size, columns, @patch_size, @channels})
      |> Nx.transpose(axes: [0, 2, 1, 3, 4])
      |> Nx.reshape({patches, @patch_size * @patch_size * @channels})
      |> Nx.as_type(:f32)
      |> Nx.divide(255)
      |> Nx.pad(0.0, [{0, padding, 0}, {0, 0, 0}])
      |> Nx.new_axis(0)

    # {column, row} of every patch; padding patches are marked with -1
    position_ids =
      for(row <- 0..(rows - 1), column <- 0..(columns - 1), do: [column, row])
      |> Nx.tensor(type: :s64, backend: Nx.BinaryBackend)
      |> Nx.pad(-1, [{0, padding, 0}, {0, 0, 0}])
      |> Nx.new_axis(0)

    %__MODULE__{
      pixel_values: pixel_values,
      position_ids: position_ids,
      soft_tokens: div(patches, @pooling_kernel_size ** 2),
      height: height,
      width: width
    }
  end
end
