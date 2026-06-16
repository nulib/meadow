import { gql } from "@apollo/client/core";

export const DIGITAL_COLLECTIONS_URL = gql`
  query DigitalCollectionsUrl {
    digitalCollectionsUrl {
      url
    }
  }
`;

export const GET_DCAPI_ENDPOINT = gql`
  query DcapiEndpoint {
    dcapiEndpoint {
      url
    }
  }
`;

export const LIVEBOOK_URL = gql`
  query LivebookUrl {
    livebookUrl {
      url
    }
  }
`;
