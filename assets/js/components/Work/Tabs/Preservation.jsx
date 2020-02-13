import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const WorkTabsPreservation = ({ work }) => {
  return (
    <div className="columns is-centered" data-testid="tab-preservation-content">
      <div className="column">
        <p className="notification is-warning">
          TODO: wire this table up to GraphQL data
        </p>
        <table className="table is-fullwidth is-striped is-hoverable">
          <thead>
            <tr>
              <th>Role</th>
              <th>Filename</th>
              <th>Checksum</th>
              <th>s3 Key</th>
              <th>Verified</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>AM</td>
              <td>1234_12.tif</td>
              <td>ASDF09860986AS0986ASDF</td>
              <td>s3://asoyuoasd.com</td>
              <td>
                <FontAwesomeIcon icon="check" />
              </td>
              <td>
                <button className="button">
                  <FontAwesomeIcon icon="trash" />
                </button>
              </td>
            </tr>
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
