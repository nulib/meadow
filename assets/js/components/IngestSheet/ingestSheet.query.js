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
      name
      filename
      state {
        name
        state
      }
      status
    }
  `
};

export const CREATE_INGEST_SHEET = gql`
  mutation CreateIngestSheet(
    $name: String!
    $projectId: String!
    $filename: String!
  ) {
    createIngestSheet(
      name: $name
      project_id: $projectId
      filename: $filename
    ) {
      id
      name
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
      name
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
        name
        status
        updatedAt
      }
    }
  }
`;

export const GET_INGEST_SHEET_STATE = gql`
  query IngestSheetState($sheetId: String!) {
    ingestSheet(id: $sheetId) {
      id
      state {
        name
        state
      }
    }
  }
`;

export const GET_INGEST_SHEET_ROW_VALIDATION_ERRORS = gql`
  query IngestSheetRowValidationErrors($sheetId: String!) {
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
  query IngestSheetValidationProgress($sheetId: String!) {
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
  query IngestSheetRows($sheetId: String!) {
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
  mutation ValidateIngestSheet($id: String!) {
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
  subscription IngestSheetValidationProgress($sheetId: String!) {
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

export const INGEST_SHEET_EXPORT_CSV = gql`
  query IngestSheetWorks($id: ID!) {
    ingestSheetWorks(id: $id) {
      accessionNumber
      id
      visibility
      workType
      metadata {
        title
        description
      }
    }
  }
`;

export const INGEST_SHEET_WORKS = gql`
  query IngestSheetWorks($id: ID!) {
    ingestSheetWorks(id: $id) {
      accessionNumber
      fileSets {
        accessionNumber
        id
        metadata {
          description
          location
        }
        role
      }
      id
      visibility
      workType
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
