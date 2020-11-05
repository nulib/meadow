import gql from "graphql-tag";

export const UPDATE_FILE_SETS = gql`
  mutation UpdateFileSets($id: ID!) {
    updateFileSets(id: $id) @client {
      id
    }
  }
`;

export const CREATE_SHARED_LINK = gql`
  mutation CreateSharedLink($workId: ID!) {
    createSharedLink(workId: $workId) {
      expires
      sharedLinkId
      workId
    }
  }
`;

export const GET_WORK = gql`
  query WorkQuery($id: ID!) {
    work(id: $id) {
      id
      accessionNumber
      administrativeMetadata {
        libraryUnit {
          id
          label
        }
        preservationLevel {
          id
          label
        }
        projectCycle
        projectDesc
        projectManager
        projectName
        projectProposer
        projectTaskNumber
        status {
          id
          label
        }
      }
      collection {
        id
        title
      }
      descriptiveMetadata {
        abstract
        alternateTitle
        ark
        boxName
        boxNumber
        caption
        catalogKey
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
        dateCreated {
          edtfDate
          humanizedDate
        }
        description
        folderName
        folderNumber
        genre {
          term {
            id
            label
          }
        }
        identifier
        keywords
        language {
          term {
            id
            label
          }
        }
        legacyIdentifier
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
        notes
        physicalDescriptionMaterial
        physicalDescriptionSize
        provenance
        publisher
        relatedUrl {
          url
          label {
            id
            label
            scheme
          }
        }
        relatedMaterial
        rightsHolder
        rightsStatement {
          id
          label
        }
        scopeAndContents
        series
        source
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
        tableOfContents
        technique {
          term {
            id
            label
          }
        }
        termsOfUse
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
      ingestSheet {
        id
        title
      }
      insertedAt
      manifestUrl
      project {
        id
        title
      }
      published
      representativeImage
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
        title
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
        libraryUnit {
          id
          label
        }
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
        title
        id
      }
      descriptiveMetadata {
        title
        description
        dateCreated {
          edtfDate
          humanizedDate
        }
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
        termsOfUse
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
        title
      }
      project {
        id
        title
      }
    }
  }
`;
