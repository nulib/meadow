defmodule MediaConvert.Mock do
  @moduledoc """
  Mock AWS Elemental MediaConvert client
  """
  def configure! do
    :ok
  end

  @doc """
  Simulate responses from creating jobs via the MediaConvert HTTP API

  To return an error tuple, make sure the MediaConvert template passed in has a :FileInput value containing
  the word "error", e.g. %{FileInput: "s3://error/test.mov"} => {:error, "Fake error response"}
  """
  def create_job(template) do
    if String.match?(file_input(template), ~r/error/) do
      {:error, "Fake error response"}
    else
      {:ok, "fake-job-id"}
    end
  end

  defp file_input(%{Settings: %{Inputs: [%{FileInput: file_input}]}}), do: file_input
  defp file_input(_template), do: ""
end
