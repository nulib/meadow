defmodule Meadow.Repo.Migrations.CreateTranscriptionBench do
  use Ecto.Migration

  def change do
    create table(:transcription_bench_runs, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :string)
      add(:author, :string)
      add(:variants, {:array, :map}, null: false, default: [])
      add(:images, {:array, :map}, null: false, default: [])
      add(:models, {:array, :string}, null: false, default: [])
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:transcription_bench_runs, [:inserted_at]))

    create table(:transcription_bench_results, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :run_id,
        references(:transcription_bench_runs, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:position, :integer, null: false, default: 0)
      add(:attempt, :integer, null: false, default: 1)
      # No foreign key: a result outlives its file set, as a record of what was sent.
      add(:file_set_id, :uuid, null: false)
      add(:label, :string)
      add(:image_url, :text)
      add(:model, :string, null: false)
      add(:variant_id, :string, null: false)
      add(:status, :string, null: false, default: "queued")
      add(:error, :text)
      add(:started_at, :utc_datetime_usec)
      add(:duration_ms, :integer)
      add(:image_width, :integer)
      add(:image_height, :integer)
      add(:sent_width, :integer)
      add(:sent_height, :integer)
      add(:sent_bytes, :integer)
      # The size the model resized the image to, which its pixel boxes are read against.
      add(:processed_width, :integer)
      add(:processed_height, :integer)
      add(:stop_reason, :string)
      add(:usage, :map)
      add(:tool_input, :text)
      add(:text, :text)
      add(:reasoning, :text)
      add(:request, :map)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:transcription_bench_results, [:run_id]))
  end
end
