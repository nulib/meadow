import { CODE_LIST_QUERY } from "./controlledVocabulary.gql";
import { makeReference } from "@apollo/client";

export const marcRelatorMock = [
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
];

export const authorityMock = [
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
];

export const subjectMock = [
  {
    id: "GEOGRAPHICAL",
    label: "Geographical",
    __typename: "CodedTerm",
  },
  {
    id: "TOPICAL",
    label: "Topical",
    __typename: "CodedTerm",
  },
];

export const codeListAuthorityMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: {
      scheme: "AUTHORITY",
    },
  },
  result: {
    data: {
      codeList: authorityMock,
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
      codeList: marcRelatorMock,
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
      codeList: subjectMock,
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
          id: "http://creativecommons.org/licenses/by-nc-sa/3.0/us/",
          label: "Attribution-NonCommercial-ShareAlike 3.0 United States",
          __typename: "CodedTerm",
        },
        {
          id: "http://www.europeana.eu/portal/rights/rr-r.html",
          label: "All rights reserved",
          __typename: "CodedTerm",
        },
        {
          id: "http://creativecommons.org/licenses/by/3.0/us/",
          label: "Attribution 3.0 United States",
          __typename: "CodedTerm",
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
          __typename: "CodedTerm",
        },
        {
          id: "2",
          label: "Level 2",
          __typename: "CodedTerm",
        },
        {
          id: "3",
          label: "Level 3",
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
          __typename: "CodedTerm",
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
          __typename: "CodedTerm",
        },
        {
          id: "IN PROGRESS",
          label: "In Progresss",
          __typename: "CodedTerm",
        },
        {
          id: "STARTED",
          label: "Started",
          __typename: "CodedTerm",
        },
      ],
    },
  },
};

export const codeListRelatedUrlMock = {
  request: {
    query: CODE_LIST_QUERY,
    variables: { scheme: "RELATED_URL" },
  },
  result: {
    data: {
      codeList: [
        {
          id: "FINDING_AID",
          label: "Finding Aid",
        },
        {
          id: "HATHI_TRUST_DIGITAL_LIBRARY",
          label: "Hathi Trust Digital Library",
        },
        {
          id: "RELATED_INFORMATION",
          label: "Related Information",
        },
        {
          id: "RESEARCH_GUIDE",
          label: "Research Guide",
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
          id: "GEOGRAPHICAL",
          label: "Geographical",
          __typename: "CodedTerm",
        },
        {
          id: "TOPICAL",
          label: "Topical",
          __typename: "CodedTerm",
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
          __typename: "CodedTerm",
        },
        {
          id: "RESTRICTED",
          label: "Private",
          __typename: "CodedTerm",
        },
        {
          id: "OPEN",
          label: "Public",
          __typename: "CodedTerm",
        },
      ],
    },
  },
};
