import React from "react";
import UILoader from "@js/components/UI/Loader";

function GeneratingAIPreview() {
  return (
    <div className="box">
      <div className="plan-placeholder">
        <UILoader />
        <span className="plan-panel-changes--loading--message">
          Generating Preview for AI Ingest
        </span>
        <p style={{ marginTop: "1rem", color: "#666", fontSize: "0.9rem" }}>
          This may take a few moments. Please do not navigate away from this
          page.
        </p>
      </div>
    </div>
  );
}

export default GeneratingAIPreview;
