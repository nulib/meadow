import gql from "graphql-tag";
import Collection from "./Collection";

// Collection.fragments = {
//   parts: gql`
//     fragment CollectionParts on Collection {
//       adminEmail
//       featured
//       findingAidUrl
//       published
//       title
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
    $adminEmail: String
    $collectionTitle: String!
    $description: String
    $featured: Boolean
    $findingAidUrl: String
    $keywords: [String]
  ) {
    createCollection(
      adminEmail: $adminEmail
      description: $description
      featured: $featured
      findingAidUrl: $findingAidUrl
      keywords: $keywords
      title: $collectionTitle
    ) {
      id
      adminEmail
      description
      featured
      findingAidUrl
      keywords
      title
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
      title
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
      title
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
      title
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
    $adminEmail: String
    $collectionId: ID!
    $collectionTitle: String!
    $description: String
    $keywords: [String]
    $featured: Boolean
    $findingAidUrl: String
    $published: Boolean
  ) {
    updateCollection(
      adminEmail: $adminEmail
      collectionId: $collectionId
      description: $description
      featured: $featured
      findingAidUrl: $findingAidUrl
      keywords: $keywords
      published: $published
      title: $collectionTitle
    ) {
      adminEmail
      description
      featured
      findingAidUrl
      id
      keywords
      published
      title
    }
  }
`;
