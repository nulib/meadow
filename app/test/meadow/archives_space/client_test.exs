defmodule Meadow.ArchivesSpace.ClientTest do
  use ExUnit.Case, async: false

  alias Meadow.ArchivesSpace.{Client, MockServer}

  setup do
    MockServer.reset()
    Client.invalidate_session()

    on_exit(fn ->
      MockServer.reset()
      Client.invalidate_session()
    end)

    :ok
  end

  describe "sessions" do
    test "logs in and caches the session token" do
      assert {:ok, token} = Client.session_token()
      assert {:ok, ^token} = Client.session_token()
    end

    test "re-authenticates when the session is gone" do
      record = MockServer.create_archival_object(2)
      {:ok, original_token} = Client.session_token()

      MockServer.expire_sessions()

      assert {:ok, %{"uri" => _}} = Client.get_record(record["uri"])
      assert {:ok, new_token} = Client.session_token()
      refute new_token == original_token
    end
  end

  describe "records" do
    test "get_record/1 fetches a record by uri" do
      record = MockServer.create_archival_object(2, %{"title" => "Folder 7"})

      assert {:ok, %{"title" => "Folder 7", "lock_version" => 0}} =
               Client.get_record(record["uri"])
    end

    test "get_record/1 returns an error for a missing record" do
      assert {:error, error} = Client.get_record("/repositories/2/archival_objects/404404")
      assert error =~ "404"
    end

    test "update_record/2 posts a record back and bumps its lock_version" do
      record = MockServer.create_archival_object(2)

      assert {:ok, %{"status" => "Updated", "lock_version" => 1}} =
               Client.update_record(record["uri"], Map.put(record, "title", "Updated Title"))

      assert MockServer.get_record(record["uri"])["title"] == "Updated Title"
    end

    test "update_record/2 reports stale lock_versions as conflicts" do
      record = MockServer.create_archival_object(2)
      {:ok, _} = Client.update_record(record["uri"], record)

      assert {:error, :conflict} = Client.update_record(record["uri"], record)
    end

    test "create_record/2 returns the new record's uri" do
      assert {:ok, "/repositories/2/digital_objects/" <> _} =
               Client.create_record("/repositories/2/digital_objects", %{
                 "jsonmodel_type" => "digital_object",
                 "digital_object_id" => "abc123"
               })
    end

    test "create_record/2 surfaces conflicting records" do
      subject = %{
        "jsonmodel_type" => "subject",
        "authority_id" => "http://id.loc.gov/authorities/subjects/sh85070610",
        "terms" => [%{"term" => "Subject", "term_type" => "topical"}]
      }

      assert {:ok, uri} = Client.create_record("/subjects", subject)
      assert {:conflict, ^uri} = Client.create_record("/subjects", subject)
    end

    test "search_resources/2 finds resources by keyword" do
      MockServer.create_resource(2, %{
        "title" => "Berkeley Folk Music Festival",
        "identifier" => "MS-63"
      })

      MockServer.create_resource(2, %{"title" => "University Archives"})
      MockServer.create_archival_object(2, %{"title" => "Folk Music Poster"})

      assert {:ok, %{results: [hit], total_hits: 1}} = Client.search_resources("folk music")
      assert hit.title == "Berkeley Folk Music Festival"
      assert hit.identifier == "MS-63"
      assert hit.uri =~ "/repositories/2/resources/"
    end

    test "search_resources/2 finds resources through matching archival objects" do
      resource =
        MockServer.create_resource(2, %{
          "title" => "John Cage scrapbooks",
          "identifier" => "abc123"
        })

      MockServer.create_archival_object(2, %{
        "title" => "John Cage: Composer, Vol. I, 1942 - 1946",
        "resource" => %{"ref" => resource["uri"]}
      })

      assert {:ok, %{results: [hit], total_hits: 1}} = Client.search_resources("Composer")
      assert hit.title == "John Cage scrapbooks"
      assert hit.identifier == "abc123"
      assert hit.uri == resource["uri"]
    end

    test "delete_record/1 deletes and tolerates already-deleted records" do
      record = MockServer.create_archival_object(2)

      assert :ok = Client.delete_record(record["uri"])
      assert MockServer.get_record(record["uri"]) |> is_nil()
      assert :ok = Client.delete_record(record["uri"])
    end
  end
end
