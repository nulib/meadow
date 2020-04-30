import gql from "graphql-tag";
import faker from "faker";

export const typeDefs = gql`
  extend type Work {
    foo: String!
  }
`;

export const resolvers = {
  Work: {
    foo: () => "An additional client side property",
  },
  WorkDescriptiveMetadata: {
    contributor: () => mockContributors(),
    creator: () => mockControlledVocabulary(),
    genre: () => mockControlledVocabulary(),
    location: () => mockControlledVocabulary(),
    language: () => mockControlledVocabulary(),
    stylePeriod: () => mockControlledVocabulary(),
    subject: () => mockSubjects(),
    technique: () => mockControlledVocabulary(),
  },
};

export const mockControlledVocabulary = () => {
  let results = [];
  let size = Math.floor(Math.random() * Math.floor(4));
  for (let i = 0; i < size; i++) {
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      role: null,
      __typename: "ControlledVocabulary",
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
        __typename: "CodeListItem",
      },
      __typename: "ControlledVocabulary",
    });
  }
  return results;
};

export const mockSubjects = () => {
  let ids = ["topcial", "temporal", "geographical"];
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
        __typename: "CodeListItem",
      },
      __typename: "ControlledVocabulary",
    });
  }
  return results;
};
