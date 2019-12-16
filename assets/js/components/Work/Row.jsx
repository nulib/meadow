import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import Work from "./Work";
import UICard from "../UI/Card";

const WorkRow = ({ work }) => {
  const fileSetsToDisplay = 5;

  return (
    <UICard>
      <div data-testid="work-row" className="w-full flex py-4">
        <div className="w-1/4">
          <Link to={`/work/${work.id}`}>
            <img src="/images/placeholder-content.png" />
          </Link>
        </div>
        <div className="w-3/4 pl-4">
          <dl data-testid="work">
            <dd>
              <Link to={`/work/${work.id}`}>{work.id}</Link>
            </dd>
            <dt>Accession Number:</dt>
            <dd>{work.accessionNumber}</dd>
            <dt>Work Type:</dt>
            <dd>{work.workType}</dd>
            <dt>Visibility:</dt>
            <dd>{work.visibility}</dd>
            <dt>File Sets:</dt>
            {work.fileSets && (
              <dd>
                <ul>
                  <li className="italic">{work.fileSets.length} total</li>
                  {work.fileSets.map((fileSet, i) =>
                    i < fileSetsToDisplay - 1 ? (
                      <li key={fileSet.id}>
                        {fileSet.accessionNumber} -{" "}
                        {fileSet.metadata &&
                          fileSet.metadata.description &&
                          fileSet.metadata.description}
                      </li>
                    ) : null
                  )}
                </ul>
              </dd>
            )}
          </dl>
        </div>
      </div>
    </UICard>
  );
};

WorkRow.propTypes = {
  work: PropTypes.object
};

export default WorkRow;
