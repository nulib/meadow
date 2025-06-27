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

export const LIST_ROLES_QUERY = gql`
  query ListRoles {
    roles
  }
`;

export const LIST_USERS_QUERY = gql`
  query ListUsers {
    users {
      username
      email
      role
      displayName
    }
  }
`;

export const SET_USER_ROLE_MUTATION = gql`
  mutation SetUserRole($userId: ID!, $userRole: UserRole) {
    setUserRole(userId: $userId, userRole: $userRole) {
      message
    }
  }
`;
