import { ASSUME_ROLE } from "./role.gql";

export const mockMessage = "Role changed to: User";

export const digitalCollectionsUrlMock = {
  request: {
    query: ASSUME_ROLE,
    variables: { userRole: "USER" },
  },
  result: {
    data: {
      assumeRole: {
        message: mockMessage,
      },
    },
  },
};
