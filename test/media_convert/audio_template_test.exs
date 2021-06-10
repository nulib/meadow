defmodule MediaConvert.AudioTemplateTest do
  use Meadow.DataCase

  alias MediaConvert.AudioTemplate

  @template %{
    Queue: "arn:aws:mediaconvert:::queues/Default",
    Role: "arn:aws:iam:::role/service-role/MediaConvert_Default_Role",
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
          Name: "File Group",
          OutputGroupSettings: %{
            FileGroupSettings: %{Destination: "s3://destination/"},
            Type: "FILE_GROUP_SETTINGS"
          },
          Outputs: [
            %{
              AudioDescriptions: [
                %{
                  AudioSourceName: "Audio Selector 1",
                  CodecSettings: %{
                    AacSettings: %{
                      CodingMode: "CODING_MODE_2_0",
                      RateControlMode: "VBR",
                      SampleRate: 44_100,
                      VbrQuality: "MEDIUM_HIGH"
                    },
                    Codec: "AAC"
                  }
                }
              ],
              ContainerSettings: %{Container: "MP4", Mp4Settings: %{}}
            }
          ]
        }
      ],
      TimecodeConfig: %{Source: "ZEROBASED"}
    },
    UserMetadata: %{file_set_id: "fake-file-set-id"}
  }

  describe "render/2" do
    test "template" do
      assert @template == AudioTemplate.render(%{file_set_id: "fake-file-set-id"}, "s3://source/test.wav", "s3://destination/")
    end
  end
end
