import { GET_PRESIGNED_URL } from "./ingestSheet.gql";

export const getPresignedUrlForIngestSheetMock = {
  request: {
    query: GET_PRESIGNED_URL,
    variables: {
      uploadType: "INGEST_SHEET",
    },
  },
  result: {
    data: {
      presignedUrl: {
        url: "https://abc123.com",
      },
    },
  },
};

export const getPresignedUrlForFileSetMock = {
  request: {
    query: GET_PRESIGNED_URL,
    variables: {
      uploadType: "FILE_SET",
    },
  },
  result: {
    data: {
      presignedUrl: {
        url: "https://abc123.com",
      },
    },
  },
};
