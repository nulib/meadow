defmodule Meadow.Data.Schemas.RelatedURLEntryTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.RelatedURLEntry

  @valid_attrs %{
    url: "https://example.edu/related/url",
    label: %{id: "RELATED_INFORMATION", scheme: "related_url"}
  }

  @invalid_attrs %{
    url: "https://example.edu/related/url",
    label: %{id: "UNRELATED_INFORMATION", scheme: "related_url"}
  }

  describe "changeset/2" do
    test "with valid type" do
      changeset = %RelatedURLEntry{} |> RelatedURLEntry.changeset(@valid_attrs)

      assert changeset.valid?
    end

    test "with invalid type" do
      changeset = %RelatedURLEntry{} |> RelatedURLEntry.changeset(@invalid_attrs)

      refute changeset.valid?
    end

    test "with missing type" do
      changeset =
        %RelatedURLEntry{}
        |> RelatedURLEntry.changeset(%{
          url: "https://example.edu/related/url"
        })

      refute changeset.valid?
    end
  end

  describe "from_string/1" do
    test "qualified note" do
      assert "RELATED_INFORMATION:https://example.edu/related/url"
             |> RelatedURLEntry.from_string() ==
               @valid_attrs
    end

    test "invalid type" do
      assert "UNRELATED_INFORMATION:https://example.edu/related/url"
             |> RelatedURLEntry.from_string() ==
               @invalid_attrs
    end

    test "missing type" do
      assert "https://example.edu/related/url"
             |> RelatedURLEntry.from_string() == %{url: "https://example.edu/related/url"}
    end
  end
end
