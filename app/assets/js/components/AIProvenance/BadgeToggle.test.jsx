import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import AIProvenanceBadgeToggle from "./BadgeToggle";
import { OriginBadge } from "./Badges";
import {
  AIProvenanceBadgesProvider,
  AIProvenanceBadgesAlwaysVisible,
} from "@js/context/ai-provenance-context";

function renderApp() {
  return render(
    <AIProvenanceBadgesProvider>
      <AIProvenanceBadgeToggle />
      <OriginBadge origin="ai_generated" />
      <AIProvenanceBadgesAlwaysVisible>
        <OriginBadge origin="human_generated" />
      </AIProvenanceBadgesAlwaysVisible>
    </AIProvenanceBadgesProvider>,
  );
}

describe("AIProvenanceBadgeToggle", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("shows badges and offers to hide them by default", () => {
    renderApp();
    // Both the gated inline badge and the always-visible one render.
    expect(screen.getAllByTestId("provenance-origin-badge")).toHaveLength(2);
    expect(screen.getByTestId("ai-provenance-badge-toggle")).toHaveTextContent(
      "Hide AI provenance badges",
    );
  });

  it("hides the gated badge and persists the preference when toggled off", () => {
    renderApp();
    fireEvent.click(screen.getByTestId("ai-provenance-badge-toggle"));

    // The gated inline badge disappears (the always-visible one remains)...
    expect(screen.queryByText("AI generated")).not.toBeInTheDocument();
    // ...the toggle now offers to show them again...
    expect(screen.getByTestId("ai-provenance-badge-toggle")).toHaveTextContent(
      "Show AI provenance badges",
    );
    // ...and the choice is persisted.
    expect(localStorage.getItem("aiProvenanceBadges")).toBe("hidden");
  });

  it("keeps badges in always-visible subtrees even when hidden globally", () => {
    renderApp();
    fireEvent.click(screen.getByTestId("ai-provenance-badge-toggle"));
    // The dedicated-view badge survives the global toggle.
    expect(screen.getByText("Human")).toBeInTheDocument();
  });

  it("starts hidden when the stored preference is 'hidden'", () => {
    localStorage.setItem("aiProvenanceBadges", "hidden");
    renderApp();
    // Only the always-visible badge renders.
    expect(screen.getAllByTestId("provenance-origin-badge")).toHaveLength(1);
    expect(screen.getByText("Human")).toBeInTheDocument();
  });
});
