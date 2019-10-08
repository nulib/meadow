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
  mutation DeleteIngestSheet($ingestSheetId: ID!) {
    deleteIngestSheet(ingestSheetId: $ingestSheetId) {
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
  query IngestSheetState($ingestSheetId: String!) {
    ingestSheet(id: $ingestSheetId) {
      id
      state {
        name
        state
      }
    }
  }
`;

export const GET_INGEST_SHEET_ERRORS = gql`
  query IngestSheetRowErrors($ingestSheetId: String!) {
    ingestSheetRows(sheetId: $ingestSheetId, state: FAIL) {
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

export const GET_INGEST_SHEET_PROGRESS = gql`
  query IngestSheetProgress($ingestSheetId: String!) {
    ingestSheetProgress(id: $ingestSheetId) {
      states {
        state
        count
      }
      percentComplete
    }
  }
`;

export const GET_INGEST_SHEET_VALIDATIONS = gql`
  query IngestSheetRows($ingestSheetId: String!) {
    ingestSheetRows(sheetId: $ingestSheetId) {
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
    validateIngestSheet(ingestSheetId: $id) {
      message
    }
  }
`;

export const INGEST_SHEET_QUERY = gql`
  query IngestSheetQuery($ingestSheetId: ID!) {
    ingestSheet(id: $ingestSheetId) {
      ...IngestSheetParts
    }
  }
  ${IngestSheet.fragments.parts}
`;

export const INGEST_SHEET_SUBSCRIPTION = gql`
  subscription SubscribeToIngestSheet($ingestSheetId: ID!) {
    ingestSheetUpdate(sheetId: $ingestSheetId) {
      ...IngestSheetParts
    }
  }
  ${IngestSheet.fragments.parts}
`;

//TODO: Delete this?
export const SUBSCRIBE_TO_INGEST_SHEET_VALIDATIONS = gql`
  subscription IngestSheetRowUpdate($ingestSheetId: String!) {
    ingestSheetRowUpdate(sheetId: $ingestSheetId) {
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

// TODO: Delete this?
export const SUBSCRIBE_TO_INGEST_SHEET_ERRORS = gql`
  subscription IngestSheetRowErrors($ingestSheetId: String!) {
    ingestSheetRowStateUpdate(sheetId: $ingestSheetId, state: FAIL) {
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

export const SUBSCRIBE_TO_INGEST_SHEET_PROGRESS = gql`
  subscription IngestSheetProgressUpdate($ingestSheetId: String!) {
    ingestSheetProgressUpdate(sheetId: $ingestSheetId) {
      states {
        state
        count
      }
      percentComplete
    }
  }
`;

export const MOCK_APPROVE_INGEST_SHEET = gql`
  mutation MockApproveIngestSheet($id: ID!) {
    mockApproveIngestSheet(id: $id) {
      id
      status
      updatedAt
    }
  }
`;

export const MOCK_WORKS_CREATED_COUNT_SUBSCRIPTION = gql`
  subscription MockWorksCreatedCount($sheetId: ID!) {
    mockWorksCreatedCount(sheetId: $sheetId) {
      count
    }
  }
`;
