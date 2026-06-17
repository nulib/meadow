import { gql } from "@apollo/client/core";

export const ASSUME_ROLE = gql`
  mutation AssumeRole($userRole: UserRole!) {
    assumeRole(userRole: $userRole) {
      message
    }
  }
`;
