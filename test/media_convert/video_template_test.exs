defmodule MediaConvert.VideoTemplateTest do
  use Meadow.DataCase

  alias MediaConvert.VideoTemplate

  @template %{
    Queue: "arn:aws:mediaconvert:::queues/Default",
    Role: "arn:aws:iam:::role/service-role/MediaConvert_Default_Role",
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
          Name: "CMAF",
          OutputGroupSettings: %{
            CmafGroupSettings: %{
              Destination: "s3://destination/",
              FragmentLength: 2,
              SegmentLength: 10
            },
            Type: "CMAF_GROUP_SETTINGS"
          },
          Outputs: [
            %{
              NameModifier: "-1080",
              Preset: "System-Ott_Cmaf_Cmfc_Avc_16x9_Sdr_1920x1080p_30Hz_8Mbps_Qvbr_Vq8"
            },
            %{
              NameModifier: "-720",
              Preset: "System-Ott_Cmaf_Cmfc_Avc_16x9_Sdr_1280x720p_30Hz_4Mbps_Qvbr_Vq7"
            },
            %{
              NameModifier: "-540",
              Preset: "System-Ott_Cmaf_Cmfc_Avc_16x9_Sdr_960x540p_30Hz_2.5Mbps_Qvbr_Vq7"
            },
            %{
              AudioDescriptions: [
                %{
                  AudioSourceName: "Audio Selector 1",
                  CodecSettings: %{
                    AacSettings: %{
                      Bitrate: 192_000,
                      CodingMode: "CODING_MODE_2_0",
                      SampleRate: 44_100
                    },
                    Codec: "AAC"
                  }
                }
              ],
              ContainerSettings: %{Container: "CMFC"}
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
      assert @template == VideoTemplate.render(%{file_set_id: "fake-file-set-id"}, "s3://source/test.mkv", "s3://destination/")
    end
  end
end
