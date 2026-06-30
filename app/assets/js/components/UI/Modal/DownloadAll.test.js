import { screen, fireEvent } from "@testing-library/react";
import React from "react";
import UIDownloadAll from "@js/components/UI/Modal/DownloadAll";
import userEvent from "@testing-library/user-event";
import { workArchiverEndpointMock } from "@js/components/Work/work.gql.mock";
import { GET_WORK } from "@js/components/Work/work.gql";
import { renderWithApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { mockUser } from "@js/components/Auth/auth.gql.mock";

useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

// Minimal GET_WORK mock — no transcriptions — for the images-only flow
const getWorkNoTranscriptionsMock = {
  request: { query: GET_WORK, variables: { id: "asdf" } },
  result: {
    data: {
      work: {
        id: "asdf",
        accessionNumber: "WORK-ASDF",
        fileSets: [],
      },
    },
  },
};

// GET_WORK mock with two transcribed file sets
const getWorkWithTranscriptionsMock = {
  request: { query: GET_WORK, variables: { id: "work-789" } },
  result: {
    data: {
      work: {
        id: "work-789",
        accessionNumber: "WORK-ACC-001",
        fileSets: [
          {
            id: "fs-1",
            accessionNumber: "FS-ACC-001",
            annotations: [
              {
                type: "transcription",
                status: "completed",
                content: "Page one text.",
              },
            ],
          },
          {
            id: "fs-2",
            accessionNumber: "FS-ACC-002",
            annotations: [
              {
                type: "transcription",
                status: "completed",
                content: "Page two text.",
              },
            ],
          },
        ],
      },
    },
  },
};

// Helper: spy on document.createElement to capture the <a> tag and mock .click()
function spyOnCreateElement() {
  const originalCreateElement = document.createElement.bind(document);
  let capturedLink = null;
  jest.spyOn(document, "createElement").mockImplementation((tag) => {
    const el = originalCreateElement(tag);
    if (tag === "a") {
      capturedLink = el;
      jest.spyOn(el, "click").mockImplementation(() => {});
    }
    return el;
  });
  return { getCapturedLink: () => capturedLink };
}

describe("UIDownloadAll component — images flow", () => {
  beforeEach(() => {
    renderWithApollo(<UIDownloadAll workId="asdf" />, {
      mocks: [workArchiverEndpointMock, getWorkNoTranscriptionsMock],
    });
  });

  it("renders the Download All button", async () => {
    expect(await screen.findByTestId("download-all-button"));
  });

  it("toggles modal display", async () => {
    const user = userEvent.setup();
    const downloadButton = await screen.findByTestId("download-all-button");
    const cancelButton = await screen.findByTestId("cancel-button");
    const modalWrapper = await screen.findByTestId("download-all-modal");

    await user.click(downloadButton);
    expect(modalWrapper).toHaveClass("is-active");

    await user.click(cancelButton);
    expect(modalWrapper).not.toHaveClass("is-active");

    await user.click(downloadButton);
    expect(modalWrapper).toHaveClass("is-active");
  });

  it("renders user email", async () => {
    expect(await screen.findByTestId("email"));
  });

  it("renders radio buttons for IIIF image sizes", async () => {
    const radioWrapperEl = await screen.findByTestId("radio-image-size");
    expect(radioWrapperEl.childNodes).toHaveLength(3);
  });

  it("renders the submit and cancel buttons", async () => {
    expect(await screen.findByTestId("cancel-button"));
    expect(await screen.findByTestId("submit-button"));
  });

  it("does not show the download-type choice when no transcriptions exist", async () => {
    // Wait for work data to load
    await screen.findByTestId("email");
    expect(screen.queryByTestId("radio-download-type")).not.toBeInTheDocument();
  });
});

describe("UIDownloadAll — transcription flow", () => {
  beforeEach(() => {
    window.URL.createObjectURL = jest.fn(() => "blob:mock-url");
    window.URL.revokeObjectURL = jest.fn();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("shows the download-type choice when transcriptions exist", async () => {
    renderWithApollo(<UIDownloadAll workId="work-789" />, {
      mocks: [workArchiverEndpointMock, getWorkWithTranscriptionsMock],
    });

    expect(
      await screen.findByTestId("radio-download-type"),
    ).toBeInTheDocument();
  });

  it("defaults to images when transcriptions exist", async () => {
    renderWithApollo(<UIDownloadAll workId="work-789" />, {
      mocks: [workArchiverEndpointMock, getWorkWithTranscriptionsMock],
    });

    await screen.findByTestId("radio-download-type");

    // Images radios and submit button visible by default
    expect(screen.getByTestId("radio-image-size")).toBeInTheDocument();
    expect(screen.getByTestId("submit-button")).toBeInTheDocument();
    expect(
      screen.queryByTestId("radio-transcription-format"),
    ).not.toBeInTheDocument();
    expect(
      screen.queryByTestId("download-transcriptions-button"),
    ).not.toBeInTheDocument();
  });

  it("switches to transcriptions view when transcriptions radio is selected", async () => {
    renderWithApollo(<UIDownloadAll workId="work-789" />, {
      mocks: [workArchiverEndpointMock, getWorkWithTranscriptionsMock],
    });

    await screen.findByTestId("radio-download-type");

    const transcriptionsRadio = screen.getByDisplayValue("transcriptions");
    fireEvent.click(transcriptionsRadio);

    expect(
      screen.getByTestId("radio-transcription-format"),
    ).toBeInTheDocument();
    expect(
      screen.getByTestId("download-transcriptions-button"),
    ).toBeInTheDocument();
    expect(screen.queryByTestId("radio-image-size")).not.toBeInTheDocument();
    expect(screen.queryByTestId("submit-button")).not.toBeInTheDocument();
  });

  it("downloads a combined .txt when the default format is used", async () => {
    const { getCapturedLink } = spyOnCreateElement();

    renderWithApollo(<UIDownloadAll workId="work-789" />, {
      mocks: [workArchiverEndpointMock, getWorkWithTranscriptionsMock],
    });

    await screen.findByTestId("radio-download-type");
    fireEvent.click(screen.getByDisplayValue("transcriptions"));

    const downloadButton = await screen.findByTestId(
      "download-transcriptions-button",
    );
    fireEvent.click(downloadButton);

    expect(window.URL.createObjectURL).toHaveBeenCalledWith(expect.any(Blob));
    expect(getCapturedLink()).not.toBeNull();
    expect(getCapturedLink().download).toBe("transcriptions-WORK-ACC-001.txt");
    expect(window.URL.revokeObjectURL).toHaveBeenCalledWith("blob:mock-url");
  });

  it("downloads a .zip when the zip format is selected", async () => {
    const { getCapturedLink } = spyOnCreateElement();

    renderWithApollo(<UIDownloadAll workId="work-789" />, {
      mocks: [workArchiverEndpointMock, getWorkWithTranscriptionsMock],
    });

    await screen.findByTestId("radio-download-type");
    fireEvent.click(screen.getByDisplayValue("transcriptions"));

    const zipRadio = await screen.findByDisplayValue("zip");
    fireEvent.click(zipRadio);

    fireEvent.click(screen.getByTestId("download-transcriptions-button"));

    expect(getCapturedLink()).not.toBeNull();
    expect(getCapturedLink().download).toBe("transcriptions-WORK-ACC-001.zip");
  });

  it("combined .txt content includes headers and both transcriptions", async () => {
    let capturedBlob = null;
    window.URL.createObjectURL = jest.fn((blob) => {
      capturedBlob = blob;
      return "blob:mock-url";
    });
    spyOnCreateElement();

    renderWithApollo(<UIDownloadAll workId="work-789" />, {
      mocks: [workArchiverEndpointMock, getWorkWithTranscriptionsMock],
    });

    await screen.findByTestId("radio-download-type");
    fireEvent.click(screen.getByDisplayValue("transcriptions"));
    fireEvent.click(screen.getByTestId("download-transcriptions-button"));

    expect(capturedBlob).not.toBeNull();
    const text = await capturedBlob.text();
    expect(text).toContain("===== FS-ACC-001 =====");
    expect(text).toContain("Page one text.");
    expect(text).toContain("===== FS-ACC-002 =====");
    expect(text).toContain("Page two text.");
  });
});
