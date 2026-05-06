defmodule LocalAuthority do
  @moduledoc """
  Authoritex module for querying local (or locally cached) authority records
  """

  defmacro __using__(use_opts) do
    quote bind_quoted: [
            code: use_opts[:code],
            uri_prefix: use_opts[:uri_prefix],
            description: use_opts[:description]
          ] do
      alias LocalAuthority.Terms
      @behaviour Authoritex

      @impl Authoritex
      def can_resolve?(unquote(uri_prefix) <> _id), do: true
      def can_resolve?(_), do: false

      @impl Authoritex
      def code, do: unquote(code)

      @impl Authoritex
      def description, do: unquote(description)

      @impl Authoritex
      def fetch(id) do
        case Terms.get_term(id) do
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
               hint: record.hint,
               qualified_label: record.qualified_label,
               variants: record.variants
             }}
        end
      end

      @impl Authoritex
      def search(query, max_results \\ 20) do
        {:ok,
         Terms.search_terms(unquote(code), query, max_results)
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

  @doc """
  Create a local authority that can be inserted into Authoritex's configured
  list of authorities. Takes a name, code, uri_prefix, and description. Name can
  be an atom or string.
  """
  def create(name, code, uri_prefix, description) when is_atom(name) do
    mod_name = Module.concat([__MODULE__, name])

    {:module, mod, _, _} =
      Module.create(
        mod_name,
        quote do
          @desc unquote(description)
          @moduledoc "Authoritex implementation for the #{@desc}"

          use LocalAuthority,
            code: unquote(code),
            uri_prefix: unquote(uri_prefix),
            description: @desc
        end,
        Macro.Env.location(__ENV__)
      )

    mod
  end

  def create(name, code, uri_prefix, description),
    do: create(Macro.camelize(name), code, uri_prefix, description)
end
