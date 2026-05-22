defmodule Meadow.Evals.Schemas.EvalPromptVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "eval_prompt_versions" do
    field(:name, :string)
    field(:system_prompt, :string)
    field(:user_prompt_template, :string)
    field(:subject_prompt, :string)
    field(:description_prompt, :string)
    field(:parent_version_id, Ecto.UUID)
    field(:author, :string)
    field(:change_notes, :string)
    field(:archived, :boolean, default: false)
    timestamps()
  end

  def changeset(prompt_version, attrs) do
    prompt_version
    |> cast(attrs, [
      :name,
      :system_prompt,
      :user_prompt_template,
      :subject_prompt,
      :description_prompt,
      :parent_version_id,
      :author,
      :change_notes,
      :archived
    ])
    |> validate_required([:name, :system_prompt, :user_prompt_template])
    |> foreign_key_constraint(:parent_version_id)
  end

  def archive(prompt_version) do
    prompt_version
    |> cast(%{archived: true}, [:archived])
  end
end
