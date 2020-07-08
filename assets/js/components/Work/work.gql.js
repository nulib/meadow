import gql from "graphql-tag";

export const GET_WORK = gql`
  query WorkQuery($id: ID!) {
    work(id: $id) {
      id
      accessionNumber
      administrativeMetadata {
        preservationLevel {
          id
          label
        }
        status {
          id
          label
        }
        projectName
        projectDesc
        projectProposer
        projectManager
        projectTaskNumber
        projectCycle
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
        callNumber
        caption
        catalogKey
        folderName
        folderNumber
        identifier
        keywords
        legacyIdentifier
        notes
        physicalDescriptionMaterial
        physicalDescriptionSize
        provenance
        publisher
        relatedUrl
        relatedMaterial
        rightsHolder
        scopeAndContents
        series
        source
        tableOfContents
        description
        contributor {
          term {
            id
            label
          }
          role {
            id
            label
            scheme
          }
        }
        creator {
          term {
            id
            label
          }
        }
        genre {
          term {
            id
            label
          }
        }
        language {
          term {
            id
            label
          }
        }
        license {
          id
          label
        }
        location {
          term {
            id
            label
          }
        }
        rightsStatement {
          id
          label
        }
        stylePeriod {
          term {
            id
            label
          }
        }
        subject {
          term {
            id
            label
          }
          role {
            id
            label
            scheme
          }
        }
        technique {
          term {
            id
            label
          }
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
        title
      }
      published
      representativeImage
      ingestSheet {
        id
        name
      }
      updatedAt
      visibility {
        id
        label
      }
      workType {
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
        title
      }
      ingestSheet {
        id
        name
      }
      published
      representativeImage
      updatedAt
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
        preservationLevel {
          id
          label
        }
        status {
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
        contributor {
          term {
            id
            label
          }
          role {
            id
            label
            scheme
          }
        }
        creator {
          term {
            id
            label
          }
        }
        genre {
          term {
            id
            label
          }
        }
        language {
          term {
            id
            label
          }
        }
        license {
          id
          label
        }
        location {
          term {
            id
            label
          }
        }
        rightsStatement {
          id
          label
        }
        stylePeriod {
          term {
            id
            label
          }
        }
        subject {
          term {
            id
            label
          }
          role {
            id
            label
            scheme
          }
        }
        technique {
          term {
            id
            label
          }
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
      ingestSheet {
        id
        name
      }
      project {
        id
        title
      }
    }
  }
`;
