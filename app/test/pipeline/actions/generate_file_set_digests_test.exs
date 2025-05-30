# defmodule Meadow.Pipeline.Actions.GenerateFileSetDigestsTest do
#   use Meadow.S3Case
#   use Meadow.DataCase
#   use Meadow.PipelineCase

#   alias Meadow.Config
#   alias Meadow.Data.{ActionStates, FileSets}
#   alias Meadow.Pipeline.Actions.GenerateFileSetDigests
#   alias Meadow.Utils.AWS

#   import ExUnit.CaptureLog
#   import WaitForIt

#   @bucket @ingest_bucket
#   @key "generate_file_set_digests_test/test.tif"
#   @content "test/fixtures/coffee.tif"
#   @fixture %{bucket: @bucket, key: @key, content: File.read!(@content)}
#   @md5 "85062e8c916f55ae0c514cb0732cfb1f"

#   setup do
#     file_set =
#       file_set_fixture(%{
#         accession_number: "123",
#         role: %{id: "A", scheme: "FILE_SET_ROLE"},
#         core_metadata: %{
#           location: "s3://#{@bucket}/#{@key}",
#           original_filename: "test.tif"
#         }
#       })

#     wait(
#       AWS.check_object_tags!(
#         @bucket,
#         @key,
#         Config.required_checksum_tags()
#       ),
#       timeout: Config.checksum_wait_timeout(),
#       frequency: 250
#     )

#     {:ok, file_set_id: file_set.id}
#   end

#   @tag s3: [@fixture]
#   test "process/2", %{file_set_id: file_set_id} do
#     assert(
#       {:ok, %{id: ^file_set_id}, %{}} =
#         send_test_message(GenerateFileSetDigests, %{file_set_id: file_set_id}, %{})
#     )

#     assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))

#     file_set = FileSets.get_file_set!(file_set_id)
#     assert(file_set.core_metadata.digests == %{"md5" => @md5})
#   end

#   describe "force flag" do
#     @describetag s3: [@fixture]

#     setup %{file_set_id: file_set_id} do
#       send_test_message(GenerateFileSetDigests, %{file_set_id: file_set_id}, %{})

#       :ok
#     end

#     test "skip if not forced", %{file_set_id: file_set_id} do
#       assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))

#       assert capture_log(fn ->
#                send_test_message(GenerateFileSetDigests, %{file_set_id: file_set_id}, %{})
#              end) =~ "Skipping #{GenerateFileSetDigests} for #{file_set_id} - already complete"
#     end

#     test "re-run if forced", %{file_set_id: file_set_id} do
#       assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))

#       assert capture_log(fn ->
#                send_test_message(GenerateFileSetDigests, %{file_set_id: file_set_id}, %{
#                  force: "true"
#                })
#              end) =~
#                "Forcing #{GenerateFileSetDigests} for #{file_set_id} even though it's already complete"
#     end
#   end

#   describe "overwrite flag" do
#     @describetag s3: [@fixture]

#     setup %{file_set_id: file_set_id} do
#       FileSets.get_file_set!(file_set_id)
#       |> FileSets.update_file_set(%{core_metadata: %{digests: %{md5: @md5}}})

#       :ok
#     end

#     test "overwrite", %{file_set_id: file_set_id} do
#       log =
#         capture_log(fn ->
#           assert {:ok, %{id: ^file_set_id}, %{}} =
#                    send_test_message(GenerateFileSetDigests, %{file_set_id: file_set_id}, %{})

#           assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))
#           file_set = FileSets.get_file_set!(file_set_id)
#           assert(file_set.core_metadata.digests == %{"md5" => @md5})
#         end)

#       refute log =~ ~r/already complete without overwriting/
#     end

#     test "retain", %{file_set_id: file_set_id} do
#       log =
#         capture_log(fn ->
#           assert {:ok, %{id: ^file_set_id}, %{}} =
#                    send_test_message(GenerateFileSetDigests, %{file_set_id: file_set_id}, %{
#                      overwrite: "false"
#                    })

#           assert(ActionStates.ok?(file_set_id, GenerateFileSetDigests))
#           file_set = FileSets.get_file_set!(file_set_id)
#           assert(file_set.core_metadata.digests == %{"md5" => @md5})
#         end)

#       assert log =~ ~r/already complete without overwriting/
#     end
#   end
# end
