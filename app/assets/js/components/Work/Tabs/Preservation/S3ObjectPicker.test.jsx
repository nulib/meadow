import React from "react";
import { render } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";
import S3ObjectPicker from "./S3ObjectPicker";
import { LIST_INGEST_BUCKET_OBJECTS } from "@js/components/Work/work.gql.js";

const mocks = [
  {
    request: {
      query: LIST_INGEST_BUCKET_OBJECTS,
      variables: { prefix: "" },
    },
    result: {
      data: {
        ListIngestBucketObjects: {
          objects: [
            { uri: "s3://bucket/file1.jpg", key: "file1", size: 1000, mimeType: "image/jpeg", storageClass: "STANDARD", lastModified: new Date().toISOString() },
            { uri: "s3://bucket/file2.png", key: "file2", size: 2000, mimeType: "image/png", storageClass: "STANDARD", lastModified: new Date().toISOString() },
          ],
          folders: ["file_sets"],
        },
      },
    },
  },
];

describe("S3ObjectPicker component", () => {
  it("renders without crashing", async () => {
    const { findByTestId } = render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectPicker onFileSelect={() => { }} fileSetRole="A" workTypeId="IMAGE" />
      </MockedProvider>
    );
    expect(await findByTestId("file-picker")).toBeInTheDocument();
  });

  it("renders an error message when there is a query error", async () => {
    const errorMock = [
      {
        request: {
          query: LIST_INGEST_BUCKET_OBJECTS,
          variables: { prefix: "" },
        },
        error: new Error("An error occurred"),
      },
    ];
    const { findByText } = render(
      <MockedProvider mocks={errorMock} addTypename={false}>
        <S3ObjectPicker onFileSelect={() => { }} fileSetRole="A" workTypeId="IMAGE" />
      </MockedProvider>,
    );
    expect(await findByText("An error occurred")).toBeInTheDocument();
  });
});