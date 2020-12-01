import { GET_CURRENT_USER_QUERY } from "./auth.gql";
export const mockUser = {
  username: "nutest",
  email: "rdctech@northwestern.edu",
  role: "ADMINISTRATOR",
  displayName: "NU Test",
};

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
