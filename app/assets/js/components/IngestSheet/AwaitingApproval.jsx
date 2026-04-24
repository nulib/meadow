import React, { useState } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client/react";
import { START_VALIDATION } from "./ingestSheet.gql";
import { Button, Notification } from "@nulib/design-system";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

function IngestSheetAwaitingApproval({ sheetId, aiCostEstimate, aiPreview }) {
  const [understood, setUnderstood] = useState(false);
  const { isAuthorized } = useIsAuthorized();
  const canApprove = isAuthorized("SUPERMANAGER");

  const [approveIngestSheet, { loading: approving }] = useMutation(
    START_VALIDATION,
    { variables: { id: sheetId } },
  );

  if (!canApprove) {
    return (
      <Notification>
        This AI ingest sheet is awaiting supermanager approval before ingesting.
      </Notification>
    );
  }

  console.log({ aiCostEstimate, aiPreview });

  return (
    <div>
      <Notification>
        This is an AI ingest sheet. Please review the work and fileset data
        below before approving.
      </Notification>

      {aiCostEstimate && (
        <div className="notification is-warning">
          <h2 className="title is-5">AI Cost Estimate</h2>
          <p>
            This AI-enhanced ingest has an estimated cost of{" "}
            <strong>${aiCostEstimate.toFixed(2)}</strong> based on the cost of
            the preview generation. The actual cost may vary.
          </p>
        </div>
      )}

      {aiPreview && aiPreview.length > 0 && (
        <div className="mb-5">
          <h2 className="title is-5">AI-Generated Previews</h2>
          <div className="table-container">
            <table className="table is-fullwidth is-striped">
              <thead>
                <tr>
                  <th style={{ width: "120px" }}>
                    <span className="is-sr-only">Thumbnail</span>
                  </th>
                  <th style={{ width: "200px" }}>Accession Number</th>
                  <th>Description</th>
                  <th style={{ minWidth: "240px" }}>Subject</th>
                </tr>
              </thead>
              <tbody>
                {aiPreview.map((preview) => (
                  <tr key={preview.work_accession_number}>
                    <td>
                      {preview.thumbnail && (
                        <figure
                          className="image"
                          style={{
                            width: "100px",
                            height: "100px",
                            margin: 0,
                          }}
                        >
                          <img
                            src={`data:image/jpeg;base64,${preview.thumbnail}`}
                            alt={preview.work_accession_number}
                            style={{
                              width: "100%",
                              height: "100%",
                              objectFit: "cover",
                              borderRadius: "0.25rem",
                            }}
                          />
                        </figure>
                      )}
                    </td>
                    <td>{preview.work_accession_number}</td>
                    <td>{preview.description}</td>
                    <td>
                      {preview.subjects && preview.subjects.length > 0 && (
                        <div className="content">
                          <ul style={{ marginTop: 0 }}>
                            {preview.subjects.map((subject) => (
                              <li key={subject.id}>
                                <a
                                  href={subject.id}
                                  target="_blank"
                                  rel="noreferrer"
                                >
                                  {subject.label}
                                </a>
                              </li>
                            ))}
                          </ul>
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <div className="field mt-5">
        <label className="checkbox">
          <input
            type="checkbox"
            checked={understood}
            onChange={(e) => setUnderstood(e.target.checked)}
            className="mr-2"
          />
          I understand that approving this AI-generated ingest sheet will
          immediately begin ingesting the listed works and filesets.
        </label>
      </div>

      <div className="mt-4">
        <Button
          isPrimary
          disabled={!understood || approving}
          onClick={approveIngestSheet}
        >
          Approve and Start Ingest
        </Button>
      </div>
    </div>
  );
}

IngestSheetAwaitingApproval.propTypes = {
  sheetId: PropTypes.string.isRequired,
  aiPreview: PropTypes.arrayOf(PropTypes.object),
};

export default IngestSheetAwaitingApproval;
