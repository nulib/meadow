import { gql } from "@apollo/client";

const RUN_SUMMARY = gql`
  fragment TranscriptionBenchRunSummary on TranscriptionBenchRun {
    id
    name
    author
    insertedAt
    variants
    images
    models
    total
    done
    failed
    cancelled
    active
  }
`;

export const GET_TRANSCRIBABLE_FILE_SETS = gql`
  query TranscribableFileSets(
    $limit: Int
    $offset: Int
    $collectionId: ID
    $work: String
  ) {
    transcribableFileSets(
      limit: $limit
      offset: $offset
      collectionId: $collectionId
      work: $work
    ) {
      total
      fileSets {
        id
        accessionNumber
        label
        representativeImageUrl
        workId
        workTitle
        workAccessionNumber
        collectionId
        collectionTitle
      }
    }
  }
`;

export const GET_TRANSCRIPTION_BENCH_MODELS = gql`
  query TranscriptionBenchModels {
    transcriptionBenchModels {
      id
      label
    }
  }
`;

export const GET_TRANSCRIPTION_BENCH_RUNS = gql`
  query TranscriptionBenchRuns($limit: Int, $offset: Int) {
    transcriptionBenchRuns(limit: $limit, offset: $offset) {
      ...TranscriptionBenchRunSummary
    }
  }
  ${RUN_SUMMARY}
`;

export const GET_TRANSCRIPTION_BENCH_RUN = gql`
  query TranscriptionBenchRun($id: ID!) {
    transcriptionBenchRun(id: $id) {
      ...TranscriptionBenchRunSummary
      results {
        id
        attempt
        fileSetId
        label
        imageUrl
        model
        variantId
        status
        error
        startedAt
        durationMs
        imageWidth
        imageHeight
        sentWidth
        sentHeight
        sentBytes
        processedWidth
        processedHeight
        stopReason
        usage
        toolInput
        text
        reasoning
        request
        parsed
      }
    }
  }
  ${RUN_SUMMARY}
`;

export const START_TRANSCRIPTION_BENCH_RUN = gql`
  mutation StartTranscriptionBenchRun(
    $name: String
    $fileSetIds: [ID!]!
    $models: [String!]!
    $variants: Json!
  ) {
    startTranscriptionBenchRun(
      name: $name
      fileSetIds: $fileSetIds
      models: $models
      variants: $variants
    ) {
      id
    }
  }
`;

export const RETRY_TRANSCRIPTION_BENCH_RESULT = gql`
  mutation RetryTranscriptionBenchResult($id: ID!) {
    retryTranscriptionBenchResult(id: $id) {
      id
      active
    }
  }
`;

export const CANCEL_TRANSCRIPTION_BENCH_RESULT = gql`
  mutation CancelTranscriptionBenchResult($id: ID!) {
    cancelTranscriptionBenchResult(id: $id) {
      id
      active
    }
  }
`;

export const CANCEL_TRANSCRIPTION_BENCH_RUN = gql`
  mutation CancelTranscriptionBenchRun($id: ID!) {
    cancelTranscriptionBenchRun(id: $id) {
      id
      active
    }
  }
`;

export const DELETE_TRANSCRIPTION_BENCH_RUN = gql`
  mutation DeleteTranscriptionBenchRun($id: ID!) {
    deleteTranscriptionBenchRun(id: $id) {
      id
    }
  }
`;
