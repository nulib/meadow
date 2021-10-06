import { BATCH_DELETE } from "./batch-edit.gql.js";

export const MOCK_BATCH_ID = "7a6c7b35-41a6-465a-9be2-0587c6b39ae0";

export const batchDeleteMock = {
  request: {
    query: BATCH_DELETE,
    variables: {
      query:
        '{"query":{"bool":{"must":[{"bool":{"must":[{"bool":{"must":[{"match":{"model.name":"Work"}}]}}]}}]}}}',
      nickname: "Test Batch Delete",
    },
  },
  result: {
    data: {
      batchDelete: {
        id: MOCK_BATCH_ID,
        nickname: "Test Batch Delete",
        status: "QUEUED",
        user: "abc123",
        started: "2021-02-09T23:28:16.823480Z",
        type: "DELETE",
        query:
          '{"query":{"bool":{"must":[{"bool":{"must":[{"bool":{"must":[{"match":{"model.name":"Work"}}]}}]}}]}}}',
        add: null,
        replace: null,
        delete: null,
        error: null,
      },
    },
  },
};
