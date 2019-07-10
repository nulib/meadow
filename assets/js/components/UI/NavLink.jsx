import React from "react";
import { Link } from "react-router-dom";

const NavLink = ({ url, title }) => (
  <Link to={url} className="block mt-4 lg:inline-block lg:mt-0 mr-4">
    {title}
  </Link>
);

export default NavLink;
