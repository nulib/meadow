import gql from "graphql-tag";

export const DIGITAL_COLLECTIONS_URL = gql`
  query DigitalCollectionsUrl {
    digitalCollectionsUrl {
      url
    }
  }
`;
