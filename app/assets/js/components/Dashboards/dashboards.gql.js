import gql from "graphql-tag";

export const CSV_METADATA_UPDATE_JOB = gql`
  mutation CsvMetadataUpdate($filename: String!, $source: String!) {
    csvMetadataUpdate(filename: $filename, source: $source) {
      id
      errors {
        errors {
          field
          messages
        }
        row
      }
      filename
      insertedAt
      rows
      source
      startedAt
      status
      updatedAt
      user
    }
  }
`;

export const CREATE_NUL_AUTHORITY_RECORD = gql`
  mutation createNulAuthorityRecord($hint: String, $label: String!) {
    createNulAuthorityRecord(hint: $hint, label: $label) {
      hint
      id
      label
    }
  }
`;

export const DELETE_NUL_AUTHORITY_RECORD = gql`
  mutation DeleteNulAuthorityRecord($id: ID!) {
    deleteNulAuthorityRecord(nulAuthorityRecordId: $id) {
      id
      label
    }
  }
`;

export const GET_BATCH = gql`
  query batch($id: ID!) {
    batch(id: $id) {
      add
      delete
      error
      id
      nickname
      query
      replace
      started
      status
      type
      user
      worksUpdated
    }
  }
`;

export const GET_BATCHES = gql`
  query batches {
    batches {
      add
      delete
      error
      id
      nickname
      query
      replace
      started
      status
      type
      user
      worksUpdated
    }
  }
`;

export const GET_PRESERVATION_CHECKS = gql`
  query preservationChecks {
    preservationChecks {
      id
      filename
      insertedAt
      invalidRows
      location
      status
      updatedAt
    }
  }
`;

export const GET_CSV_METADATA_UPDATE_JOB = gql`
  query CsvMetadataUpdateJob($id: ID!) {
    csvMetadataUpdateJob(id: $id) {
      id
      errors {
        errors {
          field
          messages
        }
        row
      }
      filename
      insertedAt
      rows
      source
      startedAt
      status
      updatedAt
      user
    }
  }
`;

export const GET_CSV_METADATA_UPDATE_JOBS = gql`
  query CsvMetadataUpdateJobs {
    csvMetadataUpdateJobs {
      id
      errors {
        errors {
          field
          messages
        }
        row
      }
      filename
      insertedAt
      rows
      source
      startedAt
      status
      updatedAt
      user
    }
  }
`;

export const GET_NUL_AUTHORITY_RECORDS = gql`
  query NulAuthorityRecords($limit: Int) {
    nulAuthorityRecords(limit: $limit) {
      id
      hint
      label
    }
  }
`;

export const UPDATE_NUL_AUTHORITY_RECORD = gql`
  mutation UpdateNulAuthorityRecord($hint: String, $id: ID!, $label: String!) {
    updateNulAuthorityRecord(hint: $hint, id: $id, label: $label) {
      hint
      id
      label
    }
  }
`;
