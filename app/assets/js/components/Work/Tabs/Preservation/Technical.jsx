import React from "react";
import PropTypes from "prop-types";
import useTechnicalMetadata from "@js/hooks/useTechnicalMetadata";
import useFileSet from "@js/hooks/useFileSet";

function TechDataDisplay({ value }) {
  if (typeof value === "object") {
    if (value === null) {
      return "--";
    } else {
      return Object.keys(value).join(", ");
    }
  }
  return value;
}

function DefinitionList({ obj }) {
  return (
    <dl>
      {Object.keys(obj).map((key) => (
        <div key={key}>
          <dt>{key}</dt>
          <dd>
            <TechDataDisplay value={obj[key]} />
          </dd>
        </div>
      ))}
    </dl>
  );
}

function WorkTabsPreservationTechnical({ fileSet = {} }) {
  const { getTechnicalMetadata } = useTechnicalMetadata();
  const { isImage, isMedia } = useFileSet();
  const techMetadata = getTechnicalMetadata(fileSet);

  return (
    <div
      style={{ marginTop: "0.5rem", textAlign: "left" }}
      data-testid="technical-metadata"
    >
      {!techMetadata && (
        <p data-testid="no-data-notification">
          No technical metadata exists for this File Set
        </p>
      )}

      {/* Display Image technical metadata */}
      {techMetadata && isImage(fileSet) && (
        <DefinitionList obj={{ ...techMetadata }} />
      )}

      {/* Display Media technical metadata */}
      {techMetadata && isMedia(fileSet) && (
        <>
          <h4>{techMetadata[0]["@type"]}</h4>
          <DefinitionList obj={techMetadata[0]} />

          <h4>{techMetadata[1]["@type"]}</h4>
          <DefinitionList obj={techMetadata[1]} />
        </>
      )}
    </div>
  );
}

WorkTabsPreservationTechnical.propTypes = {
  fileSet: PropTypes.object,
};

export default WorkTabsPreservationTechnical;
