import gql from "graphql-tag";

export const GET_BATCH = gql`
  query batch($id: ID!) {
    batch(id: $id) {
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
