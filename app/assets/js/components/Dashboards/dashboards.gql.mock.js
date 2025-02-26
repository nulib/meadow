import {
  DELETE_NUL_AUTHORITY_RECORD,
  GET_BATCH,
  GET_BATCHES,
  GET_CSV_METADATA_UPDATE_JOB,
  GET_CSV_METADATA_UPDATE_JOBS,
  GET_NUL_AUTHORITY_RECORDS,
  UPDATE_NUL_AUTHORITY_RECORD,
  GET_PRESERVATION_CHECKS,
} from "@js/components/Dashboards/dashboards.gql";
import { errors as csvMetadataUpdateJobErrors } from "@js/components/Dashboards/Csv/Errors";

export const mockGetBatchesResults = [
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{}}',
    delete: "{}",
    error: null,
    id: "f97d222b-3cf6-45ff-98c6-d09a3261964f",
    nickname: null,
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Work"}},{"query_string":{"query":" id.keyword:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"title":"Yo Ima Batch Title"}}',
    started: "2020-12-08T15:27:13.396560Z",
    status: "ERROR",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 2,
  },
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{"alternate_title":["Alt title here"],"box_name":["Beta box"],"box_number":["14"],"contributor":[{"role":{"id":"asg","scheme":"marc_relator"},"term":"http://id.worldcat.org/fast/1204155"}],"keywords":["some key word","keyword2"]}}',
    delete: '{"genre":[{"term":"http://vocab.getty.edu/aat/300266117"}]}',
    error: null,
    id: "7b9fa4c5-fa97-46e8-8fd7-db0001dc76c3",
    nickname: "My Batch Job",
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Work"}},{"query_string":{"query":" id.keyword:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"description":["Description replacer"],"rights_statement":{"id":"http://rightsstatements.org/vocab/InC/1.0/","scheme":"rights_statement"}}}',
    started: "2020-12-08T17:24:49.278717Z",
    status: "COMPLETE",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 43,
  },
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{}}',
    delete: "{}",
    error: null,
    id: "ABC-f97d222b-3cf6-45ff-98c6",
    nickname: null,
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Work"}},{"query_string":{"query":" id.keyword:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"title":"Yo Ima Batch Title"}}',
    started: "2020-12-09T15:27:13.396560Z",
    status: "IN_PROGRESS",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 2,
  },
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{}}',
    delete: "{}",
    error: null,
    id: "ZYZ-f97d222b-3cf6-45ff-98c6",
    nickname: null,
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Work"}},{"query_string":{"query":" id.keyword:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"title":"Yo Ima Batch Title"}}',
    started: "2020-12-09T15:27:13.396560Z",
    status: "QUEUED",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 2,
  },
];

export const mockPreservationChecks = [
  {
    id: "7c171c70-1f1a-4db8-8dcb-07c2c0003e10",
    filename: "preservation_check.csv",
    insertedAt: "2021-01-25T17:21:37.000000Z",
    invalid_rows: 0,
    location:
      "s3://dev-preservation-checks/csv_metadata/2c5d7d42-dee1-4274-95ce-363b942bd21f.csv",
    status: "complete",
    updatedAt: "2021-01-25T17:22:37.199112Z",
  },
  {
    id: "99971c70-1f1a-4db8-8dcb-07c2c0003e10",
    filename: "preservation_check2.csv",
    insertedAt: "2021-01-25T17:24:37.000000Z",
    invalid_rows: 0,
    location:
      "s3://dev-preservation-checks/csv_metadata/999d7d42-dee1-4274-95ce-363b942bd21f.csv",
    status: "complete",
    updatedAt: "2021-01-25T17:29:37.199112Z",
  },
];

