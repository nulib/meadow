defmodule Meadow.Ingest.Schemas.Project do
  @moduledoc """
  This modeule defines the Ecto.Schema
  and Ecto.Changeset for Meadow.Ingest.Schemas.Project

  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "projects" do
    field :title, :string
    field :folder, :string

    has_many :ingest_sheets, Meadow.Ingest.Schemas.Sheet

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    required_fields = [:title]
    optional_fields = []

    project
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> validate_length(:title, min: 4, max: 140)
    |> unique_constraint(:title)
  end

  @doc false
  def changeset(project, :create, attrs) do
    project
    |> changeset(attrs)
    |> generate_folder_name()
  end

  @doc false
  def changeset(project, :update, attrs) do
    changeset(project, attrs)
  end

  defp generate_folder_name(changeset) do
    case changeset.valid? do
      true ->
        title = changeset |> get_field(:title) |> slugify()
        put_change(changeset, :folder, title)

      _ ->
        changeset
    end
  end

  defp slugify(title) do
    unique_ending = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/(\s|-)+/, "-")
    |> Kernel.<>("-")
    |> Kernel.<>(unique_ending)
  end
end
