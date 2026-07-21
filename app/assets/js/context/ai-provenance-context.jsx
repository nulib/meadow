import React from "react";
import PropTypes from "prop-types";

/**
 * Global, per-user preference for whether AI provenance origin/status badges
 * are shown in the app. The badges are purely informational, so a user may
 * want to hide the visual clutter without changing any underlying behavior —
 * the provenance data and the dedicated Provenance views are unaffected.
 *
 * The preference is persisted to localStorage so it survives reloads and is
 * applied immediately (no page reload) via React state. The default context
 * value has badges visible, so components rendered without a provider (e.g. in
 * isolated tests) behave as before.
 */

const STORAGE_KEY = "aiProvenanceBadges";

const AIProvenanceBadgesContext = React.createContext({
  visible: true,
  toggle: () => {},
  setVisible: () => {},
});

function readStoredPreference() {
  try {
    // Absence of the key means "show" (the default); only an explicit
    // "hidden" turns the badges off.
    return localStorage.getItem(STORAGE_KEY) !== "hidden";
  } catch (e) {
    return true;
  }
}

function AIProvenanceBadgesProvider({ children }) {
  const [visible, setVisibleState] = React.useState(readStoredPreference);

  const setVisible = React.useCallback((next) => {
    setVisibleState(next);
    try {
      localStorage.setItem(STORAGE_KEY, next ? "shown" : "hidden");
    } catch (e) {
      // Ignore storage failures (e.g. privacy mode); the in-memory state
      // still drives the UI for this session.
    }
  }, []);

  const toggle = React.useCallback(() => {
    setVisible(!visible);
  }, [visible, setVisible]);

  const value = React.useMemo(
    () => ({ visible, toggle, setVisible }),
    [visible, toggle, setVisible],
  );

  return (
    <AIProvenanceBadgesContext.Provider value={value}>
      {children}
    </AIProvenanceBadgesContext.Provider>
  );
}

AIProvenanceBadgesProvider.propTypes = {
  children: PropTypes.node,
};

/**
 * Force AI provenance badges to be visible for a subtree regardless of the
 * user's global preference. Used by the dedicated Provenance views (the Work
 * "AI Provenance" tab and the provenance dashboards), where the badges are the
 * point of the page and hiding them would be confusing.
 */
function AIProvenanceBadgesAlwaysVisible({ children }) {
  const parent = React.useContext(AIProvenanceBadgesContext);
  const value = React.useMemo(() => ({ ...parent, visible: true }), [parent]);
  return (
    <AIProvenanceBadgesContext.Provider value={value}>
      {children}
    </AIProvenanceBadgesContext.Provider>
  );
}

AIProvenanceBadgesAlwaysVisible.propTypes = {
  children: PropTypes.node,
};

function useAIProvenanceBadges() {
  return React.useContext(AIProvenanceBadgesContext);
}

export {
  AIProvenanceBadgesContext,
  AIProvenanceBadgesProvider,
  AIProvenanceBadgesAlwaysVisible,
  useAIProvenanceBadges,
};
