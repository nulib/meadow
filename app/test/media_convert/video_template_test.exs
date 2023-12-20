defmodule MediaConvert.VideoTemplateTest do
  use Meadow.DataCase

  alias Meadow.Config
  alias MediaConvert.VideoTemplate

  @template %{
    Queue: "test-transcode-queue",
    Role: "test-transcode-role",
    Settings: %{
      Inputs: [
        %{
          AudioSelectors: %{"Audio Selector 1": %{DefaultSelection: "DEFAULT"}},
          FileInput: "s3://source/test.mkv",
          TimecodeSource: "ZEROBASED",
          VideoSelector: %{}
        }
      ],
      OutputGroups: [
        %{
          Name: "HLS",
          OutputGroupSettings: %{
            HlsGroupSettings: %{
              MinSegmentLength: 0,
              SegmentControl: "SEGMENTED_FILES",
              SegmentLength: 2,
              Destination: "s3://destination/"
            },
            Type: "HLS_GROUP_SETTINGS"
          },
          Outputs: Config.transcoding_presets(:video)
        }
      ],
      TimecodeConfig: %{Source: "ZEROBASED"}
    },
    UserMetadata: %{file_set_id: "fake-file-set-id"}
  }

  describe "render/2" do
    test "template" do
      assert @template ==
               VideoTemplate.render(
                 %{file_set_id: "fake-file-set-id"},
                 "s3://source/test.mkv",
                 "s3://destination/"
               )
    end
  end
end
