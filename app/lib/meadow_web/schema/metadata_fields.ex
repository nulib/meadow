defmodule MeadowWeb.Schema.MetadataFields do
  @moduledoc """
  Generate Absinthe `field` declarations from a metadata schema's declared
  fields (see `Meadow.Data.Schemas.MetadataSchema`), so the GraphQL objects
  stop repeating the field list by hand:

      import MeadowWeb.Schema.MetadataFields

      object :uncontrolled_descriptive_fields do
        metadata_fields(WorkDescriptiveMetadata, :values, list_of(:metadata_value),
          except: [:citation],
          deprecate: [publisher: "Publisher field is deprecated"]
        )

        metadata_fields(WorkDescriptiveMetadata, :string, :string)
      end

  Options:
    * `:except` - fields of that kind to leave out
    * `:deprecate` - `[field: reason]` deprecations to attach
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
