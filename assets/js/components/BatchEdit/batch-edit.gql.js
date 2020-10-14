import { gql } from "@apollo/client";

export const BATCH_UPDATE = gql`
  mutation BatchUpdate(
    $add: BatchAddInput
    $delete: BatchDeleteInput
    $query: String!
    $replace: BatchReplaceInput
  ) {
    batchUpdate(add: $add, delete: $delete, query: $query, replace: $replace) {
      message
    }
  }
`;
