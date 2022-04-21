import PropTypes from "prop-types";
import React, { useEffect } from "react";
import { START_VALIDATION } from "./ingestSheet.gql";
import { useMutation } from "@apollo/client";
import IngestSheetReport from "./Report";

function IngestSheetValidations({ sheetId, status }) {
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);
  const isValidating = status === "UPLOADED";

  useEffect(() => {
    startValidation({ variables: { id: sheetId } });
  }, []);

  return (
    <section>
      {isValidating ? (
        <React.Fragment>
          <p className="has-text-centered mb-5">Validating ingest sheet...</p>
          <progress className="progress is-small is-primary" max="100">
            30%
          </progress>
        </React.Fragment>
      ) : (
        <IngestSheetReport status={status} sheetId={sheetId} />
      )}
    </section>
  );
}

IngestSheetValidations.propTypes = {
  sheetId: PropTypes.string.isRequired,
  status: PropTypes.string.isRequired,
};
export default IngestSheetValidations;
