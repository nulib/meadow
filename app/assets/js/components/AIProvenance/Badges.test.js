import React from "react";
import { render } from "@testing-library/react";
import {
  OriginBadge,
  StatusPill,
  ProvenancePreviewBadge,
  ProvenanceEventValues,
  ProvenanceValue,
  AnnotationOriginBadge,
  FieldProvenanceBadge,
  annotationOrigin,
  fieldProvenance,
  predictedOrigin,
  previewOrigin,
  provenanceByFieldPath,
  provenanceTooltip,
  valueItemIds,
} from "./Badges";

describe("AIProvenance Badges", () => {
  it("renders a known origin with its friendly label", () => {
    const { getByTestId } = render(<OriginBadge origin="ai_generated" />);
    const badge = getByTestId("provenance-origin-badge");
    expect(badge).toHaveTextContent("AI generated");
    expect(badge).toHaveClass("is-info");
  });

  it("falls back to a humanized label for unknown origins", () => {
    const { getByTestId } = render(<OriginBadge origin="some_new_origin" />);
    expect(getByTestId("provenance-origin-badge")).toHaveTextContent(
      "Some New Origin",
    );
  });

  it("renders nothing when origin is missing", () => {
    const { queryByTestId } = render(<OriginBadge />);
    expect(queryByTestId("provenance-origin-badge")).not.toBeInTheDocument();
  });

  it("labels an AI modification of human content as 'AI edited'", () => {
    const { getByTestId } = render(
      <OriginBadge origin="ai_modified_human_content" />,
    );
    const badge = getByTestId("provenance-origin-badge");
    expect(badge).toHaveTextContent("AI edited");
    expect(badge).toHaveClass("is-link");
  });

  describe("annotationOrigin / AnnotationOriginBadge", () => {
    it("returns null for an absent or not-yet-completed annotation", () => {
      expect(annotationOrigin(null)).toBeNull();
      expect(annotationOrigin({ status: "in_progress" })).toBeNull();
    });

    it("prefers the recorded AI provenance origin", () => {
      expect(
        annotationOrigin({
          status: "completed",
          aiProvenance: { origin: "ai_assisted_human_modified" },
        }),
      ).toBe("ai_assisted_human_modified");
    });

    it("treats a completed annotation with no provenance as human-authored", () => {
      expect(annotationOrigin({ status: "completed" })).toBe("human_generated");
    });

    it("badges an AI-generated transcription", () => {
      const { getByTestId } = render(
        <AnnotationOriginBadge
          annotation={{
            status: "completed",
            aiProvenance: { origin: "ai_generated" },
          }}
        />,
      );
      expect(getByTestId("provenance-origin-badge")).toHaveTextContent(
        "AI generated",
      );
    });

    it("renders nothing before a transcription is saved", () => {
      const { queryByTestId } = render(
        <AnnotationOriginBadge annotation={null} />,
      );
      expect(queryByTestId("provenance-origin-badge")).not.toBeInTheDocument();
    });
  });

  describe("valueItemIds", () => {
    it("extracts controlled-term ids from a wrapped value", () => {
      const value = {
        value: [
          { term: { id: "http://id/fast/1", label: "One" } },
          { term: { id: "http://id/fast/2", label: "Two" } },
        ],
      };
      expect(valueItemIds(value)).toEqual([
        "http://id/fast/1",
        "http://id/fast/2",
      ]);
    });

    it("handles bare string arrays", () => {
      expect(valueItemIds(["a", "b"])).toEqual(["a", "b"]);
    });
  });

  describe("fieldProvenance", () => {
    it("matches snake_case field paths from camelCase field names", () => {
      const provenance = {
        "descriptive_metadata.style_period": { origin: "ai_generated" },
      };
      expect(fieldProvenance(provenance, "stylePeriod")).toEqual({
        origin: "ai_generated",
      });
    });
  });

  describe("FieldProvenanceBadge", () => {
    it("badges a live AI-generated field", () => {
      const { getByTestId } = render(
        <FieldProvenanceBadge
          entry={{ origin: "ai_generated", status: "applied" }}
        />,
      );
      expect(getByTestId("provenance-origin-badge")).toHaveTextContent(
        "AI generated",
      );
    });

    it("renders nothing without an entry", () => {
      const { queryByTestId } = render(<FieldProvenanceBadge />);
      expect(queryByTestId("provenance-origin-badge")).not.toBeInTheDocument();
    });

    // Once a human removes the AI value, the field is empty and the
    // "Human replaced AI" label should not linger next to it.
    it("renders nothing for a deleted value", () => {
      const { queryByTestId } = render(
        <FieldProvenanceBadge
          entry={{
            origin: "human_replacement_after_ai_suggestion",
            status: "deleted",
          }}
        />,
      );
      expect(queryByTestId("provenance-origin-badge")).not.toBeInTheDocument();
    });

    it("renders nothing for rejected or failed values", () => {
      const rejected = render(
        <FieldProvenanceBadge
          entry={{ origin: "ai_generated", status: "rejected" }}
        />,
      );
      expect(
        rejected.queryByTestId("provenance-origin-badge"),
      ).not.toBeInTheDocument();

      const failed = render(
        <FieldProvenanceBadge
          entry={{ origin: "ai_generated", status: "failed" }}
        />,
      );
      expect(
        failed.queryByTestId("provenance-origin-badge"),
      ).not.toBeInTheDocument();
    });
  });

  it("renders a status pill with mapped color", () => {
    const { getByTestId } = render(<StatusPill status="applied" />);
    const pill = getByTestId("provenance-status-pill");
    expect(pill).toHaveTextContent("Applied");
    expect(pill).toHaveClass("is-success");
  });

  describe("predictedOrigin", () => {
    it("treats a replace over an existing value as a modification", () => {
      expect(predictedOrigin("replace", ["Old title"])).toBe(
        "ai_modified_human_content",
      );
    });

    it("treats an add (or empty prior) as generation", () => {
      expect(predictedOrigin("add", undefined)).toBe("ai_generated");
      expect(predictedOrigin("replace", [])).toBe("ai_generated");
      expect(predictedOrigin("replace", "")).toBe("ai_generated");
    });
  });

  describe("previewOrigin", () => {
    it("lets a recorded human edit win over the prediction", () => {
      expect(
        previewOrigin({
          recordedOrigin: "ai_assisted_human_modified",
          method: "replace",
          currentValue: ["Old"],
        }),
      ).toBe("ai_assisted_human_modified");
    });

    it("falls back to prediction when no human edit is recorded", () => {
      expect(
        previewOrigin({
          recordedOrigin: "ai_generated",
          method: "replace",
          currentValue: ["Old"],
        }),
      ).toBe("ai_modified_human_content");
    });
  });

  describe("ProvenancePreviewBadge", () => {
    it("shows 'AI + human edited' when a reviewer edited the suggestion", () => {
      const { getByTestId } = render(
        <ProvenancePreviewBadge
          method="replace"
          currentValue={["Old"]}
          recordedOrigin="ai_assisted_human_modified"
        />,
      );
      expect(getByTestId("provenance-preview")).toHaveTextContent(
        "AI + human edited",
      );
    });
  });

  describe("provenanceByFieldPath", () => {
    it("keys entries by field path and keeps the most recent", () => {
      const summary = [
        {
          fieldPath: "descriptive_metadata.description",
          origin: "ai_generated",
          generatedAt: "2026-01-01T00:00:00Z",
        },
        {
          fieldPath: "descriptive_metadata.description",
          origin: "ai_assisted_human_modified",
          generatedAt: "2026-02-01T00:00:00Z",
          appliedAt: "2026-02-02T00:00:00Z",
        },
      ];
      const map = provenanceByFieldPath(summary);
      expect(map["descriptive_metadata.description"].origin).toBe(
        "ai_assisted_human_modified",
      );
    });
  });

  describe("provenanceTooltip", () => {
    it("includes origin, model and reviewer", () => {
      const tip = provenanceTooltip({
        origin: "ai_generated",
        model: "claude-opus",
        reviewer: "jane",
        reviewedAt: "2026-01-15T00:00:00Z",
      });
      expect(tip).toContain("AI generated");
      expect(tip).toContain("claude-opus");
      expect(tip).toContain("jane");
    });
  });

  describe("ProvenanceEventValues", () => {
    it("shows the original AI value and the human-edited value", () => {
      const { getByTestId } = render(
        <ProvenanceEventValues
          valueBefore={{ value: "AI transcription text" }}
          valueAfter={{ value: "Human-corrected text" }}
        />,
      );
      const el = getByTestId("provenance-event-values");
      expect(el).toHaveTextContent("From: AI transcription text");
      expect(el).toHaveTextContent("To: Human-corrected text");
    });

    it("renders nothing when neither snapshot is present", () => {
      const { queryByTestId } = render(
        <ProvenanceEventValues valueBefore={null} valueAfter={null} />,
      );
      expect(queryByTestId("provenance-event-values")).toBeNull();
    });
  });

  describe("ProvenanceValue", () => {
    it("renders a related_url entry's coded-term label as text, not an object", () => {
      // Regression: the entry's `label` is a coded-term object, which React
      // refuses to render directly ("Objects are not valid as a React child").
      const { getByTestId } = render(
        <ProvenanceValue
          value={[
            {
              url: "https://www.library.northwestern.edu",
              label: {
                id: "RELATED_INFORMATION",
                label: "Related Information",
                scheme: "related_url",
              },
            },
          ]}
        />,
      );
      expect(getByTestId("provenance-value")).toHaveTextContent(
        "Related Information: https://www.library.northwestern.edu",
      );
    });

    it("renders a note entry with its coded type label", () => {
      const { getByTestId } = render(
        <ProvenanceValue
          value={[
            {
              note: "Condition is fragile",
              type: {
                id: "GENERAL_NOTE",
                label: "General Note",
                scheme: "note_type",
              },
            },
          ]}
        />,
      );
      expect(getByTestId("provenance-value")).toHaveTextContent(
        "General Note: Condition is fragile",
      );
    });
  });
});
