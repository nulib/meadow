import React from "react";
import { render, fireEvent } from "@testing-library/react";
import { FormProvider, useForm } from "react-hook-form";
import {
  AttestationProvider,
  HumanAuthoredFieldControl,
  useAttestation,
  isAttestable,
} from "./Attestation";

// Surfaces the current attestation state so tests can assert what would be
// submitted with the work update.
function StateProbe() {
  const { attestationsInput } = useAttestation();
  return (
    <div data-testid="attestations">
      {JSON.stringify(attestationsInput() ?? [])}
    </div>
  );
}

function Harness({ entry, originalValue }) {
  const methods = useForm({ defaultValues: { title: originalValue } });
  return (
    <AttestationProvider>
      <FormProvider {...methods}>
        <input data-testid="title-input" {...methods.register("title")} />
        <HumanAuthoredFieldControl
          entry={entry}
          name="title"
          originalValue={originalValue}
        />
      </FormProvider>
      <StateProbe />
    </AttestationProvider>
  );
}

const aiEntry = {
  fieldPath: "descriptive_metadata.title",
  origin: "ai_generated",
  status: "applied",
};

describe("isAttestable", () => {
  it("is true for live AI-involved fields", () => {
    expect(isAttestable(aiEntry)).toBe(true);
  });

  it("is false for already-attested, human, deleted, or missing entries", () => {
    expect(isAttestable(undefined)).toBe(false);
    expect(
      isAttestable({ origin: "human_attested_after_ai", status: "applied" }),
    ).toBe(false);
    expect(isAttestable({ origin: "human_generated", status: "applied" })).toBe(
      false,
    );
    expect(isAttestable({ origin: "ai_generated", status: "deleted" })).toBe(
      false,
    );
  });
});

describe("HumanAuthoredFieldControl", () => {
  it("renders nothing for a non-AI field", () => {
    const { queryByTestId } = render(
      <Harness
        entry={{ origin: "human_generated", status: "applied" }}
        originalValue="A title"
      />,
    );
    expect(queryByTestId("human-authored-control")).toBeNull();
  });

  it("attests directly (no modal) when the value has been changed", () => {
    const { getByTestId, queryByTestId } = render(
      <Harness entry={aiEntry} originalValue="AI title" />,
    );

    // Edit the field so the current value differs from the AI value.
    fireEvent.change(getByTestId("title-input"), {
      target: { value: "Cataloger title" },
    });

    fireEvent.click(getByTestId("human-authored-checkbox"));

    // Different value -> no confirmation friction, attestation recorded.
    expect(queryByTestId("attestation-same-value-modal")).toBeNull();
    expect(getByTestId("attestations")).toHaveTextContent(
      "descriptive_metadata.title",
    );
  });

  it("confirms before attesting an unchanged value and then records it", () => {
    const { getByTestId } = render(
      <Harness entry={aiEntry} originalValue="AI title" />,
    );

    fireEvent.click(getByTestId("human-authored-checkbox"));
    // Same value -> confirmation modal, nothing recorded yet.
    expect(getByTestId("attestation-same-value-modal")).toBeInTheDocument();
    expect(getByTestId("attestations")).toHaveTextContent("[]");

    fireEvent.click(getByTestId("attestation-confirm"));
    expect(getByTestId("attestations")).toHaveTextContent(
      "descriptive_metadata.title",
    );
  });

  it("clears the attestation when unchecked", () => {
    const { getByTestId } = render(
      <Harness entry={aiEntry} originalValue="AI title" />,
    );

    fireEvent.click(getByTestId("human-authored-checkbox"));
    fireEvent.click(getByTestId("attestation-confirm"));
    expect(getByTestId("attestations")).toHaveTextContent(
      "descriptive_metadata.title",
    );

    fireEvent.click(getByTestId("human-authored-checkbox"));
    expect(getByTestId("attestations")).toHaveTextContent("[]");
  });
});
