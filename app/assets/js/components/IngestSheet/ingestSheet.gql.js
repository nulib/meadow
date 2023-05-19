import IngestSheet from "./IngestSheet";
import gql from "graphql-tag";

IngestSheet.fragments = {
  parts: gql`
    fragment IngestSheetParts on IngestSheet {
      fileErrors
      filename
      id
      ingestSheetRows {
        errors {
          field
          message
        }
        fields {
          header
          value
        }
        row
        state
      }
      state {
        name
        state
      }
      status
      title
    }
  `,
};

export const CREATE_INGEST_SHEET = gql`
  mutation CreateIngestSheet(
    $title: String!
    $projectId: ID!
    $filename: String!
  ) {
    createIngestSheet(
      title: $title
      projectId: $projectId
      filename: $filename
    ) {
      id
      title
      status
      project {
        id
        title
      }
      filename
    }
  }
`;

export const DELETE_INGEST_SHEET = gql`
  mutation DeleteIngestSheet($sheetId: ID!) {
    deleteIngestSheet(sheetId: $sheetId) {
      id
      title
      status
    }
  }
`;

export const GET_PRESIGNED_URL = gql`
  query ($uploadType: S3UploadType!, $filename: String) {
    presignedUrl(uploadType: $uploadType, filename: $filename) {
      url
    }
  }
`;

export const INGEST_PROGRESS_SUBSCRIPTION = gql`
  subscription OnIngestProgress($sheetId: ID!) {
    ingestProgress(sheetId: $sheetId) {
      totalFileSets
      completedFileSets
      percentComplete
    }
  }
`;

export const INGEST_SHEET_COMPLETED_ERRORS = gql`
  query IngestSheetCompletedErrors($id: ID!) {
    ingestSheetErrors(id: $id) {
      accessionNumber
      action
      description
      errors
      filename
      outcome
      role
      rowNumber
      workAccessionNumber
    }
  }
`;

export const INGEST_SHEET_QUERY = gql`
  query IngestSheetQuery($sheetId: ID!) {
    ingestSheet(id: $sheetId) {
      fileErrors
      filename
      id
      state {
        name
        state
      }
      status
      title
    }
  }
`;

export const INGEST_SHEET_ROWS = gql`
  query IngestSheetRowValidationErrors(
    $limit: Int
    $sheetId: ID!
    $state: [State]
  ) {
    ingestSheetRows(limit: $limit, sheetId: $sheetId, state: $state) {
      row
      fields {
        header
        value
      }
      errors {
        field
        message
      }
      state
    }
  }
`;

export const INGEST_SHEET_SUBSCRIPTION = gql`
  subscription OnIngestSheetUpdate($sheetId: ID!) {
    ingestSheetUpdate(sheetId: $sheetId) {
      fileErrors
      filename
      id
      state {
        name
        state
      }
      status
      title
    }
  }
`;

//TODO: Keeping this as a reference, and might switch back to it

// export const INGEST_SHEET_SUBSCRIPTION = gql`
//   subscription OnIngestSheetUpdate($sheetId: ID!) {
//     ingestSheetUpdate(sheetId: $sheetId) {
//       ...IngestSheetParts
//     }
//   }
//   ${IngestSheet.fragments.parts}
// `;

export const INGEST_SHEET_VALIDATION_PROGRESS = gql`
  query IngestSheetValidationProgress($sheetId: ID!) {
    ingestSheetValidationProgress(id: $sheetId) {
      percentComplete
    }
  }
`;

export const INGEST_SHEET_WORK_COUNT = gql`
  query IngestSheetWorkCount($id: ID!) {
    ingestSheetWorkCount(id: $id) {
      totalWorks
      totalFileSets
      pass
      fail
    }
  }
`;

export const INGEST_SHEET_WORKS = gql`
  query IngestSheetWorks($id: ID!, $limit: Int) {
    ingestSheetWorks(id: $id, limit: $limit) {
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
          label
          location
        }
      }
      insertedAt
      manifestUrl
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

export const INGEST_SHEETS = gql`
  query GetIngestSheets($projectId: ID!) {
    project(id: $projectId) {
      id
      ingestSheets {
        id
        title
        status
        updatedAt
      }
    }
  }
`;

export const START_VALIDATION = gql`
  mutation ValidateIngestSheet($id: ID!) {
    validateIngestSheet(sheetId: $id) {
      message
    }
  }
`;
