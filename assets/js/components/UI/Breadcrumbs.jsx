import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import CheveronRightIcon from "../../../css/fonts/zondicons/cheveron-right.svg";

const Breadcrumbs = ({ crumbs = [] }) => (
  <ul className="text-xl mb-4" data-testid="breadcrumbs">
    {crumbs.map(({ label, link, labelWithoutLink }, i) => (
      <li className="inline-block" key={label}>
        {labelWithoutLink && (
          <span className="mr-1 font-light text-gray-600">
            {labelWithoutLink}
          </span>
        )}
        <Link to={link}>{label}</Link>
        {i !== crumbs.length - 1 && (
          <span className="px-4">
            <CheveronRightIcon className="icon" />
          </span>
        )}
      </li>
    ))}
  </ul>
);

Breadcrumbs.propTypes = {
  crumbs: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      link: PropTypes.string,
      labelWithoutLink: PropTypes.string
    })
  )
};

export default Breadcrumbs;
