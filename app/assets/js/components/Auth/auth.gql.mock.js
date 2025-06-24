import { GET_CURRENT_USER_QUERY, LIST_ROLES_QUERY, LIST_USERS_QUERY, SET_USER_ROLE_MUTATION } from "./auth.gql";

export const mockUser = {
  username: "nutest",
  email: "rdctech@northwestern.edu",
  role: "ADMINISTRATOR",
  displayName: "NU Test",
};

export const mockViewer = {
  username: "nutest",
  email: "rdctech@northwestern.edu",
  role: "USER",
  displayName: "NU Test",
};

export const mockSuperuser = {
  username: "supernutest",
  email: "superrdctech@northwestern.edu",
  role: "SUPERUSER",
  displayName: "Super NU Test",
}

export const getCurrentUserMock = {
  request: {
    query: GET_CURRENT_USER_QUERY,
  },
  result: {
    data: {
      me: mockUser,
    },
  },
};

export const getViewerMock = {
  request: {
    query: GET_CURRENT_USER_QUERY,
  },
  result: {
    data: {
      me: mockViewer,
    },
  },
};

export const listUsersMock = {
  request: {
    query: LIST_USERS_QUERY,
  },
  result: {
    data: {
      users: [mockUser, mockSuperuser],
    },
  },
}

export const setUserRoleMock = {
  request: {
    query: SET_USER_ROLE_MUTATION,
    variables: {
      userId: mockViewer.username,
      userRole: "ADMINISTRATOR",
    },
  },
  result: {
    data: {
      setUserRole: {
        message:
          `User role updated successfully for ${mockViewer.username} to administrator`,
      },
    },
  },
};

export const listRolesMock = {
  request: {
    query: LIST_ROLES_QUERY,
  },
  result: {
    data: {
      roles: [
        "Superuser",
        "Administrator",
        "Manager",
        "Editor",
        "User"
      ],
    },
  },
}