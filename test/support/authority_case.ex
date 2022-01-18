defmodule Meadow.AuthorityCase do
  @moduledoc """
  Defines a common set of mock entries and setup for tests involving
  Authoritex.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Authoritex.Mock

      setup tags do
        case Map.get(tags, :authority_file) do
          nil ->
            Mock.set_data([
              %{
                id: "mock1:result1",
                label: "First Result",
                qualified_label: "First Result (1)",
                hint: "(1)",
                variants: []
              },
              %{
                id: "mock1:result2",
                label: "Second Result",
                qualified_label: "Second Result (2)",
                hint: "(2)",
                variants: []
              },
              %{
                id: "mock2:result3",
                label: "Third Result",
                qualified_label: "Third Result (3)",
                hint: "(3)",
                variants: []
              },
              %{
                id: "http://id.loc.gov/authorities/names/nb2015010626",
                label: "Border Collie Trust Great Britain",
                qualified_label: "Border Collie Trust Great Britain",
                hint: "Border Collie Trust Great Britain",
                variants: [
                  "Border Collie Trust G.B.",
                  "Border Collie Trust GB",
                  "BCT G.B. (Border Collie Trust G.B.)",
                  "BCT GB (Border Collie Trust G.B.)",
                  "BCTGB (Border Collie Trust G.B.)"
                ]
              },
              %{
                id: "https://sws.geonames.org/5347269/",
                label: "Faculty Glade",
                qualified_label: "Faculty Glade (California, United States)",
                hint: "California, United States",
                variants: []
              }
            ])

          fixture ->
            File.read!(fixture)
            |> Jason.decode!(keys: :atoms)
            |> Authoritex.Mock.set_data()
        end

        :ok
      end
    end
  end
end
