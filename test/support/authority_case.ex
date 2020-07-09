defmodule Meadow.AuthorityCase do
  @moduledoc """
  Defines a common set of mock entries and setup for tests involving
  Authoritex.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Authoritex.Mock

      setup do
        Mock.set_data([
          %{
            id: "mock1:result1",
            label: "First Result",
            qualified_label: "First Result (1)",
            hint: "(1)"
          },
          %{
            id: "mock1:result2",
            label: "Second Result",
            qualified_label: "Second Result (2)",
            hint: "(2)"
          },
          %{
            id: "mock2:result3",
            label: "Third Result",
            qualified_label: "Third Result (3)",
            hint: "(3)"
          },
          %{
            id: "http://id.loc.gov/authorities/names/nb2015010626",
            label: "Border Collie Trust Great Britain",
            qualified_label: "Border Collie Trust Great Britain",
            hint: "Border Collie Trust Great Britain"
          }
        ])

        :ok
      end
    end
  end
end
