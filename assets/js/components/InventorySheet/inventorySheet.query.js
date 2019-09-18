import gql from "graphql-tag";

export const CREATE_INGEST_JOB = gql`
  mutation CreateIngestJob(
    $name: String!
    $projectId: String!
    $filename: String!
  ) {
    createIngestJob(name: $name, project_id: $projectId, filename: $filename) {
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

export const DELETE_INGEST_JOB = gql`
  mutation DeleteIngestJob($ingestJobId: ID!) {
    deleteIngestJob(ingestJobId: $ingestJobId) {
      id
      name
    }
  }
`;

export const GET_INGEST_JOBS = gql`
  query GetIngestJobs($projectId: ID!) {
    project(id: $projectId) {
      id
      ingestJobs {
        id
        name
        updatedAt
      }
    }
  }
`;

export const GET_INVENTORY_SHEET_STATUS = gql`
  query InventorySheetStatus($inventorySheetId: String!) {
    ingestJob(id: $inventorySheetId) {
      state {
        name
        state
      }
    }
  }
`;

export const GET_INVENTORY_SHEET_ERRORS = gql`
  query IngestJobRowErrors($inventorySheetId: String!) {
    ingestJobRows(jobId: $inventorySheetId, state: FAIL) {
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

export const GET_INVENTORY_SHEET_PROGRESS = gql`
  query IngestJobProgress($inventorySheetId: String!) {
    ingestJobProgress(id: $inventorySheetId) {
      states {
        state
        count
      }
      percentComplete
    }
  }
`;

export const GET_INVENTORY_SHEET_VALIDATIONS = gql`
  query IngestJobRows($inventorySheetId: String!) {
    ingestJobRows(jobId: $inventorySheetId) {
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
  mutation ValidateIngestJob($id: String!) {
    validateIngestJob(ingestJobId: $id) {
      message
    }
  }
`;

export const SUBSCRIBE_TO_INVENTORY_SHEET_STATUS = gql`
  subscription InventorySheetStatusUpdate($inventorySheetId: String!) {
    ingestJobUpdate(jobId: $inventorySheetId) {
      state {
        name
        state
      }
    }
  }
`;

export const SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS = gql`
  subscription IngestJobRowUpdate($ingestJobId: String!) {
    ingestJobRowUpdate(jobId: $ingestJobId) {
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

export const SUBSCRIBE_TO_INVENTORY_SHEET_ERRORS = gql`
  subscription IngestJobRowErrors($inventorySheetId: String!) {
    ingestJobRowStateUpdate(jobId: $inventorySheetId, state: FAIL) {
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

export const SUBSCRIBE_TO_INVENTORY_SHEET_PROGRESS = gql`
  subscription IngestJobProgressUpdate($inventorySheetId: String!) {
    ingestJobProgressUpdate(jobId: $inventorySheetId) {
      states {
        state
        count
      }
      percentComplete
    }
  }
`;
