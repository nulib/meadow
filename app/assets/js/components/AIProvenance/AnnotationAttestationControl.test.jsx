import React from "react";
import { fireEvent, waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import AnnotationAttestationControl from "./AnnotationAttestationControl";
import { ATTEST_HUMAN_AUTHORED_ANNOTATION } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";

const aiAnnotation = {
  id: "annotation-1",
  aiProvenance: { origin: "ai_generated", status: "applied" },
};

describe("AnnotationAttestationControl", () => {
  it("renders nothing for an annotation that is not attestable", () => {
    const { queryByTestId } = renderWithRouterApollo(
      <AnnotationAttestationControl
        annotation={{
          id: "annotation-1",
          aiProvenance: {
            origin: "human_attested_after_ai",
            status: "applied",
          },
        }}
        workId="work-1"
      />,
      { mocks: [] },
    );
    expect(
      queryByTestId("annotation-attestation-trigger"),
    ).not.toBeInTheDocument();
  });

  it("renders nothing for an annotation with no AI provenance", () => {
    const { queryByTestId } = renderWithRouterApollo(
      <AnnotationAttestationControl
        annotation={{ id: "annotation-1", aiProvenance: null }}
        workId="work-1"
      />,
      { mocks: [] },
    );
    expect(
      queryByTestId("annotation-attestation-trigger"),
    ).not.toBeInTheDocument();
  });

  it("attests the annotation with its reason via the mutation", async () => {
    let attestedWith = null;
    const attestMock = {
      request: {
        query: ATTEST_HUMAN_AUTHORED_ANNOTATION,
        variables: {
          annotationId: "annotation-1",
          reason: "Verified against the image",
        },
      },
      result: (variables) => {
        attestedWith = variables;
        return {
          data: {
            attestHumanAuthoredAnnotation: {
              id: "annotation-1",
              fileSetId: "fs-1",
              aiProvenance: {
                origin: "human_attested_after_ai",
                status: "applied",
              },
            },
          },
        };
      },
    };

    const { getByTestId } = renderWithRouterApollo(
      <AnnotationAttestationControl
        annotation={aiAnnotation}
        workId="work-1"
      />,
      { mocks: [attestMock] },
    );

    fireEvent.click(getByTestId("annotation-attestation-trigger"));
    fireEvent.change(getByTestId("annotation-attestation-reason"), {
      target: { value: "Verified against the image" },
    });
    fireEvent.click(getByTestId("annotation-attestation-confirm"));

    await waitFor(() => expect(attestedWith).not.toBeNull());
  });

  it("does not show the autosave note when there are no unsaved changes", () => {
    const { getByTestId, queryByTestId } = renderWithRouterApollo(
      <AnnotationAttestationControl
        annotation={aiAnnotation}
        workId="work-1"
        hasUnsavedChanges={false}
        onBeforeAttest={jest.fn()}
      />,
      { mocks: [] },
    );

    fireEvent.click(getByTestId("annotation-attestation-trigger"));
    expect(
      queryByTestId("annotation-attestation-autosave-note"),
    ).not.toBeInTheDocument();
  });

  it("saves unsaved edits before attesting and shows the autosave note", async () => {
    let attested = false;
    let savedBeforeAttest = null;
    const onBeforeAttest = jest.fn(() => {
      savedBeforeAttest = !attested;
      return Promise.resolve();
    });

    const attestMock = {
      request: {
        query: ATTEST_HUMAN_AUTHORED_ANNOTATION,
        variables: { annotationId: "annotation-1" },
      },
      result: () => {
        attested = true;
        return {
          data: {
            attestHumanAuthoredAnnotation: {
              id: "annotation-1",
              fileSetId: "fs-1",
              aiProvenance: {
                origin: "human_attested_after_ai",
                status: "applied",
              },
            },
          },
        };
      },
    };

    const { getByTestId } = renderWithRouterApollo(
      <AnnotationAttestationControl
        annotation={aiAnnotation}
        workId="work-1"
        hasUnsavedChanges={true}
        onBeforeAttest={onBeforeAttest}
      />,
      { mocks: [attestMock] },
    );

    fireEvent.click(getByTestId("annotation-attestation-trigger"));
    expect(
      getByTestId("annotation-attestation-autosave-note"),
    ).toHaveTextContent(/unsaved edits will be saved automatically/i);

    fireEvent.click(getByTestId("annotation-attestation-confirm"));

    await waitFor(() => expect(attested).toBe(true));
    expect(onBeforeAttest).toHaveBeenCalledTimes(1);
    expect(savedBeforeAttest).toBe(true);
  });

  it("aborts the attestation when saving unsaved edits fails", async () => {
    let attested = false;
    const onBeforeAttest = jest.fn(() =>
      Promise.reject(new Error("save failed")),
    );

    const attestMock = {
      request: {
        query: ATTEST_HUMAN_AUTHORED_ANNOTATION,
        variables: { annotationId: "annotation-1" },
      },
      result: () => {
        attested = true;
        return {
          data: {
            attestHumanAuthoredAnnotation: {
              id: "annotation-1",
              fileSetId: "fs-1",
              aiProvenance: {
                origin: "human_attested_after_ai",
                status: "applied",
              },
            },
          },
        };
      },
    };

    const { getByTestId } = renderWithRouterApollo(
      <AnnotationAttestationControl
        annotation={aiAnnotation}
        workId="work-1"
        hasUnsavedChanges={true}
        onBeforeAttest={onBeforeAttest}
      />,
      { mocks: [attestMock] },
    );

    fireEvent.click(getByTestId("annotation-attestation-trigger"));
    fireEvent.click(getByTestId("annotation-attestation-confirm"));

    await waitFor(() => expect(onBeforeAttest).toHaveBeenCalled());
    // Give the (aborted) attest mutation a chance to fire if it was going to.
    await new Promise((resolve) => setTimeout(resolve, 50));
    expect(attested).toBe(false);
  });
});
