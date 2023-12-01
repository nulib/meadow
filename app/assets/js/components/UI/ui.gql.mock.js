import { GET_DCAPI_ENDPOINT, DIGITAL_COLLECTIONS_URL } from "./ui.gql";

export const mockDCUrl = "https://imamockurl.io/";
export const dcapiEndpointUrl =
  "https://prefix.dev.rdc.library.northwestern.edu/";

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

export const dcApiEndpointMock = {
  request: {
    query: GET_DCAPI_ENDPOINT,
  },
  result: {
    data: {
      dcapiEndpoint: {
        url: dcapiEndpointUrl,
      },
    },
  },
};
