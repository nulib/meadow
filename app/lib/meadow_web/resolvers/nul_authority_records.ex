defmodule MeadowWeb.Resolvers.NULAuthorityRecords do
  @moduledoc """
  Resolver for NUL.AuthorityRecords
  """

  alias Meadow.Utils.ChangesetErrors
  alias NUL.AuthorityRecords

  def nul_authority_records(_, %{limit: limit}, _) do
    {:ok, AuthorityRecords.list_authority_records(limit)}
  end

  def nul_authority_record(_, %{id: id}, _) do
    {:ok, AuthorityRecords.get_authority_record!(id)}
  end

  def create_nul_authority_record(_, args, _) do
    case AuthorityRecords.create_authority_record(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create authority record",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, authority_record} ->
        {:ok, authority_record}
    end
  end

  def update_nul_authority_record(_, %{id: id, label: label, hint: hint}, _) do
    authority_record = AuthorityRecords.get_authority_record!(id)

    case AuthorityRecords.update_authority_record(authority_record, %{label: label, hint: hint}) do
      {:error, changeset} ->
        {:error,
         message: "Could not update authority record",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, authority_record} ->
        {:ok, authority_record}
    end
  end

  def delete_nul_authority_record(_, args, _) do
    authority_record = AuthorityRecords.get_authority_record!(args[:nul_authority_record_id])

    case AuthorityRecords.delete_authority_record(authority_record) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete Authority Record",
          details: ChangesetErrors.humanize_errors(changeset)
        }

      {:ok, authority_record} ->
        {:ok, authority_record}
    end
  end
end
