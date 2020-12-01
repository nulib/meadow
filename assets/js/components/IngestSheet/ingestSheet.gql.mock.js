import { GET_PRESIGNED_URL } from "./ingestSheet.gql";

export const getPresignedUrlMock = {
  request: {
    query: GET_PRESIGNED_URL,
  },
  result: {
    data: {
      presignedUrl: {
        url: "https://abc123.com",
      },
    },
  },
};
