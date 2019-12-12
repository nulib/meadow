import gql from "graphql-tag";
import Collection from "./Collection";

Collection.fragments = {
  parts: gql`
    fragment CollectionParts on Collection {
      id
      description
      keywords
      name
    }
  `
};

export const GET_COLLECTION = gql`
  query GetCollection($id: ID!) {
    collection(collectionId: $id) {
      ...CollectionParts
    }
  }
  ${Collection.fragments.parts}
`;

export const GET_COLLECTIONS = gql`
  query GetCollections {
    collections {
      ...CollectionParts
    }
  }
  ${Collection.fragments.parts}
`;
