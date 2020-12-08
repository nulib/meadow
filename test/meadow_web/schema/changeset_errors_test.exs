defmodule MeadowWeb.Schema.ChangesetErrorsTest do
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.ControlledTerms
  alias Meadow.Data.Schemas.Work
  alias MeadowWeb.Schema.ChangesetErrors

  setup do
    ControlledTerms.fetch("unknown:nb2015010626")
    :ok
  end

  test "formats errors for human readability" do
    invalid_attrs = %{
      accession_number: "",
      descriptive_metadata: %{
        contributor: [
          %{
            term: "missing_id_authority:123",
            role: %{
              id: "aut",
              scheme: "marc_relator"
            }
          }
        ],
        genre: [
          %{term: "wrong"}
        ],
        subject: [
          %{
            term: "http://id.loc.gov/authorities/names/nb2015010626",
            role: %{
              id: "wrong_coded_term_id",
              scheme: "subject_role"
            }
          }
        ]
      }
    }

    changeset = Work.changeset(%Work{}, invalid_attrs)
    error_details = ChangesetErrors.error_details(changeset)

    assert get_in(error_details, [:accession_number]) == ["can't be blank"]

    assert List.first(get_in(error_details, [:descriptive_metadata, :contributor]))
           |> Map.get(:term) == ["identifier not found in authority"]

    assert List.first(get_in(error_details, [:descriptive_metadata, :genre]))
           |> Map.get(:term) == ["unknown authority"]

    assert List.first(get_in(error_details, [:descriptive_metadata, :subject]))
           |> Map.get(:role) == [
             "wrong_coded_term_id is an invalid coded term for scheme SUBJECT_ROLE"
           ]
  end

  test "handles changesets without errors" do
    valid_attrs = %{
      accession_number: "12345",
      descriptive_metadata: %{title: "Test"}
    }

    changeset = Work.changeset(%Work{}, valid_attrs)

    assert ChangesetErrors.error_details(changeset) == %{}
  end
end
