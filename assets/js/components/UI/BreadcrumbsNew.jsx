import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import HomeIcon from "../../../css/fonts/zondicons/home.svg";

const Breadcrumbs = ({ crumbs = [] }) => {
  if (crumbs.length === 0) {
    return null;
  }
  return (
    <div className="breadcrumb flat mb-2" data-testid="breadcrumbs">
      <Link to="/">
        <HomeIcon className="icon"></HomeIcon>
      </Link>
      {crumbs.map(({ label, link }, i) => (
        <Link key={`${label}-${i}`} to={link}>
          {label}
        </Link>
      ))}
    </div>
  );
};

Breadcrumbs.propTypes = {
  crumbs: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      link: PropTypes.string
    })
  )
};

export default Breadcrumbs;
