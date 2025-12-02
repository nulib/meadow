import gql from "graphql-tag";

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
      type
      updatedAt
    }
  }
`;

export const WORK_FILE_SET_ANNOTATION = gql`
  subscription workFileSetAnnotation($workId: ID!) {
    workFileSetAnnotation(workId: $workId) {
      fileSetAnnotation {
        status
        fileSetId
      }
    }
  }
`;

export const TRANSCRIBE_FILE_SET = gql`
  mutation transcribeFileSet(
    $fileSetId: ID!
    $language: [String]
    $model: String
  ) {
    transcribeFileSet(
      fileSetId: $fileSetId
      language: $language
      model: $model
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
    }
  }
`;