export const mockCsvMetadataUpdateJobs = [
  {
    id: "7c171c70-1f1a-4db8-8dcb-07c2c0003e10",
    errors: csvMetadataUpdateJobErrors,
    filename: "csv-contributor-faceted-mandela.csv",
    insertedAt: "2021-01-25T17:21:34.582697Z",
    rows: 8,
    source:
      "s3://dev-uploads/csv_metadata/2c5d7d42-dee1-4274-95ce-363b942bd21f.csv",
    startedAt: "2021-01-25T17:21:37.000000Z",
    status: "complete",
    updatedAt: "2021-01-25T17:21:37.199112Z",
    user: "aja0137",
  },
  {
    __typename: "CsvMetadataUpdateJob",
    id: "12b3b345-8391-45a9-8f15-03efb721cf4c",
    errors: [],
    filename: "search_results_selected_items.csv",
    insertedAt: "2021-01-25T16:58:25.076293Z",
    rows: 8,
    source:
      "s3://dev-uploads/csv_metadata/4fcb761f-fd5f-4d71-9fea-c98fe2978147.csv",
    startedAt: "2021-01-25T16:58:26.000000Z",
    status: "complete",
    updatedAt: "2021-01-25T16:58:25.898129Z",
    user: "aja0137",
  },
];

export const mockNulAuthorityRecords = [
  {
    hint: "Ima hint 1",
    id: "info:nul/675ed59a-ab54-481a-9bd1-d9b7fd2604dc",
    label: "NUL Auth Record 1",
  },
  {
    hint: "Ima hint 2",
    id: "info:nul/a7a2c899-305d-42e5-b825-9cc13b327793",
    label: "NUL Auth Record 2",
  },
];

export const deleteNulAuthorityRecordMock = {
  request: {
    query: DELETE_NUL_AUTHORITY_RECORD,
  },
  response: {
    data: {
      deleteNulAuthorityRecord: {
        id: "info:nul/675ed59a-ab54-481a-9bd1-d9b7fd2604dc",
        label: "NUL Auth Record 1",
      },
    },
  },
};

export const getBatchMock = {
  request: {
    query: GET_BATCH,
    variables: {
      id: "ABC123",
    },
  },
  result: {
    data: {
      batch: mockGetBatchesResults[1],
    },
  },
};

export const getBatchesMock = {
  request: {
    query: GET_BATCHES,
  },
  result: {
    data: {
      batches: mockGetBatchesResults,
    },
  },
};

export const getPreservationChecksMocks = {
  request: {
    query: GET_PRESERVATION_CHECKS,
  },
  result: {
    data: {
      preservationChecks: mockPreservationChecks,
    },
  },
};

export const getCsvMetadataUpdateJobMock = {
  request: {
    query: GET_CSV_METADATA_UPDATE_JOB,
    variables: {
      id: "7c171c70-1f1a-4db8-8dcb-07c2c0003e10",
    },
  },
  result: {
    data: {
      csvMetadataUpdateJob: mockCsvMetadataUpdateJobs[0],
    },
  },
};

export const getCsvMetadataUpdateJobsMock = {
  request: {
    query: GET_CSV_METADATA_UPDATE_JOBS,
  },
  result: {
    data: {
      csvMetadataUpdateJobs: mockCsvMetadataUpdateJobs,
    },
  },
};

export const getNulAuthorityRecordsMock = {
  request: {
    query: GET_NUL_AUTHORITY_RECORDS,
    variables: {
      limit: 100,
    },
  },
  result: {
    data: {
      nulAuthorityRecords: mockNulAuthorityRecords,
    },
  },
};

export const getNulAuthorityRecordsSetLimitMock = {
  request: {
    query: GET_NUL_AUTHORITY_RECORDS,
    variables: {
      limit: 25,
    },
  },
  result: {
    data: {
      nulAuthorityRecords: mockNulAuthorityRecords,
    },
  },
};

export const updateNulAuthorityRecordMock = {
  request: {
    query: UPDATE_NUL_AUTHORITY_RECORD,
  },
  result: {
    data: {
      updateNulAuthorityRecord: mockNulAuthorityRecords[0],
    },
  },
};
