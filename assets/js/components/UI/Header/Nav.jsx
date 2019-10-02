import React from "react";
import UserTopNav from "./UserTopNav";
import { Link } from "react-router-dom";

const UIHeaderNav = ({ currentUser }) => (
  <ul
    data-testid="header-nav"
    className="md:flex md:items-center md:justify-end md:w-1/3 px-6 text-gray-500"
  >
    <li className="pr-4">
      <Link to="/">Meadow v1.0</Link>
    </li>
    <li>
      <UserTopNav currentUser={currentUser} />
    </li>
  </ul>
);

export default UIHeaderNav;
