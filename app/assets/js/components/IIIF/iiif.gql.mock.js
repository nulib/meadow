import { IIIF_SERVER_URL } from "./iiif.gql";

export const iiifServerUrlMock = {
  request: {
    query: IIIF_SERVER_URL,
  },
  result: {
    data: {
      iiifServerUrl: {
        url: "http://localhost:8184/iiif/2/",
      },
    },
  },
};
