import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import useTechnicalMetadata from "@js/hooks/useTechnicalMetadata";
import useFileSet from "@js/hooks/useFileSet";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const modalCss = css`
  z-index: 100;
  padding-top: 90px;
`;
const modalCloseButton = css`
  margin-top: 70px;
`;

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

function WorkTabsPreservationTechnical({
  fileSet = {},
  handleClose,
  isVisible,
}) {
  const { getTechnicalMetadata } = useTechnicalMetadata();
  const { isImage, isMedia } = useFileSet();
  const techMetadata = getTechnicalMetadata(fileSet);

  return (
    <div
      className={`modal ${isVisible ? "is-active" : ""}`}
      css={modalCss}
      data-testid="technical-metadata"
    >
      <div className="modal-background"></div>
      <div className="modal-content content">
        <div className="box">
          <h3>Technical Metadata</h3>
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

          <div className="buttons is-right">
            <Button isText onClick={handleClose}>
              Close
            </Button>
          </div>
        </div>
      </div>

      <button
        className="modal-close is-large"
        aria-label="close"
        css={modalCloseButton}
        onClick={handleClose}
      />
    </div>
  );
}

WorkTabsPreservationTechnical.propTypes = {
  fileSet: PropTypes.object,
  handleClose: PropTypes.func,
  isVisible: PropTypes.bool,
};

export default WorkTabsPreservationTechnical;
