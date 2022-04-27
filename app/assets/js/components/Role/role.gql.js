import gql from "graphql-tag";

export const ASSUME_ROLE = gql`
  mutation AssumeRole($userRole: UserRole!) {
    assumeRole(userRole: $userRole) {
      message
    }
  }
`;
