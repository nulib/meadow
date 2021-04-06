import React from "react";
import { Link } from "react-router-dom";
import { IconSearch } from "@js/components/Icon";

function HomeSearchAndDescribeBox(props) {
  return (
    <div className="has-text-centered pt-6">
      <Link className="button is-large is-primary" to="/search">
        <span className="icon">
          <IconSearch />
        </span>
        <span>Search &amp; describe objects</span>
      </Link>
    </div>
  );
}

HomeSearchAndDescribeBox.propTypes = {};

export default HomeSearchAndDescribeBox;
