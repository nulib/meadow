import React from "react";
import PropTypes from "prop-types";

const IngestSheetWorkRow = ({ work }) => {
  const fileSetsToDisplay = 3;

  return (
    <>
      <div className="w-full flex py-4">
        <div className="w-1/3">
          <img src="/images/placeholder-content.png" />
        </div>
        <div className="w-2/3 pl-4">
          <dl>
            <dt>Accession Number:</dt>
            <dd>{work.accessionNumber}</dd>
            <dt>Work Type:</dt>
            <dd>{work.workType}</dd>
            <dt>Visibility:</dt>
            <dd>{work.visibility}</dd>
            <dt>File Sets:</dt>
            <dd>
              <ul>
                <li className="italic">{work.fileSets.length} total</li>
                {work.fileSets.map((fileSet, i) =>
                  i < fileSetsToDisplay - 1 ? (
                    <li key={fileSet.id}>
                      {fileSet.accessionNumber} - {fileSet.metadata.description}
                    </li>
                  ) : null
                )}
              </ul>
            </dd>
          </dl>
        </div>
      </div>
    </>
  );
};

IngestSheetWorkRow.propTypes = {
  work: PropTypes.object
};

export default IngestSheetWorkRow;
