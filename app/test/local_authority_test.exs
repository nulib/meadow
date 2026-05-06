defmodule LocalAuthorityTest do
  use Meadow.DataCase, async: true

  alias NimbleCSV.RFC4180, as: CSV
  alias Meadow.Repo
  alias LocalAuthority.Schemas.Term

  setup_all do
    configured_authorities = Application.get_env(:authoritex, :authorities)
    on_exit(fn -> Application.put_env(:authoritex, :authorities, configured_authorities) end)

    test_modules = [
      LocalAuthority.create(
        :AAT,
        "aat",
        "http://vocab.getty.edu/aat/",
        "Local Getty Art & Architecture Thesaurus"
      ),
      LocalAuthority.create(
        :TGN,
        "tgn",
        "http://vocab.getty.edu/tgn/",
        "Local Getty Thesaurus of Geographic Names"
      ),
      LocalAuthority.create(
        :ULAN,
        "ulan",
        "http://vocab.getty.edu/ulan/",
        "Local Getty Union List of Artist Names"
      )
    ]

    Application.put_env(:authoritex, :authorities, test_modules)
  end

  describe "create/4" do
    test "creates a module that implements Authoritex" do
      authority_module =
        LocalAuthority.create(
          :Temp,
          "temp",
          "http://temp-authority.example.edu/",
          "Temporary Local Authority for Testing"
        )

      assert authority_module.code() == "temp"
      assert authority_module.description() == "Temporary Local Authority for Testing"
      assert authority_module.can_resolve?("http://temp-authority.example.edu/some_id")
      refute authority_module.can_resolve?("http://vocab.getty.edu/tgn/some_id")
    end
  end

  describe "search/2 and fetch/1" do
    setup do
      "test/fixtures/authority_records/local_authorities.csv"
      |> File.stream!()
      |> CSV.parse_stream()
      |> Enum.map(fn [authority, uri, label, hint, qualified_label, variants] ->
        %{
          authority: authority,
          uri: uri,
          label: label,
          hint: if(hint == "", do: nil, else: hint),
          qualified_label: qualified_label,
          variants: if(variants == "", do: nil, else: variants)
        }
      end)
      |> then(&Repo.insert_all(Term, &1))

      :ok
    end

    test "can resolve and fetch a term" do
      assert LocalAuthority.AAT.can_resolve?("http://vocab.getty.edu/aat/300433160")

      assert {:ok, record} =
               Authoritex.fetch("http://vocab.getty.edu/aat/300433160")

      assert record.id == "http://vocab.getty.edu/aat/300433160"
      assert record.label == "soccer goalie gloves"
      assert is_nil(record.hint)
      assert record.qualified_label == "soccer goalie gloves"

      assert record.variants == [
               "gant de gardien de but de soccer",
               "glove, soccer goalie",
               "soccer goalie glove"
             ]

      assert LocalAuthority.ULAN.can_resolve?("http://vocab.getty.edu/ulan/500078791")

      assert {:ok, record} =
               Authoritex.fetch("http://vocab.getty.edu/ulan/500078791")

      assert record.id == "http://vocab.getty.edu/ulan/500078791"
      assert record.label == "Nijinsky, Vaslav"
      assert record.hint == "artist"
      assert record.qualified_label == "Nijinsky, Vaslav"
      assert Enum.member?(record.variants, "Nižinskij, Vaclav Fomič")
    end

    test "returns nil for a non-existent term" do
      assert LocalAuthority.AAT.can_resolve?("http://vocab.getty.edu/aat/non_existent_id")
      assert {:error, 404} = Authoritex.fetch("http://vocab.getty.edu/aat/non_existent_id")
    end

    test "search for a term" do
      assert {:ok, results} = Authoritex.search("ulan", "nijinsky")
      assert results != []

      assert Enum.any?(results, fn result ->
               result.id == "http://vocab.getty.edu/ulan/500078791"
               result.label == "Nijinsky, Vaslav"
               result.hint == "artist"
             end)
    end

    test "search returns empty list for no matches" do
      assert {:ok, results} = Authoritex.search("tgn", "bogus nowheresville")
      assert results == []
    end
  end
end
