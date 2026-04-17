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
    { variables: { id: sheetId } }
  );

  if (!canApprove) {
    return (
      <Notification>
        This AI ingest sheet is awaiting supermanager approval before ingesting.
      </Notification>
    );
  }

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
            This AI-enhanced ingest has an estimated cost of <strong>${aiCostEstimate.toFixed(2)}</strong> based 
            on the cost of the preview generation. The actual cost may vary.
          </p>
        </div>
      )}

      {aiPreview && aiPreview.length > 0 && (
        <div className="mb-5">
          <h2 className="title is-5">AI-Generated Previews</h2>
          <div className="columns is-multiline">
            {aiPreview.map((preview) => (
              <div
                key={preview.work_accession_number}
                className="column is-one-third"
              >
                <div className="card">
                  {preview.thumbnail && (
                    <div className="card-image">
                      <figure className="image">
                        <img
                          src={`data:image/jpeg;base64,${preview.thumbnail}`}
                          alt={preview.work_accession_number}
                        />
                      </figure>
                    </div>
                  )}
                  <div className="card-content">
                    <p className="subtitle is-6 mb-2">
                      <strong>{preview.work_accession_number}</strong>
                    </p>
                    <p className="heading">Description</p>
                    <p className="is-size-7 mb-3">{preview.description}</p>
                    {preview.subjects && preview.subjects.length > 0 && (
                      <>
                        <p className="heading">Subjects</p>
                        <ul>
                          {preview.subjects.map((subject) => (
                            <li key={subject.id} className="is-size-7">
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
                      </>
                    )}
                  </div>
                </div>
              </div>
            ))}
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
