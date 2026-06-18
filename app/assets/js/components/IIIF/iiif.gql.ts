import { gql } from "@apollo/client/core";

export const IIIF_SERVER_URL = gql`
  query IiifServerUrl {
    iiifServerUrl {
      url
    }
  }
`;
