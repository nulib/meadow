defmodule Meadow.Utils.Arn do
  @moduledoc """
  Utilities for parsing and manipulating AWS ARNs
  """

  defstruct scheme: "arn",
            partition: "aws",
            service: nil,
            region: "",
            account: "",
            resource: ""

  @doc "Parse an ARN into a struct"
  def parse(arn) do
    values =
      [:scheme, :partition, :service, :region, :account, :resource]
      |> Enum.zip(String.split(arn, ":"))

    struct(__MODULE__, values)
  end

  @doc "Update the ARN scheme"
  def update_scheme(arn, v), do: %__MODULE__{arn | scheme: v}

  @doc "Update the ARN partition"
  def update_partition(arn, v), do: %__MODULE__{arn | partition: v}

  @doc "Update the ARN service"
  def update_service(arn, v), do: %__MODULE__{arn | service: v}

  @doc "Update the ARN region"
  def update_region(arn, v), do: %__MODULE__{arn | region: v}

  @doc "Update the ARN account"
  def update_account(arn, v), do: %__MODULE__{arn | account: v}

  @doc "Update the ARN resource"
  def update_resource(arn, v), do: %__MODULE__{arn | resource: v}

  @doc "Convert an ARN struct to a string"
  def to_string(arn) do
    [arn.scheme, arn.partition, arn.service, arn.region, arn.account, arn.resource]
    |> Enum.join(":")
  end
end
