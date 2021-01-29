import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";

function HomeSearchAndDescribeBox(props) {
  return (
    <div className="box has-text-centered content">
      <FontAwesomeIcon icon="search" size="4x" />
      <h2 className="title">Search &amp; Describe Objects</h2>
      <Link className="button" to="/search">
        Search All Works
      </Link>
    </div>
  );
}

HomeSearchAndDescribeBox.propTypes = {};

export default HomeSearchAndDescribeBox;
