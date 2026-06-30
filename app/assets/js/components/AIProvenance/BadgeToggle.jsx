import React from "react";
import { FaEye, FaEyeSlash } from "react-icons/fa";
import IconText from "@js/components/UI/IconText";
import { useAIProvenanceBadges } from "@js/context/ai-provenance-context";

/**
 * Menu item that toggles whether AI provenance badges are shown throughout the
 * app. Lives in the User dropdown so it reads as a personal display
 * preference. Hiding the badges is purely visual — the provenance data and the
 * dedicated Provenance views are unaffected.
 */
function AIProvenanceBadgeToggle() {
  const { visible, toggle } = useAIProvenanceBadges();
  return (
    <a
      role="menuitem"
      onClick={toggle}
      data-testid="ai-provenance-badge-toggle"
      aria-pressed={visible}
      title={
        visible
          ? "Hide AI provenance badges throughout the app"
          : "Show AI provenance badges throughout the app"
      }
    >
      <IconText icon={visible ? <FaEyeSlash /> : <FaEye />}>
        {visible ? "Hide AI provenance badges" : "Show AI provenance badges"}
      </IconText>
    </a>
  );
}

AIProvenanceBadgeToggle.propTypes = {};

export default AIProvenanceBadgeToggle;
