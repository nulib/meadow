defmodule MeadowWeb.Schema.MetadataFieldsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Meadow.Data.Schemas.{WorkAdministrativeMetadata, WorkDescriptiveMetadata}

  defmodule TestSchema do
    @moduledoc false
    use Absinthe.Schema
    import MeadowWeb.Schema.MetadataFields
    alias Meadow.Data.Schemas.{WorkAdministrativeMetadata, WorkDescriptiveMetadata}

    object :values_with_options do
      metadata_fields(WorkDescriptiveMetadata, :values, list_of(:string),
        except: [:citation, :abstract],
        deprecate: [publisher: "Publisher field is deprecated"]
      )
    end

    object :columns do
      metadata_fields(WorkAdministrativeMetadata, :coded, :string)
      metadata_fields(WorkAdministrativeMetadata, :string, :string)
    end

    input_object :controlled_input do
      metadata_fields(WorkDescriptiveMetadata, :controlled, list_of(non_null(:string)))
    end

    query do
      field(:values, :values_with_options)
      field(:columns, :columns)
      field(:echo, :string, args: [input: [type: :controlled_input]])
    end
  end

  defp field_names(type) do
    TestSchema
    |> Absinthe.Schema.lookup_type(type)
    |> Map.fetch!(:fields)
    |> Map.keys()
    |> List.delete(:__typename)
    |> Enum.sort()
  end

  test "declares one field per metadata field of the kind, honoring :except" do
    expected =
      (WorkDescriptiveMetadata.__metadata__(:fields, :values) -- [:citation, :abstract])
      |> Enum.sort()

    assert field_names(:values_with_options) == expected
  end

  test "attaches deprecations" do
    %{fields: fields} = Absinthe.Schema.lookup_type(TestSchema, :values_with_options)
    assert fields.publisher.deprecation.reason == "Publisher field is deprecated"
    assert fields.keywords.deprecation == nil
  end

  test "uses the given type" do
    %{fields: fields} = Absinthe.Schema.lookup_type(TestSchema, :values_with_options)
    assert %Absinthe.Type.List{of_type: :string} = fields.keywords.type
  end

  test "works for column kinds and can be stacked in one object" do
    assert field_names(:columns) ==
             Enum.sort(
               WorkAdministrativeMetadata.__metadata__(:fields, :coded) ++
                 WorkAdministrativeMetadata.__metadata__(:fields, :string)
             )
  end

  test "works in input objects" do
    assert field_names(:controlled_input) ==
             Enum.sort(WorkDescriptiveMetadata.__metadata__(:fields, :controlled))
  end
end
