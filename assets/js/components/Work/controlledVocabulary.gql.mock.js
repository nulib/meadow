import { CODE_LIST_QUERY } from "./controlledVocabulary.gql";

export const codeListAuthorityMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: {
      scheme: "AUTHORITY",
    },
  },
  result: {
    data: {
      codeList: [
        {
          id: "fast",
          label: "Faceted Application of Subject Terminology",
          __typename: "CodedTerm",
        },
        {
          id: "fast-corporate-name",
          label: "Faceted Application of Subject Terminology -- Corporate Name",
          __typename: "CodedTerm",
        },
      ],
    },
  },
};

export const codeListLicenseMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: { scheme: "LICENSE" },
  },
  result: {
    data: {
      codeList: [
        {
          __typename: "CodedTerm",
          id: "http://creativecommons.org/licenses/by-nc-sa/3.0/us/",
          label: "Attribution-NonCommercial-ShareAlike 3.0 United States",
        },
        {
          __typename: "CodedTerm",
          id: "http://www.europeana.eu/portal/rights/rr-r.html",
          label: "All rights reserved",
        },
        {
          __typename: "CodedTerm",
          id: "http://creativecommons.org/licenses/by/3.0/us/",
          label: "Attribution 3.0 United States",
        },
      ],
    },
  },
};

export const codeListMarcRelatorMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: {
      scheme: "MARC_RELATOR",
    },
  },
  result: {
    data: {
      codeList: [
        {
          id: "abr",
          label: "Abridger",
          __typename: "CodedTerm",
        },
        {
          id: "act",
          label: "Actor",
          __typename: "CodedTerm",
        },
        {
          id: "adp",
          label: "Adapter",
          __typename: "CodedTerm",
        },
      ],
    },
  },
};

export const codeListRightsStatementMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: { scheme: "RIGHTS_STATEMENT" },
  },
  result: {
    data: {
      codeList: [
        {
          id: "http://rightsstatements.org/vocab/InC/1.0/",
          label: "In Copyright",
          __typename: "CodedTerm",
        },
        {
          id: "http://rightsstatements.org/vocab/InC-OW-EU/1.0/",
          label: "In Copyright - EU Orphan Work",
          __typename: "CodedTerm",
        },
        {
          id: " http://rightsstatements.org/vocab/InC-EDU/1.0/",
          label: "In Copyright - Educational Use Permitted",
        },
      ],
    },
  },
};

export const codeListSubjectRoleMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: { scheme: "SUBJECT_ROLE" },
  },
  result: {
    data: {
      codeList: [
        {
          __typename: "CodedTerm",
          id: "GEOGRAPHICAL",
          label: "Geographical",
        },
        {
          __typename: "CodedTerm",
          id: "TOPICAL",
          label: "Topical",
        },
      ],
    },
  },
};
