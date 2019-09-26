import React from "react";
import UIAlert from "../../UI/Alert";
import UIProgressBar from "../../UI/UIProgressBar";
import { withRouter, Link } from "react-router-dom";

const IngestSheetStatusApprovedInProgress = ({ match }) => {
  const {
    params: { id, ingestSheetId }
  } = match;

  return (
    <section>
      <div className="p-4 bg-yellow-100 text-sm">
        <Link to={`/project/${id}/ingest-sheet/${ingestSheetId}`}>Go Back</Link>
      </div>
      <h2>Ingest Sheet - Approved In Progress</h2>
      <p>
        Guessing once the use hits approve, could the API expose an "approved"
        flag the front-end can reference?{" "}
      </p>
      <UIAlert
        type="success"
        body="Ingest sheet has been approved and skeleton works are being created"
        title="Ingest sheet approved"
      />
      <div className="pt-12">
        <UIProgressBar percentComplete={50} label="works being created" />
      </div>
      <div className="text-center leading-loose text-gray-600">
        <p>48 works are being created</p>
        <p>370 file sets are being created</p>
        <p>What other info goes here?</p>
      </div>
    </section>
  );
};

export default withRouter(IngestSheetStatusApprovedInProgress);
