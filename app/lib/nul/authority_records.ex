defmodule NUL.AuthorityRecords do
  @moduledoc """
  The NUL.AuthorityRecords context.
  """

  alias Meadow.Repo
  alias NUL.Schemas.AuthorityRecord

  import Ecto.Query

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
  Deletes an AuthorityRecord.
  """
  def delete_authority_record(%AuthorityRecord{} = authority_record) do
    Repo.delete(authority_record)
  end
end
