import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const WorkTabsPreservation = ({ work }) => {
  return (
    <div className="columns is-centered">
      <div className="column">
        <table className="table is-fullwidth is-striped is-hoverable">
          <thead>
            <tr>
              <th>Role</th>
              <th>Filename</th>
              <th>Checksum</th>
              <th>s3 Key</th>
              <th>Verified</th>
              <th className="has-text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {work.fileSets &&
              work.fileSets.map(fileset => {
                const metadata = fileset.metadata;
                return (
                  <tr key={fileset.id}>
                    <td>{fileset.role}</td>
                    <td>{metadata ? metadata.originalFilename : " "}</td>
                    <td className="notification is-warning">
                      {metadata.sha256}
                    </td>
                    <td className="notification is-warning">
                      TODO: Need this exposed in GraphQL
                    </td>
                    <td className="notification is-warning">
                      TODO: Need this exposed in GraphQL
                    </td>
                    <td>
                      <div className="buttons-end">
                        <button className="button">
                          <FontAwesomeIcon icon="trash" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

WorkTabsPreservation.propTypes = {
  work: PropTypes.object
};

export default WorkTabsPreservation;
