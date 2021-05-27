defmodule MediaConvert.AudioTemplate do
  @moduledoc """
  Create an AWS Elemental MediaConvert template for audio jobs.
  """

  alias Meadow.Config

  def render(user_metadata, source, destination) do
    source_path = [:Settings, :Inputs, Access.at(0), :FileInput]

    destination_path = [
      :Settings,
      :OutputGroups,
      Access.at(0),
      :OutputGroupSettings,
      :FileGroupSettings,
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
            AudioSelectorGroups: %{
              "Audio Selector Group 1": %{AudioSelectorNames: ["Audio Selector 1"]}
            },
            TimecodeSource: "ZEROBASED"
          }
        ],
        OutputGroups: [
          %{
            Name: "File Group",
            OutputGroupSettings: %{
              FileGroupSettings: %{},
              Type: "FILE_GROUP_SETTINGS"
            },
            Outputs: [
              %{
                ContainerSettings: %{
                  Container: "MP4",
                  Mp4Settings: %{}
                },
                AudioDescriptions: [
                  %{
                    AudioSourceName: "Audio Selector 1",
                    CodecSettings: %{
                      Codec: "AAC",
                      AacSettings: %{
                        VbrQuality: "MEDIUM_HIGH",
                        RateControlMode: "VBR",
                        CodingMode: "CODING_MODE_2_0",
                        SampleRate: 44_100
                      }
                    }
                  }
                ]
              }
            ]
          }
        ],
        TimecodeConfig: %{Source: "ZEROBASED"}
      }
    }
  end
end
