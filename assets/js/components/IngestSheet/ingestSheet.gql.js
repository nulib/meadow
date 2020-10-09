import gql from "graphql-tag";
import IngestSheet from "./IngestSheet";

IngestSheet.fragments = {
  parts: gql`
    fragment IngestSheetParts on IngestSheet {
      fileErrors
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
      id
      title
      filename
      state {
        name
        state
      }
      status
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
      project_id: $projectId
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

export const GET_INGEST_SHEETS = gql`
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

export const GET_INGEST_SHEET_STATE = gql`
  query IngestSheetState($sheetId: ID!) {
    ingestSheet(id: $sheetId) {
      id
      state {
        title
        state
      }
    }
  }
`;

export const GET_INGEST_SHEET_ROW_VALIDATION_ERRORS = gql`
  query IngestSheetRowValidationErrors($sheetId: ID!) {
    ingestSheetRows(sheetId: $sheetId, state: FAIL) {
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

export const GET_INGEST_SHEET_VALIDATION_PROGRESS = gql`
  query IngestSheetValidationProgress($sheetId: ID!) {
    ingestSheetValidationProgress(id: $sheetId) {
      states {
        state
        count
      }
      percentComplete
    }
  }
`;

export const GET_INGEST_SHEET_ROW_VALIDATIONS = gql`
  query IngestSheetRows($sheetId: ID!) {
    ingestSheetRows(sheetId: $sheetId) {
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

export const GET_PRESIGNED_URL = gql`
  query {
    presignedUrl {
      url
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

export const INGEST_SHEET_QUERY = gql`
  query IngestSheetQuery($sheetId: ID!) {
    ingestSheet(id: $sheetId) {
      ...IngestSheetParts
    }
  }
  ${IngestSheet.fragments.parts}
`;

export const INGEST_SHEET_SUBSCRIPTION = gql`
  subscription SubscribeToIngestSheet($sheetId: ID!) {
    ingestSheetUpdate(sheetId: $sheetId) {
      ...IngestSheetParts
    }
  }
  ${IngestSheet.fragments.parts}
`;

export const SUBSCRIBE_TO_INGEST_SHEET_VALIDATION_PROGRESS = gql`
  subscription IngestSheetValidationProgress($sheetId: ID!) {
    ingestSheetValidationProgress(sheetId: $sheetId) {
      states {
        state
        count
      }
      percentComplete
    }
  }
`;

export const APPROVE_INGEST_SHEET = gql`
  mutation ApproveIngestSheet($id: ID!) {
    approveIngestSheet(id: $id) {
      message
    }
  }
`;

export const INGEST_PROGRESS_SUBSCRIPTION = gql`
  subscription IngestProgress($sheetId: ID!) {
    ingestProgress(sheetId: $sheetId) {
      totalFileSets
      completedFileSets
      percentComplete
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
        role
        accessionNumber
        metadata {
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
