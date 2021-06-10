defmodule MediaConvert.VideoTemplate do
  @moduledoc """
  Create an AWS Elemental MediaConvert template for video jobs.
  """

  alias Meadow.Config

  def render(user_metadata, source, destination) do
    source_path = [:Settings, :Inputs, Access.at(0), :FileInput]

    destination_path = [
      :Settings,
      :OutputGroups,
      Access.at(0),
      :OutputGroupSettings,
      :CmafGroupSettings,
      :Destination
    ]

    template()
    |> Map.merge(%{
      UserMetadata: user_metadata,
      Role: Config.transcoder_role(),
      Queue: Config.transcoder_queue()
    })
    |> put_in(source_path, source)
    |> put_in(destination_path, destination)
  end

  defp template do
    %{
      Settings: %{
        Inputs: [
          %{
            AudioSelectors: %{"Audio Selector 1": %{DefaultSelection: "DEFAULT"}},
            TimecodeSource: "ZEROBASED",
            VideoSelector: %{}
          }
        ],
        OutputGroups: [
          %{
            Name: "CMAF",
            OutputGroupSettings: %{
              CmafGroupSettings: %{FragmentLength: 2, SegmentLength: 10},
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
      }
    }
  end
end
