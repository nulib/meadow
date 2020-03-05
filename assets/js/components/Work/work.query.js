import gql from "graphql-tag";

export const GET_WORK = gql`
  query WorkQuery($id: ID!) {
    work(id: $id) {
      id
      accessionNumber
      descriptiveMetadata {
        title
        description
      }
      fileSets {
        id
        role
        accessionNumber
        metadata {
          description
          originalFilename
          label
          location
          sha256
        }
      }
      insertedAt
      manifestUrl
      project {
        id
        name
      }
      sheet {
        id
        name
      }
      published
      representativeImage
      updatedAt
      visibility
      workType
      collection {
        id
        name
      }
      administrativeMetadata {
        preservationLevel
        rightsStatement
      }
    }
  }
`;

export const GET_WORKS = gql`
  query WorksQuery {
    works {
      id
      accessionNumber
      descriptiveMetadata {
        title
        description
      }
      fileSets {
        id
        role
        accessionNumber
        metadata {
          description
          originalFilename
          location
          label
          sha256
        }
      }
      insertedAt
      manifestUrl
      project {
        id
        name
      }
      sheet {
        id
        name
      }
      published
      representativeImage
      updatedAt
      visibility
      workType
    }
  }
`;

export const SET_WORK_IMAGE = gql`
  mutation SetWorkImage($fileSetId: ID!, $workId: ID!) {
    setWorkImage(fileSetId: $fileSetId, workId: $workId) {
      id
      representativeImage
    }
  }
`;

export const UPDATE_WORK = gql`
  mutation UpdateWork($id: ID!, $work: WorkUpdateInput!) {
    updateWork(id: $id, work: $work) {
      id
      administrativeMetadata {
        preservationLevel
        rightsStatement
      }
      collection {
        name
        id
      }
      descriptiveMetadata {
        title
        description
      }
      insertedAt
      published
      visibility
    }
  }
`;

export const ADD_WORK_TO_COLLECTION = gql`
  mutation addWorkToCollection($workId: ID!, $collectionId: ID!) {
    addWorkToCollection(workId: $workId, collectionId: $collectionId) {
      id
    }
  }
`;

export const DELETE_WORK = gql`
  mutation deleteWork($workId: ID!) {
    deleteWork(workId: $workId) {
      id
      descriptiveMetadata {
        title
      }
      sheet {
        id
        name
      }
      project {
        id
        name
      }
    }
  }
`;
