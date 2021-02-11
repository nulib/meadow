import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

function ChartsGoogleAnalytics(props) {
  return (
    <div>
      <div className="is-flex is-justify-content-space-between">
        <h3 className="subtitle is-3">
          Digital Collections traffic last 30 days
        </h3>
        <Link to="/dashboards/analytics" className="button">
          View GA Dashboard
        </Link>
      </div>

      <iframe
        width="100%"
        height="250"
        src="https://datastudio.google.com/embed/reporting/203ba83b-85d7-42a5-ae10-afaa85f7dab0/page/FW7"
        frameBorder="0"
      />
    </div>
  );
}

ChartsGoogleAnalytics.propTypes = {};

export default ChartsGoogleAnalytics;
