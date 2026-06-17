defmodule Meadow.ArchivesSpace.ImportPreviewTest do
  use Meadow.DataCase

  alias Meadow.ArchivesSpace.{Client, ImportPreview, MockServer, PreviewStore}
  alias Meadow.Notification

  setup do
    MockServer.reset()
    Client.invalidate_session()

    # PreviewStore is a web-tier process not started by the test harness; the
    # MCP tool would normally write previews here for the resolver to read.
    case start_supervised(PreviewStore) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    # Keep Digital's image copy off the network/S3 and short-circuit the agent,
    # populating the store the way the real submit_archives_space_previews MCP
    # tool would.
    Application.put_env(:meadow, :archives_space_image_store, fn _uri, _key -> :ok end)

    on_exit(fn ->
      Application.delete_env(:meadow, :archives_space_image_store)
      Application.delete_env(:meadow, :archives_space_preview_agent)
    end)

    resource = MockServer.create_resource(2, %{"title" => "Berkeley Folk Music Festival Records"})

    {:ok, %{resource: resource}}
  end

  defp with_image(archival_object) do
    digital_object =
      MockServer.create_digital_object(2, %{
        "file_versions" => [
          %{"file_uri" => "https://images.example.edu/poster.tif", "publish" => true}
        ]
      })

    MockServer.seed(
      Map.put(archival_object, "instances", [MockServer.digital_object_instance(digital_object)])
    )
  end

  defp stub_agent(cost) do
    Application.put_env(:meadow, :archives_space_preview_agent, fn samples, token ->
      previews =
        Enum.map(samples, fn %{accession: accession, s3_uri: s3_uri} ->
          %{
            work_accession_number: accession,
            filename: s3_uri,
            description: "AI description for #{accession}",
            subjects: [%{id: "http://example.edu/fast/1", label: "Folk music"}],
            thumbnail: "ZmFrZQ=="
          }
        end)

      PreviewStore.put(token, previews)
      {:ok, cost}
    end)
  end

  describe "generate/2" do
    test "previews up to three image-bearing works and extrapolates cost", %{resource: resource} do
      for n <- 1..4 do
        MockServer.create_archival_object(2, %{
          "level" => "item",
          "display_string" => "Poster #{n}, 1968",
          "resource" => %{"ref" => resource["uri"]}
        })
        |> with_image()
      end

      stub_agent(0.30)

      assert {:ok, summary} = ImportPreview.generate(resource["uri"])

      assert summary.sample_count == 3
      assert length(summary.previews) == 3
      assert summary.total_count == 4

      # 0.30 cost / 3 sampled * 4 total * 1.3 fudge factor
      assert summary.estimated_cost == 0.52

      titles = Enum.map(summary.previews, & &1.title)
      assert "Poster 1, 1968" in titles

      preview = hd(summary.previews)
      assert preview.description =~ "AI description"
      assert [%{label: "Folk music"}] = preview.subjects
      assert preview.thumbnail == "ZmFrZQ=="
    end

    test "skips archival objects without digital-object images", %{resource: resource} do
      MockServer.create_archival_object(2, %{
        "level" => "item",
        "display_string" => "Text-only finding aid entry",
        "resource" => %{"ref" => resource["uri"]}
      })

      MockServer.create_archival_object(2, %{
        "level" => "item",
        "display_string" => "Poster with image",
        "resource" => %{"ref" => resource["uri"]}
      })
      |> with_image()

      stub_agent(0.10)

      assert {:ok, summary} = ImportPreview.generate(resource["uri"])

      assert summary.sample_count == 1
      assert [%{title: "Poster with image"}] = summary.previews
    end

    test "returns an empty preview when nothing has images", %{resource: resource} do
      MockServer.create_archival_object(2, %{
        "level" => "item",
        "display_string" => "Text-only",
        "resource" => %{"ref" => resource["uri"]}
      })

      assert {:ok, summary} = ImportPreview.generate(resource["uri"])

      assert summary.sample_count == 0
      assert summary.previews == []
      assert summary.estimated_cost == 0.0
    end

    test "ignores levels that are not imported", %{resource: resource} do
      MockServer.create_archival_object(2, %{
        "level" => "series",
        "display_string" => "Series I",
        "resource" => %{"ref" => resource["uri"]}
      })
      |> with_image()

      assert {:ok, summary} = ImportPreview.generate(resource["uri"])

      assert summary.sample_count == 0
    end
  end

  describe "start/2" do
    setup do
      :ok = Notification.register(self())
      on_exit(fn -> Notification.unregister(self()) end)
    end

    test "returns a token and publishes the finished preview", %{resource: resource} do
      MockServer.create_archival_object(2, %{
        "level" => "item",
        "display_string" => "Poster 1, 1968",
        "resource" => %{"ref" => resource["uri"]}
      })
      |> with_image()

      stub_agent(0.30)

      token = ImportPreview.start(resource["uri"])
      assert is_binary(token)

      topic = ImportPreview.topic(token)

      assert_receive {:notify, payload, [archives_space_import_preview: ^topic]}, 5_000

      assert payload.token == token
      assert payload.status == :complete
      assert [%{title: "Poster 1, 1968"}] = payload.previews
    end
  end
end
