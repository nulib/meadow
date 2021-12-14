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
    $published: Boolean
    $visibility: CodedTermInput
  ) {
    createCollection(
      adminEmail: $adminEmail
      description: $description
      featured: $featured
      findingAidUrl: $findingAidUrl
      keywords: $keywords
      published: $published
      title: $collectionTitle
      visibility: $visibility
    ) {
      id
      adminEmail
      description
      featured
      findingAidUrl
      keywords
      published
      title
      visibility {
        id
        label
      }
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
      description
      featured
      findingAidUrl
      id
      keywords
      published
      representativeWork {
        id
        representativeImage
      }
      title
      totalWorks
      visibility {
        id
        label
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
      totalWorks
      representativeWork {
        id
        representativeImage
      }
      visibility {
        id
        label
      }
    }
  }
`;

export const UPDATE_COLLECTION = gql`
  mutation UpdateCollection(
    $adminEmail: String
    $collectionId: ID!
    $collectionTitle: String
    $description: String
    $featured: Boolean
    $findingAidUrl: String
    $keywords: [String]
    $published: Boolean
    $visibility: CodedTermInput
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
      visibility: $visibility
    ) {
      adminEmail
      description
      featured
      findingAidUrl
      id
      keywords
      published
      title
      visibility {
        id
        label
      }
    }
  }
`;
