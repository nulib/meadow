import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";

function HomeSearchAndDescribeBox(props) {
  return (
    <>
      <FontAwesomeIcon icon="search" size="4x" />
      <h2 className="subtitle is-4 pt-3">Search &amp; Describe Objects</h2>
      <Link className="button is-fullwidth" to="/search">
        Search All Works
      </Link>
    </>
  );
}

HomeSearchAndDescribeBox.propTypes = {};

export default HomeSearchAndDescribeBox;
