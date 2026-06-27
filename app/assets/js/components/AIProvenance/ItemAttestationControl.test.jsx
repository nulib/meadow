import React from "react";
import { fireEvent, waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { ItemAttestation } from "./ItemAttestationControl";
import { isItemAttestable } from "./Attestation";
import { ATTEST_HUMAN_AUTHORED_METADATA } from "../Work/work.gql";

describe("isItemAttestable", () => {
  it("is true for AI-involved origins", () => {
    expect(isItemAttestable("ai_generated")).toBe(true);
    expect(isItemAttestable("ai_assisted_human_modified")).toBe(true);
  });

  it("is false for already-attested or human origins", () => {
    expect(isItemAttestable("human_attested_after_ai")).toBe(false);
    expect(isItemAttestable("human_generated")).toBe(false);
    expect(isItemAttestable(undefined)).toBe(false);
  });
});

describe("ItemAttestation", () => {
  const props = {
    workId: "work-1",
    fieldPath: "descriptive_metadata.subject",
    itemId: "https://example.com/term1",
  };

  it("renders nothing for an item that is not attestable", () => {
    const { queryByTestId } = renderWithRouterApollo(
      <ItemAttestation origin="human_attested_after_ai" {...props} />,
      { mocks: [] },
    );
    expect(queryByTestId("item-attestation-trigger")).not.toBeInTheDocument();
  });

  it("attests a single item with its reason via the mutation", async () => {
    let attestedWith = null;
    const attestMock = {
      request: {
        query: ATTEST_HUMAN_AUTHORED_METADATA,
        variables: {
          workId: "work-1",
          fieldPaths: ["descriptive_metadata.subject"],
          itemIds: ["https://example.com/term1"],
          reason: "Verified against authority record",
        },
      },
      result: (variables) => {
        attestedWith = variables;
        return { data: { attestHumanAuthoredMetadata: { id: "work-1" } } };
      },
    };

    const { getByTestId } = renderWithRouterApollo(
      <ItemAttestation origin="ai_generated" {...props} />,
      { mocks: [attestMock] },
    );

    fireEvent.click(getByTestId("item-attestation-trigger"));
    fireEvent.change(getByTestId("item-attestation-reason"), {
      target: { value: "Verified against authority record" },
    });
    fireEvent.click(getByTestId("item-attestation-confirm"));

    await waitFor(() => expect(attestedWith).not.toBeNull());
  });
});
