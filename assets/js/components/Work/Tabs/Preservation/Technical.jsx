import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";

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
    return Object.keys(value).join(", ");
  }
  return value;
}

function WorkTabsPreservationTechnical({
  fileSet = {},
  handleClose,
  isVisible,
}) {
  const { metadata } = fileSet;
  const exifData = metadata && metadata.exif ? JSON.parse(metadata.exif) : null;

  return (
    <div
      className={`modal ${isVisible ? "is-active" : ""}`}
      css={modalCss}
      data-testid="technical-metadata"
    >
      <div className="modal-background"></div>
      <div className="modal-content content">
        <div className="box">
          <h2 className="title">Technical Metadata</h2>
          {!exifData && (
            <p data-testid="no-data-notification">
              No technical metadata exists for this File Set
            </p>
          )}
          {exifData && (
            <dl>
              {Object.keys(exifData).map((key) => (
                <div key={key}>
                  <dt>{key}</dt>
                  <dd>
                    <TechDataDisplay value={exifData[key]} />
                  </dd>
                </div>
              ))}
            </dl>
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
