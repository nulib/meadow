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
});
