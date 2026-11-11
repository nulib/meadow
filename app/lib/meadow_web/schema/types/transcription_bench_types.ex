defmodule MeadowWeb.Schema.TranscriptionBenchTypes do
  @moduledoc "Absinthe types, queries and mutations for the transcription bench."

  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.TranscriptionBench
  alias MeadowWeb.Schema.Middleware

  @desc "A file set a transcription can be made of: an access file that is an image"
  object :transcribable_file_set do
    field(:id, non_null(:id))
    field(:accession_number, :string)
    field(:label, :string)
    field(:representative_image_url, :string)
    field(:work_id, :id)
    field(:work_title, :string)
    field(:work_accession_number, :string)
    field(:collection_id, :id)
    field(:collection_title, :string)
  end

  object :transcribable_file_set_page do
    field(:total, non_null(:integer))
    field(:file_sets, non_null(list_of(non_null(:transcribable_file_set))))
  end

  object :transcription_bench_model do
    field(:id, non_null(:string))
    field(:label, non_null(:string))
  end

  @desc "One file set sent to one model with one variant"
  object :transcription_bench_result do
    field(:id, non_null(:id))
    @desc "Counts up each time the result is run again"
    field(:attempt, non_null(:integer))
    field(:file_set_id, non_null(:id))
    field(:label, :string)
    @desc "The file set's IIIF Image API URL"
    field(:image_url, :string)
    field(:model, non_null(:string))
    field(:variant_id, non_null(:string))
    @desc "queued, running, done, error or cancelled"
    field(:status, non_null(:string))
    field(:error, :string)
    field(:started_at, :datetime)
    field(:duration_ms, :integer)
    field(:image_width, :integer)
    field(:image_height, :integer)
    field(:sent_width, :integer)
    field(:sent_height, :integer)
    field(:sent_bytes, :integer)
    @desc "The size the model resized the image to, which its pixel boxes are read against"
    field(:processed_width, :integer)
    field(:processed_height, :integer)
    field(:stop_reason, :string)
    field(:usage, :json)
    field(:tool_input, :string)
    field(:text, :string)
    field(:reasoning, :string)
    @desc "The Converse request, without the image's bytes"
    field(:request, :json)
    @desc "The output read into text and regions"
    field(:parsed, :json)
  end

  object :transcription_bench_run do
    field(:id, non_null(:id))
    field(:name, :string)
    field(:author, :string)
    field(:inserted_at, :datetime)
    @desc "The variants as they were when the run started"
    field(:variants, :json)
    @desc "The file sets of the run, as fileSetId and label"
    field(:images, :json)
    field(:models, list_of(:string))
    field(:total, non_null(:integer))
    field(:done, non_null(:integer))
    field(:failed, non_null(:integer))
    field(:cancelled, non_null(:integer))
    field(:active, non_null(:integer))

    field :results, list_of(:transcription_bench_result) do
      resolve(fn
        %{results: results}, _, _ when is_list(results) -> {:ok, results}
        _, _, _ -> {:ok, nil}
      end)
    end
  end

  object :transcription_bench_queries do
    @desc "A page of the file sets that can be transcribed"
    field :transcribable_file_sets, :transcribable_file_set_page do
      arg(:limit, :integer, default_value: 10)
      arg(:offset, :integer, default_value: 0)
      arg(:collection_id, :id)
      @desc "A work's id or accession number, or text in its title"
      arg(:work, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.transcribable_file_sets/3)
    end

    @desc "The Bedrock models a bench run can be sent to"
    field :transcription_bench_models, list_of(:transcription_bench_model) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.models/3)
    end

    @desc "Transcription bench runs, newest first, without their results"
    field :transcription_bench_runs, list_of(:transcription_bench_run) do
      arg(:limit, :integer)
      arg(:offset, :integer)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.list_runs/3)
    end

    @desc "A transcription bench run with its results"
    field :transcription_bench_run, :transcription_bench_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.get_run/3)
    end
  end

  object :transcription_bench_mutations do
    @desc "Transcribe every file set with every model and variant (10 at most)"
    field :start_transcription_bench_run, :transcription_bench_run do
      arg(:name, :string)
      arg(:file_set_ids, non_null(list_of(non_null(:id))))
      arg(:models, non_null(list_of(non_null(:string))))
      @desc "A JSON array of variants"
      arg(:variants, non_null(:json))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.start_run/3)
    end

    @desc "Run one finished result again"
    field :retry_transcription_bench_result, :transcription_bench_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.retry_result/3)
    end

    @desc "Cancel one result that is queued or transcribing"
    field :cancel_transcription_bench_result, :transcription_bench_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.cancel_result/3)
    end

    @desc "Cancel everything in a run that is queued or transcribing"
    field :cancel_transcription_bench_run, :transcription_bench_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.cancel_run/3)
    end

    @desc "Delete a run that is not transcribing"
    field :delete_transcription_bench_run, :transcription_bench_run do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&TranscriptionBench.delete_run/3)
    end
  end
end
