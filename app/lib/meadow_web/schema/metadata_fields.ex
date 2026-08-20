defmodule MeadowWeb.Schema.MetadataFields do
  @moduledoc """
  Generate Absinthe `field` declarations from a metadata schema's declared
  fields (see `Meadow.Data.Schemas.MetadataSchema`), so the GraphQL objects
  stop repeating the field list by hand:

      import MeadowWeb.Schema.MetadataFields

      object :uncontrolled_descriptive_fields do
        metadata_fields(WorkDescriptiveMetadata, :values, list_of(:string),
          except: [:citation],
          deprecate: [publisher: "Publisher field is deprecated"]
        )

        metadata_fields(WorkDescriptiveMetadata, :string, :string)
      end

  The GraphQL type is always supplied by the caller, so a kind is not tied to
  one type: the same `:values` fields are `list_of(:string)` on both the output
  object and the input object, and `:coded` fields are `:coded_term` on output
  and `:coded_term_input` on input. Any kind
  `Meadow.Data.Schemas.MetadataSchema` declares works here (`:string`,
  `:coded`, `:values`, `:dates`, `:places`, `:controlled`, `:entries`); the
  kinds with only one field apiece (`:dates`, `:places`) and the `:entries`
  fields, whose types differ per field, are still declared by hand.

  Options:
    * `:except` - fields of that kind to leave out
    * `:deprecate` - `[field: reason]` deprecations to attach

  A deprecation attached here also reaches any input object that pulls the
  object in with `import_fields/1`, and Absinthe's introspection omits
  deprecated input fields, so a deprecated field disappears from the published
  input schema (it is still accepted at runtime).
  """

  @doc "Declare one Absinthe field of `type` for every `kind` field of `schema`"
  defmacro metadata_fields(schema, kind, type, opts \\ []) do
    schema = Macro.expand(schema, __CALLER__)
    except = Keyword.get(opts, :except, [])
    deprecations = Keyword.get(opts, :deprecate, [])

    for name <- schema.__metadata__(:fields, kind) -- except do
      case Keyword.get(deprecations, name) do
        nil ->
          quote do
            field(unquote(name), unquote(type))
          end

        reason ->
          quote do
            field(unquote(name), unquote(type)) do
              deprecate(unquote(reason))
            end
          end
      end
    end
  end
end
