import { gql } from "@apollo/client";

export const BATCH_UPDATE = gql`
  mutation BatchUpdate(
    $add: BatchAddInput
    $delete: BatchDeleteInput
    $query: String!
    $replace: BatchReplaceInput
    $nickname: String
  ) {
    batchUpdate(
      add: $add
      delete: $delete
      query: $query
      replace: $replace
      nickname: $nickname
    ) {
      id
      nickname
      status
      user
      started
      type
      query
      add
      replace
      delete
      error
    }
  }
`;
