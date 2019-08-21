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

export const GET_INVENTORY_SHEET_VALIDATIONS = gql`
  query IngestJobValidations($inventorySheetId: String!) {
    ingestJobValidations(id: $inventorySheetId) {
      validations {
        id
        object {
          content
          errors
          status
        }
      }
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

export const SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS = gql`
  subscription IngestJobValidationUpdate($ingestJobId: String!) {
    ingestJobValidationUpdate(ingestJobId: $ingestJobId) {
      id
      object {
        content
        errors
        status
      }
    }
  }
`;
