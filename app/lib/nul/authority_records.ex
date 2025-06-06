defmodule NUL.AuthorityRecords do
  @moduledoc """
  The NUL.AuthorityRecords context.
  """

  #  alias Faker.NaiveDateTime
  alias Meadow.Repo
  alias NUL.Schemas.AuthorityRecord

  import Ecto.Query

  require Logger

  @doc """
  Returns the list of AuthorityRecords.

  ## Examples

      iex> list_authority_records(2)
      [%NUL.Schemas.AuthorityRecord{}, %NUL.Schemas.AuthorityRecord{}]

  """
  def list_authority_records(limit \\ 100) do
    from(a in AuthorityRecord, order_by: [desc: a.inserted_at, desc: a.id], limit: ^limit)
    |> Repo.all()
  end

  def with_stream(func) do
    Repo.transaction(fn ->
      stream = Repo.stream(AuthorityRecord)
      func.(stream)
    end)
  end

  @doc """
  Gets an AuthorityRecord.

  Raises `Ecto.NoResultsError` if the AuthorityRecord does not exist.

  ## Examples

      iex> get_authority_record!("info:nul/123")
      %NUL.Schemas.AuthorityRecord{}

      iex> get_authority_record!("456")
      ** (Ecto.NoResultsError)

  """
  def get_authority_record!(id) do
    Repo.get!(AuthorityRecord, id)
  end

  @doc """
  Gets an AuthorityRecord.

  ## Examples

      iex> get_authority_record("info:nul/123")
      %NUL.Schemas.AuthorityRecord{}

      iex> get_authority_record("456")
      nil

  """
  def get_authority_record(id) do
    Repo.get(AuthorityRecord, id)
  end

  @doc """
  Creates an AuthorityRecord.

  ## Examples

      iex> create_authority_record(%{id: "info:nul/123", label: "test label", hint: "test hint"})
      {:ok, %NUL.Schemas.AuthorityRecord{}}

      iex> create_authority_record(%{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  def create_authority_record(attrs \\ %{}) do
    %AuthorityRecord{}
    |> AuthorityRecord.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Same as create_authority_record/1 but raises on error
  """
  def create_authority_record!(attrs \\ %{}) do
    %AuthorityRecord{}
    |> AuthorityRecord.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates many AuthorityRecords at once using bulk insert. Returns a list of [{:created|:duplicate}, %AuthorityRecord{}]
  where the record is either the newly created record or the retrieved existing record
  """
  def create_authority_records(list_of_attrs) do
    inserted_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    records =
      Enum.map(list_of_attrs, fn entry ->
        %{
          id: "info:nul/" <> Ecto.UUID.generate(),
          label: String.trim(Map.get(entry, :label, "")),
          hint: String.trim(Map.get(entry, :hint, "")),
          inserted_at: inserted_at,
          updated_at: inserted_at
        }
      end)
      |> Enum.reject(&(&1.label == ""))

    labels = Enum.map(records, & &1.label)

    duplicates =
      from(ar in AuthorityRecord, where: ar.label in ^labels)
      |> Repo.all()
      |> indexed_records(:duplicate)

    created =
      Repo.insert_all(AuthorityRecord, records,
        returning: true,
        on_conflict: :nothing,
        conflict_target: :label
      )
      |> indexed_records(:created)

    results = Enum.into(created ++ duplicates, %{})
    Enum.map(labels, &Map.get(results, &1))
  rescue
    error ->
      Logger.error("Error in create_authority_records: #{inspect(error)}")
      {:error, error}
  end

  # Creates many AuthorityRecords at once by inserting each individually to get around the
  # `(Postgrex.QueryError) postgresql protocol can not handle 135500 parameters, the maximum is 65535 error`.
  # Uncomment this function and comment out above function for dev environment loads of full export from prod.
  # You may also need to adjust MeadowWeb.AuthorityRecordsController.do_bulk_update/2 if you need to pass in ids.
  # """

  # def create_authority_records(list_of_attrs) do
  #   case Repo.transaction(fn ->
  #          Enum.map(list_of_attrs, &create_authority_record/1) |> IO.inspect()
  #        end) do
  #     {:ok, results} -> results
  #     {:error, error} -> {:error, error}
  #   end
  # end

  @doc """
  Updates an AuthorityRecord.

  ## Examples

      iex> update_authority_record(authority_record, %{label: "new label"})
      {:ok, %AuthorityRecord{}}

      iex> update_authority_record(authority_record, %{id: "not allowed"})
      {:error, %Ecto.Changeset{}}

  """
  def update_authority_record(%AuthorityRecord{} = authority_record, attrs) do
    authority_record
    |> AuthorityRecord.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates many AuthorityRecords at once. Ignores any updates for records with IDs
  that do not already exist. Returns a list of updated Authority records.
  """
  def update_authority_records(list_of_attrs) do
    updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    records =
      Enum.map(list_of_attrs, fn entry ->
        %{
          id: String.trim(Map.get(entry, :id)),
          label: String.trim(Map.get(entry, :label, "")),
          hint: String.trim(Map.get(entry, :hint, "") || ""),
          updated_at: updated_at
        }
      end)

    # Check for duplicate labels within the batch
    duplicate_labels_found = duplicate_labels(records)

    {duplicate_records, clean_records} =
      Enum.split_with(records, fn record -> record.label in duplicate_labels_found end)

    # Check for label conflicts with existing records
    labels = Enum.map(clean_records, & &1.label)
    ids = Enum.map(clean_records, & &1.id)

    conflicting_labels =
      from(ar in AuthorityRecord,
        where: ar.label in ^labels and ar.id not in ^ids,
        select: ar.label
      )
      |> Repo.all()

    {conflict_records, processable_records} =
      Enum.split_with(clean_records, fn record -> record.label in conflicting_labels end)

    clean_results =
      case Repo.transaction(fn -> do_update_authority_records(processable_records) end) do
        {:ok, results} ->
          results

        other ->
          other
      end

    duplicate_results =
      duplicate_records
      |> Enum.map(fn record ->
        %{id: record.id, label: record.label, hint: record.hint}
      end)
      |> indexed_records(:duplicate_in_batch)

    conflict_results =
      conflict_records
      |> Enum.map(fn record ->
        %{id: record.id, label: record.label, hint: record.hint}
      end)
      |> indexed_records(:label_already_exists)

    duplicate_tuples =
      Enum.map(duplicate_results, fn {_label, {status, record}} -> {status, record} end)

    conflict_tuples =
      Enum.map(conflict_results, fn {_label, {status, record}} -> {status, record} end)

    clean_results ++ duplicate_tuples ++ conflict_tuples
  rescue
    error ->
      Logger.error("Error in update_authority_records: #{inspect(error)}")
      {:error, error}
  end

  defp do_update_authority_records(records) do
    ids = Enum.map(records, & &1.id)

    existing =
      from(ar in AuthorityRecord, where: ar.id in ^ids, select: {ar.id, ar})
      |> Repo.all()
      |> Enum.into(%{})

    records
    |> Enum.map(fn record ->
      %{id: id, label: label, hint: hint} = record

      case Map.get(existing, record.id) do
        nil ->
          {:not_found, record}

        %{id: ^id, label: ^label, hint: ^hint} ->
          {:unchanged, record}

        ar ->
          do_update_authority_record(ar, record)
      end
    end)
  end

  defp do_update_authority_record(existing_record, new_record) do
    case update_authority_record(existing_record, new_record) do
      {:ok, record} -> {:updated, record}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes an AuthorityRecord.
  """
  def delete_authority_record(%AuthorityRecord{} = authority_record) do
    Repo.delete(authority_record)
  end

  defp indexed_records({_, records}, status), do: indexed_records(records, status)

  defp indexed_records(records, status) do
    records
    |> Enum.map(fn record ->
      {record.label, {status, record}}
    end)
  end

  defp duplicate_labels(records) do
    records
    |> Enum.group_by(& &1.label)
    |> Enum.filter(fn {_label, entries} -> length(entries) > 1 end)
    |> Enum.map(fn {label, _entries} -> label end)
  end
end
