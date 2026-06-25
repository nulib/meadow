import React from "react";
import { render, screen } from "@testing-library/react";
import UIFormFieldArrayDisplay from "./FieldArrayDisplay";

const values = ["Metadata item #1", "Metadata item #2", "Metadata item #3"];
const props = {
  values,
  isFacetLink: false,
  metadataItem: {
    name: "boxNumber",
    facetComponentId: "BoxNumber",
    label: "Box Number",
    metadataClass: "descriptive",
  },
};

describe("UIFormFieldArrayDisplay", () => {
  it("renders the label", () => {
    const { getByTestId } = render(<UIFormFieldArrayDisplay {...props} />);
    expect(getByTestId("items-label"));
  });

  it("renders an expected list of metadata values", () => {
    const { getByTestId, getByText } = render(
      <UIFormFieldArrayDisplay {...props} />,
    );
    const listEl = getByTestId("field-array-item-list");
    expect(listEl);
    expect(listEl.children).toHaveLength(3);
    expect(getByText("Metadata item #1"));
    expect(getByText("Metadata item #2"));
    expect(getByText("Metadata item #3"));
  });

  it("does not render a link by default", () => {
    render(<UIFormFieldArrayDisplay {...props} isFacetLink={false} />);
    expect(screen.getByText("Metadata item #1").nodeName).toEqual("LI");
  });

  it("renders the item as a link if configured", () => {
    render(<UIFormFieldArrayDisplay {...props} isFacetLink={true} />);
    expect(screen.getByText("Metadata item #1").nodeName).toEqual("A");
  });

  it("badges only the values that carry AI provenance", () => {
    render(
      <UIFormFieldArrayDisplay
        {...props}
        provenance={{
          origin: "ai_assisted_human_modified",
          status: "applied",
          itemProvenance: [{ id: values[0], origin: "ai_generated" }],
        }}
      />,
    );
    const badges = screen.getAllByTestId("provenance-origin-badge");
    // Only value[0] matches the AI's proposed id; value[1]/value[2] were
    // human-added or since-edited, so they carry no AI attribution and are
    // intentionally left unbadged. The field-level badge is suppressed because
    // at least one value is badged individually.
    expect(badges).toHaveLength(1);
    expect(badges[0]).toHaveTextContent("AI generated");
  });

  it("badges an edited AI item with its reconciled origin", () => {
    // The backend keys item provenance by each item's *current* value, so an
    // AI item a human edited in place still matches a value and keeps a badge —
    // now reflecting the human edit rather than disappearing.
    render(
      <UIFormFieldArrayDisplay
        {...props}
        provenance={{
          origin: "ai_assisted_human_modified",
          status: "applied",
          itemProvenance: [
            { id: values[0], origin: "ai_generated" },
            { id: values[1], origin: "ai_assisted_human_modified" },
          ],
        }}
      />,
    );
    const badges = screen.getAllByTestId("provenance-origin-badge");
    // value[0] unchanged AI, value[1] edited AI, value[2] human-added (unbadged).
    expect(badges).toHaveLength(2);
    expect(badges[0]).toHaveTextContent("AI generated");
    expect(badges[1]).toHaveTextContent("AI + human edited");
  });

  it("renders a single field-level badge when there is no per-item provenance", () => {
    render(
      <UIFormFieldArrayDisplay
        {...props}
        provenance={{ origin: "ai_generated", status: "applied" }}
      />,
    );
    const badges = screen.getAllByTestId("provenance-origin-badge");
    expect(badges).toHaveLength(1);
    expect(badges[0]).toHaveTextContent("AI generated");
  });

  it("renders no badges without provenance", () => {
    render(<UIFormFieldArrayDisplay {...props} />);
    expect(screen.queryByTestId("provenance-origin-badge")).toBeNull();
  });
});
