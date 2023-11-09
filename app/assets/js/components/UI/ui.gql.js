import gql from "graphql-tag";

export const DIGITAL_COLLECTIONS_URL = gql`
  query DigitalCollectionsUrl {
    digitalCollectionsUrl {
      url
    }
  }
`;

export const GET_DCAPI_ENDPOINT = gql`
  query {
    dcapiEndpoint {
      url
    }
  }
`;
