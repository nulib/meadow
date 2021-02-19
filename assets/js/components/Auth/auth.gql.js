import gql from "graphql-tag";

export const GET_CURRENT_USER_QUERY = gql`
  query GetCurrentUser {
    me {
      username
      email
      role
      displayName
    }
  }
`;
