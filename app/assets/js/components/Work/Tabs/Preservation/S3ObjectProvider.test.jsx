import React from "react";
import { render, screen } from "@testing-library/react";
import { MockedProvider } from "@apollo/client/testing";
import S3ObjectProvider from "./S3ObjectProvider";
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
            { uri: "s3://bucket/file1.jpg", key: "file1.jpg", size: 1000, mimeType: "image/jpeg", storageClass: "STANDARD", lastModified: "2024-09-14T05:12:59.224Z", },
            { uri: "s3://bucket/file2.png", key: "file2.png", size: 2000, mimeType: "image/png", storageClass: "STANDARD", lastModified: "2024-09-14T05:12:59.224Z", },
            { uri: "s3://bucket/hideme.mp4", key: "hideme.mp4", size: 12000, mimeType: "video/mp4", storageClass: "STANDARD", lastModified: "2024-09-14T05:12:59.224Z", },
          ],
          folders: ["file_sets"],
        },
      },
    },
    expected: {
      files: [ 
        { id: "s3://bucket/file1.jpg", name: "file1.jpg", size: 1000, modDate: "2024-09-14T05:12:59.224Z", isDir: false, icon: "image", },
        { id: "s3://bucket/file2.png", name: "file2.png", size: 2000, modDate: "2024-09-14T05:12:59.224Z", isDir: false, icon: "image", },
        { id: "file_sets", name: "file_sets", isDir: true },
      ],
      folders: [{ id: '/', name: 'ingest', isDir: true, icon: '' }]
    }
  },
  {
    request: {
      query: LIST_INGEST_BUCKET_OBJECTS,
      variables: { prefix: "file_sets/" },
    },
    result: {
      data: {
        ListIngestBucketObjects: {
          objects: [
            { uri: "s3://bucket/file_sets/file3.jpg", key: "file_sets/file3.jpg", size: 1000, mimeType: "image/jpeg", storageClass: "STANDARD", lastModified: "2024-09-14T05:12:59.224Z", },
            { uri: "s3://bucket/file_sets/file4.png", key: "file_sets/file4.png", size: 2000, mimeType: "image/png", storageClass: "STANDARD", lastModified: "2024-09-14T05:12:59.224Z", },
          ],
          folders: [],
        },
      },
    },
    expected: {
      files: [
        { id: "s3://bucket/file_sets/file3.jpg", name: "file3.jpg", size: 1000, modDate: "2024-09-14T05:12:59.224Z", isDir: false, icon: "image" }, 
        { id: "s3://bucket/file_sets/file4.png", name: "file4.png", size: 2000, modDate: "2024-09-14T05:12:59.224Z", isDir: false, icon: "image" },
      ],
      folders: [{ id: "/", name: "ingest", isDir: true, icon: "" }, { id: "file_sets", name: "file_sets", isDir: true, icon: "" }],
    }
  },
];

const TestHarness = ({ files, folderChain }) => {
  return (
    <div role="result">
      <span role="files">{JSON.stringify(files)}</span>
      <span role="folderChain">{JSON.stringify(folderChain)}</span>
    </div>
  )
}

describe("S3ObjectProvider component", () => {
  it("provides file and folderChain props", async () => {
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectProvider fileSetRole="A" workTypeId="IMAGE" prefix="">
          <TestHarness/>
        </S3ObjectProvider>
      </MockedProvider>
    );

    await screen.findByRole("result");
    const { expected } = mocks[0];
    const files = JSON.parse(screen.getByRole("files").textContent);
    const folders = JSON.parse(screen.getByRole("folderChain").textContent);
    expect(files).toEqual(expected.files);
    expect(folders).toEqual(expected.folders);
  });

  it("handles a prefixed query", async () => {
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <S3ObjectProvider fileSetRole="A" workTypeId="IMAGE" prefix="file_sets/">
          <TestHarness/>
        </S3ObjectProvider>
      </MockedProvider>
    );


    await screen.findByRole("result");
    const { expected } = mocks[1];
    const files = JSON.parse(screen.getByRole("files").textContent);
    const folders = JSON.parse(screen.getByRole("folderChain").textContent);
    expect(files).toEqual(expected.files);
    expect(folders).toEqual(expected.folders);
  });
});