import gql from "graphql-tag";

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
        updatedAt
      }
    }
  }
`;

export const GET_INGEST_SHEET_STATUS = gql`
  query IngestSheetStatus($ingestSheetId: String!) {
    ingestSheet(id: $ingestSheetId) {
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

export const SUBSCRIBE_TO_INGEST_SHEET_STATUS = gql`
  subscription IngestSheetStatusUpdate($ingestSheetId: String!) {
    ingestSheetUpdate(sheetId: $ingestSheetId) {
      state {
        name
        state
      }
    }
  }
`;

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
