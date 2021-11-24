import gql from "graphql-tag";

export const ADD_WORK_TO_COLLECTION = gql`
  mutation addWorkToCollection($workId: ID!, $collectionId: ID!) {
    addWorkToCollection(workId: $workId, collectionId: $collectionId) {
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

export const CREATE_WORK = gql`
  mutation createWork(
    $accessionNumber: String!
    $title: String
    $workType: CodedTermInput
  ) {
    createWork(
      accessionNumber: $accessionNumber
      administrativeMetadata: {}
      descriptiveMetadata: { title: $title }
      workType: $workType
    ) {
      accessionNumber
      descriptiveMetadata {
        title
      }
      id
      workType {
        id
        label
      }
    }
  }
`;

export const DELETE_FILESET = gql`
  mutation DeleteFileSet($fileSetId: ID!) {
    deleteFileSet(fileSetId: $fileSetId) {
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
        culturalContext
        dateCreated {
          edtf
          humanized
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
        accessionNumber
        coreMetadata {
          description
          label
          location
          mimeType
          originalFilename
          digests {
            md5
            sha1
            sha256
          }
        }
        extractedMetadata
        insertedAt
        role {
          id
          label
        }
        representativeImageUrl
        streamingUrl
        structuralMetadata {
          type
          value
        }
        updatedAt
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
        role {
          id
          label
        }
        accessionNumber
        coreMetadata {
          description
          originalFilename
          location
          label
          digests {
            md5
            sha1
            sha256
          }
        }
        representativeImageUrl
        insertedAt
        updatedAt
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

export const GET_WORK_TYPES = gql`
  query GetWorkTypes {
    codeList(scheme: WORK_TYPE) {
      id
      label
      scheme
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
        culturalContext
        description
        dateCreated {
          edtf
          humanized
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
        termsOfUse
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

export const INGEST_FILE_SET = gql`
  mutation IngestFileSet(
    $accession_number: String!
    $role: FileSetRole!
    $coreMetadata: FileSetCoreMetadataInput!
    $workId: ID!
  ) {
    ingestFileSet(
      accessionNumber: $accession_number
      role: $role
      coreMetadata: $coreMetadata
      workId: $workId
    ) {
      id
      accession_number
      role {
        id
        label
      }
      work {
        id
      }
      coreMetadata {
        location
        label
        description
        original_filename
        digests {
          md5
          sha1
          sha256
        }
      }
    }
  }
`;

export const UPDATE_ACCESS_FILE_ORDER = gql`
  mutation UpdateAccessFileOrder($workId: ID!, $fileSetIds: [ID]) {
    updateAccessFileOrder(workId: $workId, fileSetIds: $fileSetIds) {
      id
    }
  }
`;

export const WORK_ARCHIVER_ENDPOINT = gql`
  query WorkArchiverEndpoint {
    workArchiverEndpoint {
      url
    }
  }
`;

export const UPDATE_FILE_SET = gql`
  mutation UpdateFileSet(
    $id: ID!
    $coreMetadata: FileSetCoreMetadataUpdate
    $posterOffset: Int
    $structuralMetadata: FileSetStructuralMetadataInput
  ) {
    updateFileSet(
      id: $id
      coreMetadata: $coreMetadata
      posterOffset: $posterOffset
      structuralMetadata: $structuralMetadata
    ) {
      id
    }
  }
`;

export const UPDATE_FILE_SETS = gql`
  mutation UpdateFileSets($fileSets: [FileSetUpdate]!) {
    updateFileSets(fileSets: $fileSets) {
      id
      coreMetadata {
        description
        label
      }
    }
  }
`;

export const VERIFY_FILE_SETS = gql`
  query VerifyFileSets($workId: ID!) {
    verifyFileSets(workId: $workId) {
      fileSetId
      verified
    }
  }
`;
