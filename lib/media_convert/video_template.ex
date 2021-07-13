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
      :HlsGroupSettings,
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
            Name: "HLS",
            OutputGroupSettings: %{
              HlsGroupSettings: %{
                MinSegmentLength: 0,
                SegmentControl: "SEGMENTED_FILES",
                SegmentLength: 2
              },
              Type: "HLS_GROUP_SETTINGS"
            },
            Outputs: Config.transcoding_presets(:video)
          }
        ],
        TimecodeConfig: %{Source: "ZEROBASED"}
      }
    }
  end
end
