defmodule Meadow.Data.CodedTerms do
  @moduledoc "Functions for retrieving coded terms and term lists"

  alias Meadow.Data.Schemas.CodedTerm
  alias Meadow.Repo

  import Ecto.Query

  @doc """
  List all coded term schemes

  Example:
    iex> Meadow.Data.CodedTerms.list_schemes()
    ["authority", "license", "marc_relator", "preservation_level",
     "rights_statement", "status", "subject_role", "visibility", "work_type"]
  """
  def list_schemes do
    from(ct in CodedTerm, distinct: ct.scheme, select: [:scheme])
    |> Repo.all()
    |> Enum.map(& &1.scheme)
  end

  @doc """
  List all coded terms in a scheme

  Examples:
    iex> Meadow.Data.CodedTerms.list_coded_terms("visibility")
    [
      %Meadow.Data.Schemas.CodedTerm{
        id: "AUTHENTICATED",
        label: "Institution",
        scheme: "visibility"
      },
      %Meadow.Data.Schemas.CodedTerm{
        id: "RESTRICTED",
        label: "Private",
        scheme: "visibility"
      },
      %Meadow.Data.Schemas.CodedTerm{
        id: "OPEN",
        label: "Public",
        scheme: "visibility"
      }
    ]

    iex> Meadow.Data.CodedTerms.list_coded_terms("non_existent_scheme")
    []
  """
  def list_coded_terms(scheme) do
    with scheme <- normalize(scheme) do
      from(ct in CodedTerm,
        where: ct.scheme == ^scheme,
        order_by: ct.label
      )
      |> Repo.all()
    end
  end

  @doc """
  Retrieve a coded term by id and scheme

  Example:
    iex> Meadow.Data.CodedTerms.get_coded_term("OPEN", "visibility")
    %Meadow.Data.Schemas.CodedTerm{
      id: "OPEN",
      label: "Public",
      scheme: "visibility"
    }

    iex> Meadow.Data.CodedTerms.get_coded_term("NAH", "visibility")
    nil

    iex> Meadow.Data.CodedTerms.get_coded_term("OPEN", "invisibility")
    nil
  """
  def get_coded_term(id, scheme) do
    with scheme <- normalize(scheme) do
      from(ct in CodedTerm,
        where: ct.scheme == ^scheme and ct.id == ^id,
        order_by: ct.label
      )
      |> Repo.one()
    end
  end

  def label(id, scheme) do
    case get_coded_term(id, scheme) do
      nil ->
        nil

      term ->
        term.label
    end
  end

  defp normalize(scheme), do: scheme |> to_string |> String.downcase()
end
