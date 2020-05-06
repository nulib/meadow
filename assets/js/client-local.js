import gql from "graphql-tag";
import faker from "faker";
import { codeListMock } from "./client-mocks";

export const typeDefs = gql`
  extend type Work {
    foo: String!
  }
`;

export const resolvers = {
  Work: {
    foo: () => "An additional client-side only property on the work object",
    visibility: () => mockVisibility(),
    workType: () => mockWorkType(),
  },
  WorkDescriptiveMetadata: {
    contributor: () => mockContributors(),
    creator: () => mockControlledTerm(),
    genre: () => mockControlledTerm(),
    license: () => mockLicense(),
    location: () => mockControlledTerm(),
    language: () => mockControlledTerm(),
    rightsStatement: () => mockRightsStatement(),
    stylePeriod: () => mockControlledTerm(),
    subject: () => mockSubjects(),
    technique: () => mockControlledTerm(),
  },
  WorkAdministrativeMetadata: {
    preservationLevel: () => mockPreservationLevel(),
    status: () => mockStatus(),
  },
  Query: {
    codeList: (root, { scheme }) => codeListMock(scheme),
    authoritiesSearch: (root, { _authority, _query }) =>
      mockAuthoritiesSearch(),
    fetchControlledTermLabel: (root, { _id }) =>
      mockLabelFetch("ControlledTerm"),
    fetchCodedTermLabel: () => mockLabelFetch("CodedTerm"),
  },
};

export const mockControlledTerm = () => {
  let results = [];
  let size = Math.floor(Math.random() * Math.floor(4));
  for (let i = 0; i < size; i++) {
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      role: null,
      __typename: "ControlledTerm",
    });
  }
  return results;
};

export const mockContributors = () => {
  let results = [];
  let size = Math.floor(Math.random() * Math.floor(4));
  for (let i = 0; i < size; i++) {
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      role: {
        id: "aut",
        label: "Author",
        scheme: "MARC_RELATOR",
        __typename: "CodedTerm",
      },
      __typename: "ControlledTerm",
    });
  }
  return results;
};

export const mockSubjects = () => {
  let ids = ["topicial", "temporal", "geographical"];
  let results = [];
  let size = Math.floor(Math.random() * Math.floor(4));
  for (let i = 0; i < size; i++) {
    let random_subject = ids[Math.floor(Math.random() * ids.length)];
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      role: {
        id: random_subject,
        label: random_subject,
        scheme: "SUBJECT",
        __typename: "CodedTerm",
      },
      __typename: "ControlledTerm",
    });
  }
  return results;
};

export const mockAuthoritiesSearch = () => {
  let results = [];
  let size = Math.floor(Math.random() * Math.floor(4));
  for (let i = 0; i < size; i++) {
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      role: null,
      __typename: "CodedTerm",
    });
  }
  return results;
};

export const mockLabelFetch = (typename) => {
  return {
    id: faker.internet.url(),
    label: faker.lorem.words(),
    __typename: typename,
  };
};

const mockRightsStatement = () => {
  return {
    id: "http://rightsstatements.org/vocab/InC/1.0/",
    label: "In Copyright",
    __typename: "CodedTerm",
  };
};

const mockPreservationLevel = () => {
  return {
    id: "1",
    label: "Level 1",
    __typename: "CodedTerm",
  };
};

const mockLicense = () => {
  return {
    id: "https://creativecommons.org/licenses/by-nc/4.0/",
    label: "Attribution-NonCommercial 4.0 International",
    __typename: "CodedTerm",
  };
};

const mockStatus = () => {
  return {
    id: "IN PROGRESS",
    label: "In Progresss",
    __typename: "CodedTerm",
  };
};

const mockVisibility = () => {
  return {
    label: "Institution",
    id: "AUTHENTICATED",
    __typename: "CodedTerm",
  };
};

const mockWorkType = () => {
  return {
    id: "IMAGE",
    label: "Image",
    __typename: "CodedTerm",
  };
};
