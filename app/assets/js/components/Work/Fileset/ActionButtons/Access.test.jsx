import React from "react";
import WorkFilesetActionButtonsAccess from "@js/components/Work/Fileset/ActionButtons/Access";
import { WorkProvider } from "@js/context/work-context";
import { dcApiEndpointMock } from "@js/components/UI/ui.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { screen } from "@testing-library/react";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

const mocks = [dcApiEndpointMock];

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mockFileSet = {
  __typename: "FileSet",
  id: "120da9c2-abb3-4492-a62c-e4f0beb2bb6f",
  accessionNumber: "Donohue_002_01",
  coreMetadata: {
    __typename: "FileSetCoreMetadata",
    description: "Photo, man with two children",
    label: "The label",
    location: "s3://testing",
    mimeType: "video/x-m4v",
    originalFilename: "small.m4v",
    digests: {
      __typename: "Digests",
      md5: "a036e18dad7b0deab383454ec1d32f87",
      sha1: null,
      sha256: null,
    },
  },
  extractedMetadata: "",
  insertedAt: "2023-05-04T20:31:27.097298Z",
  role: {
    __typename: "CodedTerm",
    id: "A",
    label: "Access",
  },
  representativeImageUrl: null,
  streamingUrl: "https://testings/120da9c2-abb3-4492-a62c-e4f0beb2bb6f.m4v",
  structuralMetadata: {
    __typename: "FileSetStructuralMetadata",
    type: "WEBVTT",
    value:
      "WEBVTT - Translation of that film I like\n\nNOTE\nThis translation was done by Kyle so that\nsome friends can watch it with their parents.\n\n1\n00:02:15.000 --> 00:02:20.000\n- Ta en kopp varmt te.\n- Det är inte varmt.\n\n2\n00:02:20.000 --> 00:02:25.000\n- Har en kopp te.\n- Det smakar som te.\n\nNOTE This last line may not translate well.\n\n3\n00:02:25.000 --> 00:02:30.000\n- Ta en kopp",
  },
  updatedAt: "2023-05-04T20:32:03.571707Z",
};

const initialState = {
  activeMediaFileSet: mockFileSet,
  webVttModal: {
    fileSetId: null,
    isOpen: false,
    webVttString: "",
  },
  workType: "VIDEO",
  dcApiToken: "abcZ4323823092mccas999",
};

describe("WorkFilesetActionButtonsAccess", () => {
  it("renders a download button for a Video Work Fileset", () => {
    renderWithRouterApollo(
      <WorkProvider
        initialState={{
          ...initialState,
          workType: "VIDEO",
        }}
      >
        <WorkFilesetActionButtonsAccess fileSet={mockFileSet} />
      </WorkProvider>,
      { mocks },
    );
    expect(screen.getByTestId("download-fileset-button")).toBeInTheDocument();
  });

  it("renders a download button for an Audio Work Fileset", () => {
    const audioFileSet = {
      ...mockFileSet,
      coreMetadata: {
        ...mockFileSet.coreMetadata,
        mimeType: "audio/mp3",
      },
    };
    renderWithRouterApollo(
      <WorkProvider
        initialState={{
          ...initialState,
          workType: "AUDIO",
        }}
      >
        <WorkFilesetActionButtonsAccess fileSet={audioFileSet} />
      </WorkProvider>,
      { mocks },
    );
    expect(screen.getByTestId("download-fileset-button")).toBeInTheDocument();
  });

  it("renders a download button for an Image Work Fileset", () => {
    const imageFileSet = {
      ...mockFileSet,
      coreMetadata: {
        ...mockFileSet.coreMetadata,
        mimeType: "image/jpeg",
      },
    };
    renderWithRouterApollo(
      <WorkProvider
        initialState={{
          ...initialState,
          workType: "IMAGE",
        }}
      >
        <WorkFilesetActionButtonsAccess fileSet={imageFileSet} />
      </WorkProvider>,
      { mocks },
    );
    expect(screen.getByTestId("download-image-fileset")).toBeInTheDocument();
  });
});
