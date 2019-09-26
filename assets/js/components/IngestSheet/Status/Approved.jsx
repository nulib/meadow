import React from "react";
import { withRouter, Link } from "react-router-dom";
import WorkRow from "./WorkRow";

const IngestSheetStatusApproved = ({ match }) => {
  const {
    params: { id, ingestSheetId }
  } = match;

  return (
    <section>
      <div className="p-4 bg-yellow-100 text-sm mb-12">
        <Link to={`/project/${id}/ingest-sheet/${ingestSheetId}`}>Go Back</Link>
      </div>
      <h2>IngestSheet - Approved</h2>
      <WorkRow />
      <WorkRow />
      <WorkRow />
      <WorkRow />
    </section>
  );
};

export default withRouter(IngestSheetStatusApproved);
