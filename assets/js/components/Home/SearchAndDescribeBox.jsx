import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";

function HomeSearchAndDescribeBox(props) {
  return (
    <>
      <div className="is-flex mb-4 is-align-items-center">
        <FontAwesomeIcon icon="search" size="4x" />
        <h2 className="subtitle is-3 pl-3">Search &amp; Describe Objects</h2>
      </div>
      <Link className="button is-fullwidth is-large" to="/search">
        Search All Works
      </Link>
    </>
  );
}

HomeSearchAndDescribeBox.propTypes = {};

export default HomeSearchAndDescribeBox;
