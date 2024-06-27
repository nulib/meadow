import React from "react";
import { render, fireEvent, waitFor } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";
import S3ObjectPicker from "@js/components/Work/Tabs/Preservation/S3ObjectPicker";
import { LIST_INGEST_BUCKET_OBJECTS } from "@js/components/Work/work.gql.js";

const mocks = [
  {
    request: {
      query: LIST_INGEST_BUCKET_OBJECTS,
      variables: { prefix: "file_sets/" },
    },
    result: {
      data: {
        ListIngestBucketObjects: [
          { key: "file_sets/file3", size: 1000, mimeType: "image/jpeg" },
          { key: "file_sets/file4", size: 2000, mimeType: "image/png" },
        ],
      },
    },
  },
  {
    request: {
      query: LIST_INGEST_BUCKET_OBJECTS,
      variables: { prefix: "" },
    },
    result: {
      data: {
        ListIngestBucketObjects: [
          { key: "file1", size: 1000, mimeType: "image/jpeg" },
          { key: "file2", size: 2000, mimeType: "image/png" },
          { key: "file_sets/file3", size: 1000, mimeType: "image/jpeg" },
          { key: "file_sets/file4", size: 2000, mimeType: "image/png" },
        ],
      },
    },
  },
];

describe("S3ObjectPicker component", () => {
  it("renders without crashing", () => {
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectPicker onFileSelect={() => { }} fileSetRole="A" workTypeId="IMAGE" />
      </MockedProvider>
    );
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
      </MockedProvider>
    );
    expect(await findByText("An error occurred")).toBeInTheDocument();
  });

  it("renders the Clear and Refresh buttons", async () => {
    const { findByText } = render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectPicker onFileSelect={() => { }} fileSetRole="A" workTypeId="IMAGE" />
      </MockedProvider>
    );
    expect(await findByText("Clear")).toBeInTheDocument();
    expect(await findByText("Refresh")).toBeInTheDocument();
  });

  it("renders the table when data is available", async () => {
    const { findByText } = render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectPicker onFileSelect={() => { }} fileSetRole="A" workTypeId="IMAGE" />
      </MockedProvider>
    );
    expect(await findByText("file1")).toBeInTheDocument();
    expect(await findByText("file2")).toBeInTheDocument();
  });

  it("handles prefixed search", async () => {
    const { findByText, getByPlaceholderText, queryByText } = render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectPicker onFileSelect={() => { }} fileSetRole="A" workTypeId="IMAGE" />
      </MockedProvider>
    );

    await findByText("file1");

    const input = getByPlaceholderText("Enter prefix");
    fireEvent.change(input, { target: { value: "file_sets/" } });

    await waitFor(() => {
      expect(input.value).toBe("file_sets/");
    });

    // Check that the prefixed files are present
    expect(await findByText("file_sets/file3")).toBeInTheDocument();
    expect(await findByText("file_sets/file4")).toBeInTheDocument();

    // Check that the non-prefixed files are not present
    expect(queryByText("file1")).not.toBeInTheDocument();
    expect(queryByText("file2")).not.toBeInTheDocument();
  });

});