import gql from "graphql-tag";

export const GET_COLLECTIONS = gql`
  query GetCollections {
    collections {
      id
      description
      keywords
      name
    }
  }
`;
