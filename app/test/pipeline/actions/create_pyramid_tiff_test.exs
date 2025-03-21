# defmodule Meadow.Pipeline.Actions.CreatePyramidTiffTest do
#   use Meadow.S3Case
#   use Meadow.DataCase
#   use Meadow.PipelineCase

#   alias Meadow.Data.{ActionStates, FileSets}
#   alias Meadow.Pipeline.Actions.CreatePyramidTiff
#   alias Meadow.Repo
#   alias Meadow.Utils.Pairtree

#   import ExUnit.CaptureLog

#   @key "create_pyramid_tiff_test/coffee.tif"
#   @content "test/fixtures/coffee.tif"
#   @fixture %{bucket: @ingest_bucket, key: @key, content: File.read!(@content)}

#   setup do
#     file_set =
#       file_set_fixture(%{
#         id: "6caf2759-c476-46ae-9c40-ec58cf44c704",
#         accession_number: "123",
#         role: %{id: "A", scheme: "FILE_SET_ROLE"},
#         core_metadata: %{
#           location: "s3://#{@ingest_bucket}/#{@key}",
#           original_filename: "coffee.tif"
#         }
#       })

#     invalid_file_set =
#       file_set_fixture(%{
#         id: "5915fe2b-6b66-4373-b69a-e13f765dc2a4",
#         accession_number: "1234",
#         role: %{id: "A", scheme: "FILE_SET_ROLE"},
#         core_metadata: %{
#           location: "invalid",
#           original_filename: "coffee.tif"
#         }
#       })

#     {:ok,
#      file_set_id: file_set.id,
#      pairtree: Pairtree.pyramid_path(file_set.id),
#      invalid_file_set_id: invalid_file_set.id,
#      invalid_pairtree: Pairtree.pyramid_path(invalid_file_set.id)}
#   end

#   @tag s3: [@fixture]
#   describe "success" do
#     test "process/2", %{file_set_id: file_set_id, pairtree: dest} do
#       assert {:ok, %{id: ^file_set_id}, %{}} =
#                send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})

#       assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))
#       assert(object_exists?(@pyramid_bucket, dest))

#       assert FileSets.get_file_set(file_set_id)
#              |> Map.get(:derivatives)
#              |> Map.get("pyramid_tiff") == "s3://#{@pyramid_bucket}/#{dest}"

#       with metadata <- object_metadata(@pyramid_bucket, dest) do
#         assert metadata.height == "1024"
#         assert metadata.width == "1024"
#       end

#       on_exit(fn ->
#         delete_object(@pyramid_bucket, dest)
#       end)
#     end
#   end

#   describe "file_set with invalid location fails" do
#     test "process/2", %{invalid_file_set_id: file_set_id, invalid_pairtree: dest} do
#       assert {:error, _, %{error: "Invalid location: invalid"}} =
#                send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})

#       assert(ActionStates.ok?(file_set_id, CreatePyramidTiff) == false)

#       refute(object_exists?(@pyramid_bucket, dest))

#       on_exit(fn ->
#         delete_object(@pyramid_bucket, dest)
#       end)
#     end

#     test "process/2 will skip the action if it has been previously set to error", %{
#       invalid_file_set_id: file_set_id,
#       invalid_pairtree: dest
#     } do
#       assert {:error, _, %{error: "Invalid location: invalid"}} =
#                send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})

#       assert(ActionStates.error?(file_set_id, CreatePyramidTiff) == true)

#       assert(
#         {:ok, %{id: ^file_set_id}, _} =
#           send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})
#       )

#       assert capture_log(fn ->
#                send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})
#              end) =~ "Skipping #{CreatePyramidTiff} for #{file_set_id} - already complete"

#       on_exit(fn ->
#         delete_object(@pyramid_bucket, dest)
#       end)
#     end
#   end

#   describe "force flag" do
#     @describetag s3: [@fixture]

#     setup %{file_set_id: file_set_id, pairtree: dest} do
#       send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})

#       on_exit(fn ->
#         delete_object(@pyramid_bucket, dest)
#       end)

#       :ok
#     end

#     test "skip if not forced", %{file_set_id: file_set_id} do
#       assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))

#       assert capture_log(fn ->
#                send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})
#              end) =~ "Skipping #{CreatePyramidTiff} for #{file_set_id} - already complete"
#     end

#     test "re-run if forced", %{file_set_id: file_set_id} do
#       assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))

#       assert capture_log(fn ->
#                send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{
#                  force: "true"
#                })
#              end) =~
#                "Forcing #{CreatePyramidTiff} for #{file_set_id} even though it's already complete"
#     end
#   end

#   describe "overwrite flag" do
#     @describetag s3: [@fixture]

#     setup %{file_set_id: file_set_id, pairtree: dest} do
#       send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})
#       ActionStates.get_states(file_set_id) |> Enum.each(&Repo.delete!/1)

#       on_exit(fn ->
#         delete_object(@pyramid_bucket, dest)
#       end)

#       :ok
#     end

#     test "overwrite", %{file_set_id: file_set_id} do
#       log =
#         capture_log(fn ->
#           assert {:ok, %{id: ^file_set_id}, %{}} =
#                    send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{})

#           assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))
#         end)

#       refute log =~ ~r/already complete without overwriting/
#     end

#     test "retain", %{file_set_id: file_set_id} do
#       log =
#         capture_log(fn ->
#           assert {:ok, %{id: ^file_set_id}, %{}} =
#                    send_test_message(CreatePyramidTiff, %{file_set_id: file_set_id}, %{
#                      overwrite: "false"
#                    })

#           assert(ActionStates.ok?(file_set_id, CreatePyramidTiff))
#         end)

#       assert log =~ ~r/already complete without overwriting/
#     end
#   end
# end
