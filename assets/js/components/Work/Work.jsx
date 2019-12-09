import React from "react";
import { Link } from "react-router-dom";

const Work = ({ work }) => {
  const fileSetsToDisplay = 5;

  return (
    <>
      <dl data-testid="work">
        <dt>ID:</dt>
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
    </>
  );
};

export default Work;
