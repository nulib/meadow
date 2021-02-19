import { DIGITAL_COLLECTIONS_URL } from "./ui.gql";

export const mockDCUrl = "https://imamockurl.io/";

export const digitalCollectionsUrlMock = {
  request: {
    query: DIGITAL_COLLECTIONS_URL,
  },
  result: {
    data: {
      digitalCollectionsUrl: {
        url: mockDCUrl,
      },
    },
  },
};
