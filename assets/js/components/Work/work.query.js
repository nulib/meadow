import gql from "graphql-tag";

export const GET_WORK = gql`
  query WorkQuery($id: ID!) {
    work(id: $id) {
      id
      accessionNumber
      administrativeMetadata {
        preservationLevel @client {
          id
          label
        }
        status @client {
          id
          label
        }
      }
      collection {
        id
        name
      }
      descriptiveMetadata {
        abstract
        alternateTitle
        boxName
        boxNumber
        description
        contributor @client {
          id
          label
          role {
            id
            label
            scheme
          }
        }
        creator @client {
          id
          label
        }
        genre @client {
          id
          label
        }
        language @client {
          id
          label
        }
        license @client {
          id
          label
        }
        location @client {
          id
          label
        }
        rightsStatement @client {
          id
          label
        }
        stylePeriod @client {
          id
          label
        }
        subject @client {
          id
          label
          role {
            id
            label
            scheme
          }
        }
        technique @client {
          id
          label
        }
        title
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
      published
      representativeImage
      sheet {
        id
        name
      }
      updatedAt
      visibility @client {
        id
        label
      }
      workType @client {
        id
        label
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
      workType @client {
        id
        label
      }
      visibility @client {
        id
        label
      }
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
        preservationLevel @client {
          id
          label
        }
        status @client {
          id
          label
        }
      }
      collection {
        name
        id
      }
      descriptiveMetadata {
        title
        description
        contributor @client {
          id
          label
          role {
            id
            label
            scheme
          }
        }
        creator @client {
          id
          label
        }
        genre @client {
          id
          label
        }
        language @client {
          id
          label
        }
        license @client {
          id
          label
        }
        location @client {
          id
          label
        }
        rightsStatement @client {
          id
          label
        }
        stylePeriod @client {
          id
          label
        }
        subject @client {
          id
          label
          role {
            id
            label
            scheme
          }
        }
        technique @client {
          id
          label
        }
      }
      insertedAt
      published
      workType {
        id
        label
      }
      visibility {
        id
        label
      }
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
