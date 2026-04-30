defmodule GettyLocal do
  @moduledoc """
  Authoritex module for querying Getty local authority records
  """

  defmacro __using__(use_opts) do
    quote bind_quoted: [
            subauthority: use_opts[:subauthority],
            code: use_opts[:code] || use_opts[:subauthority],
            http_uri: "http://vocab.getty.edu/#{use_opts[:subauthority]}/",
            prefix: "#{use_opts[:subauthority]}:",
            description: use_opts[:description]
          ] do
      alias GettyLocal.GettyTerms
      @behaviour Authoritex

      @impl Authoritex
      def can_resolve?(unquote(http_uri) <> _id), do: true

      def can_resolve?(unquote(prefix) <> _ = id) do
        unquote(prefix) != ":"
      end

      def can_resolve?(_), do: false

      @impl Authoritex
      def code, do: unquote(code)

      @impl Authoritex
      def description, do: unquote(description)

      @impl Authoritex
      def fetch(id) do
        case GettyTerms.get_term(id) do
          nil ->
            {:error, 404}

          record ->
            variants =
              case record.variants do
                nil -> []
                variants -> Enum.take(variants, 10)
              end

            {:ok,
             %Authoritex.Record{
               id: record.uri,
               label: record.qualified_label,
               qualified_label: record.qualified_label,
               variants: record.variants
             }}
        end
      end

      @impl Authoritex
      def search(query, max_results \\ 20) do
        {:ok,
         GettyTerms.search_terms(unquote(subauthority), query, max_results)
         |> Enum.map(fn record ->
           %Authoritex.SearchResult{
             id: record.uri,
             label: record.qualified_label,
             hint: record.hint
           }
         end)}
      end
    end
  end
end

defmodule GettyLocal.AAT do
  @desc "Getty Art & Architecture Thesaurus (AAT)"
  @moduledoc "Authoritex implementation for the #{@desc}"

  use GettyLocal,
    subauthority: "aat",
    description: @desc
end

defmodule GettyLocal.TGN do
  @desc "Getty Thesaurus of Geographic Names (TGN)"
  @moduledoc "Authoritex implementation for the #{@desc}"

  use GettyLocal,
    subauthority: "tgn",
    description: @desc
end

defmodule GettyLocal.ULAN do
  @desc "Getty Union List of Artist Names (ULAN)"
  @moduledoc "Authoritex implementation for the #{@desc}"

  use GettyLocal,
    subauthority: "ulan",
    description: @desc
end
