defmodule Mix.Tasks.Assets.Install do
  @moduledoc """
  Installs JavaScript dependencies
  """
  def run(_) do
    File.cd!("assets", fn ->
      System.cmd("yarn", ["install"], into: IO.stream(:stdio, :line))
    end)
  end
end

defmodule Mix.Tasks.Assets.Build do
  @moduledoc """
  Builds static assets
  """
  alias Mix.Tasks.Assets.Install

  def run(_) do
    Install.run(0)

    File.cd!("assets", fn ->
      System.cmd("yarn", ["deploy", "--production"], into: IO.stream(:stdio, :line))
    end)
  end
end
