import gql from "graphql-tag";

export const GET_BATCHES = gql`
  query batches {
    batches {
      add
      delete
      error
      id
      nickname
      query
      replace
      started
      status
      type
      user
      worksUpdated
    }
  }
`;
