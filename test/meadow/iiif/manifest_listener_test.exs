defmodule Meadow.IIIF.ManifestListenerTest do
  use Meadow.DataCase
  use Meadow.S3Case
  alias Meadow.Config
  alias Meadow.IIIF.ManifestListener
  alias Meadow.Utils.Pairtree

  setup _context do
    listener = start_supervised!(ManifestListener)
    %{listener: listener}
  end

  @pyramid_bucket Config.pyramid_bucket()

  describe "handle_notification/2" do
    test "writes a manifest to S3 when it receives a Postgres INSERT/UPDATE notification" do
      work = work_fixture()
      destination = Pairtree.manifest_key(work.id)

      payload =
        "{\"operation\" : \"INSERT\", \"record\" : {\"id\":\"#{work.id}\",\"work_type\":\"image\",\"collection_id\":null,\"visibility\":\"restricted\",\"accession_number\":\"jjj\",\"descriptive_metadata\":{\"id\": \"4a6ecdbe-8509-4085-9f79-e6f2547dc852\", \"genre\": [], \"title\": null, \"keywords\": [], \"technique\": null, \"updated_at\": \"2020-03-03T10:55:13.594939Z\", \"description\": null, \"inserted_at\": \"2020-03-03T10:55:13.594939Z\", \"nul_subject\": []},\"administrative_metadata\":{\"id\": \"6dbc9f29-b66c-4f7c-a40e-d9484d892882\", \"updated_at\": \"2020-03-03T10:55:13.594917Z\", \"inserted_at\": \"2020-03-03T10:55:13.594917Z\", \"rights_statement\": null, \"preservation_level\": null},\"published\":false,\"inserted_at\":\"2020-03-03T10:55:13.594947\",\"updated_at\":\"2020-03-03T10:55:13.594947\",\"representative_file_set_id\":null}}"

      assert ManifestListener.handle_notification(:works_changed, payload, %{}) ==
               {:noreply, %{}}

      assert(object_exists?(@pyramid_bucket, destination))

      on_exit(fn ->
        delete_object(@pyramid_bucket, destination)
      end)
    end
  end
end
