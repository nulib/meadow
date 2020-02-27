import React from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { INGEST_SHEET_EXPORT_CSV } from "../ingestSheet.query";
import { CSVLink } from "react-csv";
import Error from "../../UI/Error";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const IngestSheetDownload = ({ sheetId }) => {
  const { loading, error, data } = useQuery(INGEST_SHEET_EXPORT_CSV, {
    variables: { id: sheetId }
  });

  if (loading) return "Loading...";
  if (error) return <Error error={error.message} />;

  const works = data.ingestSheetWorks;

  //Temporary. Ultimately CSV prep will be handled on the backend.
  const reformattedWorks = works.map(work => {
    let rWork = {};

    try {
      rWork.accession_number = work.accessionNumber;
      rWork.id = work.id;
      rWork.visibility = work.visibility;
      rWork.workype = work.workType;
      rWork.title = work.descriptiveMetadata
        ? work.descriptiveMetadata.title
        : "";
      rWork.description = work.descriptiveMetadata
        ? work.descriptiveMetadata.description
        : "";
    } catch (e) {
      console.log(
        "Error attemping to put together works for CSV download file",
        e
      );
    }

    return rWork;
  });

  return (
    <>
      {works.length > 0 && (
        <CSVLink
          data={reformattedWorks}
          filename={`ingest_sheet_${sheetId}.csv`}
          className="button"
          target="_blank"
        >
          <span className="icon">
            <FontAwesomeIcon icon="file-download" />
          </span>
          <span>Download .csv</span>
        </CSVLink>
      )}
    </>
  );
};

IngestSheetDownload.propTypes = {
  sheetId: PropTypes.string
};
export default IngestSheetDownload;
