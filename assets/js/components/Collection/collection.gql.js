import gql from "graphql-tag";
import Collection from "./Collection";

// Collection.fragments = {
//   parts: gql`
//     fragment CollectionParts on Collection {
//       adminEmail
//       featured
//       findingAidUrl
//       published
//       name
//       description
//       id
//       keywords
//       works {
//         id
//       }
//     }
//   `
// };

export const CREATE_COLLECTION = gql`
  mutation CreateCollection(
    $description: String
    $collectionName: String!
    $keywords: [String]
    $findingAidUrl: String
    $adminEmail: String
    $featured: Boolean
  ) {
    createCollection(
      description: $description
      name: $collectionName
      keywords: $keywords
      findingAidUrl: $findingAidUrl
      adminEmail: $adminEmail
      featured: $featured
    ) {
      id
      description
      name
      keywords
      findingAidUrl
      adminEmail
      featured
    }
  }
`;

export const SET_COLLECTION_IMAGE = gql`
  mutation SetCollectionImage($collectionId: ID!, $workId: ID!) {
    setCollectionImage(collectionId: $collectionId, workId: $workId) {
      id
      representativeWork {
        id
        representativeImage
      }
    }
  }
`;

export const DELETE_COLLECTION = gql`
  mutation DeleteCollection($collectionId: ID!) {
    deleteCollection(collectionId: $collectionId) {
      id
      name
    }
  }
`;

// export const GET_COLLECTION = gql`
//   query GetCollection($id: ID!) {
//     collection(collectionId: $id) {
//       ...CollectionParts
//     }
//   }
//   ${Collection.fragments.parts}
// `;
export const GET_COLLECTION = gql`
  query GetCollection($id: ID!) {
    collection(collectionId: $id) {
      adminEmail
      featured
      findingAidUrl
      published
      name
      description
      representativeWork {
        id
        representativeImage
      }
      id
      keywords
      works {
        id
        representativeImage
        descriptiveMetadata {
          title
        }
      }
    }
  }
`;

// export const GET_COLLECTIONS = gql`
//   query GetCollections {
//     collections {
//       ...CollectionParts
//     }
//   }
//   ${Collection.fragments.parts}
// `;
export const GET_COLLECTIONS = gql`
  query GetCollections {
    collections {
      adminEmail
      featured
      findingAidUrl
      published
      name
      description
      id
      keywords
      representativeWork {
        id
        representativeImage
      }
      works {
        id
        representativeImage
        descriptiveMetadata {
          title
        }
      }
    }
  }
`;

export const UPDATE_COLLECTION = gql`
  mutation UpdateCollection(
    $collectionId: ID!
    $description: String
    $collectionName: String!
    $keywords: [String]
    $findingAidUrl: String
    $adminEmail: String
    $featured: Boolean
  ) {
    updateCollection(
      collectionId: $collectionId
      description: $description
      name: $collectionName
      keywords: $keywords
      findingAidUrl: $findingAidUrl
      adminEmail: $adminEmail
      featured: $featured
    ) {
      id
      description
      name
      keywords
      findingAidUrl
      adminEmail
      featured
    }
  }
`;
