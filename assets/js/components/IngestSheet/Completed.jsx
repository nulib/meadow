import React from "react";
import { withRouter } from "react-router-dom";
import WorkRow from "./WorkRow";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { MOCK_INGEST_SHEET_COMPLETED } from "./ingestSheet.query";
import Error from "../UI/Error";

const IngestSheetStatusCompleted = ({ ingestSheetId }) => {
  const { loading, error, data } = useQuery(MOCK_INGEST_SHEET_COMPLETED, {
    variables: { id: ingestSheetId }
  });

  if (loading) return "Loading...";
  if (error) return <Error error={error} />;

  const { works = [] } = data.mockIngestSheet;

  return (
    <section>
      {works.length > 0 &&
        works.map(work => <WorkRow key={work.id} work={work} />)}
    </section>
  );
};

IngestSheetStatusCompleted.propTypes = {
  ingestSheetId: PropTypes.string
};

export default IngestSheetStatusCompleted;
