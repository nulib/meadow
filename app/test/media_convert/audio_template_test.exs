defmodule MediaConvert.AudioTemplateTest do
  use Meadow.DataCase

  alias Meadow.Config
  alias MediaConvert.AudioTemplate

  @template %{
    Queue: "test-transcode-queue",
    Role: "test-transcode-role",
    Settings: %{
      Inputs: [
        %{
          AudioSelectorGroups: %{
            "Audio Selector Group 1": %{AudioSelectorNames: ["Audio Selector 1"]}
          },
          AudioSelectors: %{"Audio Selector 1": %{DefaultSelection: "DEFAULT"}},
          TimecodeSource: "ZEROBASED",
          FileInput: "s3://source/test.wav"
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
          Outputs: Config.transcoding_presets(:audio)
        }
      ],
      TimecodeConfig: %{Source: "ZEROBASED"}
    },
    UserMetadata: %{file_set_id: "fake-file-set-id"}
  }

  describe "render/2" do
    test "template" do
      assert @template ==
               AudioTemplate.render(
                 %{file_set_id: "fake-file-set-id"},
                 "s3://source/test.wav",
                 "s3://destination/"
               )
    end
  end
end
