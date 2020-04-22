import gql from "graphql-tag";
import faker from "faker";

export const typeDefs = gql`
  extend type Work {
    foo: String!
  }
`;

export const resolvers = {
  Work: {
    foo: () => "An additional client side property"
  },
  WorkDescriptiveMetadata: {
    genre: () => mockControlledVocabulary(),
    location: () => mockControlledVocabulary(),
    language: () => mockControlledVocabulary(),
    stylePeriod: () => mockControlledVocabulary(),
    technique: () => mockControlledVocabulary()
  }
};

export const mockControlledVocabulary = () => {
  let results = [];
  let size = Math.floor(Math.random() * Math.floor(4));
  for (let i = 0; i < size; i++) {
    results.push({
      id: faker.internet.url(),
      label: faker.lorem.words(),
      __typename: "ControlledVocabulary"
    });
  }
  return results;
};
