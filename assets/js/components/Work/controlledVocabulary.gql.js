import gql from "graphql-tag";

export const AUTHORITIES_SEARCH = gql`
  query AuthoritiesSearch($authority: ID!, $query: String!) {
    authoritiesSearch(authority: $authority, query: $query) {
      hint
      id
      label
    }
  }
`;

export const CODE_LIST_QUERY = gql`
  query CodeListQuery($scheme: CodeListScheme!) {
    codeList(scheme: $scheme) {
      id
      label
    }
  }
`;

export const FETCH_CODED_TERM_QUERY = gql`
  query FetchCodedTermLabelQuery($id: ID!, $scheme: CodeListScheme!) {
    fetchCodedTermLabel(id: $id, scheme: $scheme) {
      label
    }
  }
`;

export const FETCH_CONTROLLED_TERM_QUERY = gql`
  query FetchControlledTermLabel($id: ID!) {
    fetchControlledTermLabel(id: $id) {
      label
    }
  }
`;
