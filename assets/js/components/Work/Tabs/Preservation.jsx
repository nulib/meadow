import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";

const WorkTabsPreservation = ({ work }) => {
  return (
    <>
      <UITabsStickyHeader title="Preservation and Access Masters" />
      <div className="box mt-4">
        <table className="table is-fullwidth is-striped is-hoverable is-fixed">
          <thead>
            <tr>
              <th>Role</th>
              <th>Filename</th>
              <th>Checksum</th>
              <th>s3 Key</th>
              <th>Verified</th>
              <DisplayAuthorized action="delete">
                <th className="has-text-right">Actions</th>{" "}
              </DisplayAuthorized>
            </tr>
          </thead>
          <tbody>
            {work.fileSets &&
              work.fileSets.map((fileset) => {
                const metadata = fileset.metadata;
                return (
                  <tr key={fileset.id}>
                    <td>{fileset.role}</td>
                    <td className="break-word">
                      {metadata ? metadata.originalFilename : " "}
                    </td>
                    <td className="break-word">
                      {metadata ? metadata.sha256 : ""}
                    </td>
                    <td className="break-word">
                      {metadata ? metadata.location : ""}
                    </td>
                    <td>
                      <UITagNotYetSupported label="Display not yet supported" />
                    </td>
                    <DisplayAuthorized action="delete">
                      <td>
                        <div className="buttons-end">
                          <button className="button">
                            <FontAwesomeIcon icon="trash" />
                          </button>
                        </div>
                      </td>
                    </DisplayAuthorized>
                  </tr>
                );
              })}
          </tbody>
        </table>
      </div>
    </>
  );
};

WorkTabsPreservation.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsPreservation;
