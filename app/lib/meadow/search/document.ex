defprotocol Meadow.Search.Document do
  @moduledoc """
  A protocol for converting a struct into an indexable document.
  ## Example
      defimpl Meadow.SearchIndex.Document, for: MyStruct do
        def encode(struct) do
          %{
            id: struct.id,
            name: struct.name
          }
        end
      end
  """

  @doc """
  Returns a map of fields, which will be converted to JSON and stored in
  the index as a document.
  ## Example
      def encode(item, version) do
        %{
          title: item.title,
          author: item.author
        }
      end
  """
  @spec encode(any, integer) :: map
  def encode(item, version)
end
