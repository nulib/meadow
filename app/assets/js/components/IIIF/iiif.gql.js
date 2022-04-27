import gql from "graphql-tag";

export const IIIF_SERVER_URL = gql`
  query IiifServerUrl {
    iiifServerUrl {
      url
    }
  }
`;
