import { gql } from "@apollo/client";

export const BATCH_UPDATE = gql`
  mutation BatchUpdate(
    $add: BatchAddInput
    $delete: BatchDeleteInput
    $query: String!
  ) {
    batchUpdate(add: $add, delete: $delete, query: $query) {
      message
    }
  }
`;
