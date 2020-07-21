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
        },
        {
          id: "act",
          label: "Actor",
        },
        {
          id: "adp",
          label: "Adapter",
        },
      ],
    },
  },
};

export const codeListPreservationLevelMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: {
      scheme: "PRESERVATION_LEVEL",
    },
  },
  result: {
    data: {
      codeList: [
        {
          id: "1",
          label: "Level 1",
        },
        {
          id: "2",
          label: "Level 2",
        },
        {
          id: "3",
          label: "Level 3",
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

export const codeListStatusMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: { scheme: "STATUS" },
  },
  result: {
    data: {
      codeList: [
        {
          id: "DONE",
          label: "Done",
        },
        {
          id: "IN PROGRESS",
          label: "In Progresss",
        },
        {
          id: "STARTED",
          label: "Started",
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

export const codeListVisibilityMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: { scheme: "VISIBILITY" },
  },
  result: {
    data: {
      codeList: [
        {
          id: "AUTHENTICATED",
          label: "Institution",
        },
        {
          id: "RESTRICTED",
          label: "Private",
        },
        {
          id: "OPEN",
          label: "Public",
        },
      ],
    },
  },
};
