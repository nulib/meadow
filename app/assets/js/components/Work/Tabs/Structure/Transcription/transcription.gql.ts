import { gql } from "@apollo/client/core";

export const FILE_SET_ANNOTATION = gql`
  subscription fileSetAnnotation($fileSetId: ID!) {
    fileSetAnnotation(fileSetId: $fileSetId) {
      content
      fileSetId
      id
      insertedAt
      language
      model
      s3Location
      status
      error
      type
      updatedAt
      aiProvenance {
        origin
        status
        model
        reviewer
        reviewedAt
        generatedAt
      }
    }
  }
`;

export const WORK_FILE_SET_ANNOTATION = gql`
  subscription workFileSetAnnotation($workId: ID!) {
    workFileSetAnnotation(workId: $workId) {
      status
      fileSetId
    }
  }
`;

export const TRANSCRIBE_FILE_SET = gql`
  mutation transcribeFileSet(
    $fileSetId: ID!
    $language: [String]
    $model: String
    $context: String
  ) {
    transcribeFileSet(
      fileSetId: $fileSetId
      language: $language
      model: $model
      context: $context
    ) {
      id
      status
    }
  }
`;

export const UPDATE_FILE_SET_ANNOTATION = gql`
  mutation updateFileSetAnnotation($annotationId: ID!, $content: String!) {
    updateFileSetAnnotation(annotationId: $annotationId, content: $content) {
      content
      fileSetId
      id
      insertedAt
      language
      model
      s3Location
      status
      type
      updatedAt
      aiProvenance {
        origin
        status
        model
        reviewer
        reviewedAt
        generatedAt
      }
    }
  }
`;

export const UPSERT_FILE_SET_ANNOTATION = gql`
  mutation upsertFileSetAnnotation(
    $fileSetId: ID!
    $type: String!
    $content: String!
    $language: [String]
  ) {
    upsertFileSetAnnotation(
      fileSetId: $fileSetId
      type: $type
      content: $content
      language: $language
    ) {
      content
      fileSetId
      id
      insertedAt
      language
      model
      s3Location
      status
      type
      updatedAt
      aiProvenance {
        origin
        status
        model
        reviewer
        reviewedAt
        generatedAt
      }
    }
  }
`;

export const DELETE_FILE_SET_ANNOTATION = gql`
  mutation deleteFileSetAnnotation($annotationId: ID!) {
    deleteFileSetAnnotation(annotationId: $annotationId) {
      id
      fileSetId
    }
  }
`;

export const ATTEST_HUMAN_AUTHORED_ANNOTATION = gql`
  mutation AttestHumanAuthoredAnnotation($annotationId: ID!, $reason: String) {
    attestHumanAuthoredAnnotation(
      annotationId: $annotationId
      reason: $reason
    ) {
      id
      fileSetId
      aiProvenance {
        origin
        status
      }
    }
  }
`;
