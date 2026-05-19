import gql from "graphql-tag";

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
      id
      fileSetId
      type
      language
      status
      content
      insertedAt
      updatedAt
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
