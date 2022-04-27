import gql from "graphql-tag";
import faker from "faker";

export const typeDefs = gql`
  extend type Work {
    foo: String!
  }

  extend type Mutation {
    updateFileSets(fileSets: [FileSet]): String
  }
`;

export const resolvers = {
  Work: {
    foo: () => "An additional client-side only property on the work object",
    visibility: () => mockVisibility(),
    workType: () => mockWorkType(),
  },
  WorkDescriptiveMetadata: {
    license: () => mockLicense(),
    rightsStatement: () => mockRightsStatement(),
  },
  WorkAdministrativeMetadata: {
    preservationLevel: () => mockPreservationLevel(),
    status: () => mockStatus(),
  },
  Query: {
    // authoritiesSearch: (root, { _authority, _query }) =>
    //   mockAuthoritiesSearch(),
    fetchControlledTermLabel: (root, { _id }) =>
      mockLabelFetch("ControlledValue"),
    fetchCodedTermLabel: () => mockLabelFetch("CodedTerm"),
  },
  Mutation: {
    updateFileSets: () => "Return message or id of individually updated item",
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
      label: faker.name.findName(),
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
  let ids = ["topicial", "geographical"];
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
  let size = Math.floor(Math.random() * Math.floor(10));
  for (let i = 0; i < size; i++) {
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      hint: faker.lorem.words(),
      __typename: "ControlledValue",
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
    label: "In Progress",
    __typename: "CodedTerm",
  };
};

export const mockVisibility = () => {
  return {
    label: "Institution",
    id: "AUTHENTICATED",
    __typename: "CodedTerm",
  };
};

export const mockWorkType = () => {
  return {
    id: "IMAGE",
    label: "Image",
    __typename: "CodedTerm",
  };
};
