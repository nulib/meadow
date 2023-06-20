import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { IconChart } from "@js/components/Icon";
import UIActionHeadline from "@js/components/UI/ActionHeadline";

function ChartsGoogleAnalytics(props) {
  return (
    <div>
      <UIActionHeadline>
        <>
          <h3 className="subtitle is-3">
            Digital Collections traffic last 30 days
          </h3>
          <Link to="/dashboards/analytics" className="button">
            <IconChart />
            <span>View GA Dashboard</span>
          </Link>
        </>
      </UIActionHeadline>

      <iframe
        className="is-hidden-mobile"
        width="100%"
        height="250"
        src="https://lookerstudio.google.com/embed/reporting/3bbe7b0d-0c8b-407b-9f8a-bf8121788ade/page/FW7"
      />
    </div>
  );
}

ChartsGoogleAnalytics.propTypes = {};

export default ChartsGoogleAnalytics;
