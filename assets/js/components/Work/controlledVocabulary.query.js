import gql from "graphql-tag";

export const CODED_TERM_QUERY = gql`
  query CodedTermQuery($id: ID!) {
    codedTerm(id: $id) {
      label
    }
  }
`;

export const CODE_LIST_QUERY = gql`
  query CodeListQuery($scheme: CodeListScheme!) {
    codeList(scheme: $scheme) @client {
      id
      label
    }
  }
`;
