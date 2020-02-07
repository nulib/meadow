import React from "react";
import UserTopNav from "./UserTopNav";
import { Link } from "react-router-dom";

const UIHeaderNav = ({ currentUser }) => (
  <ul data-testid="header-nav" className="">
    <li className="">
      <Link to="/">Meadow v1.0</Link>
    </li>
    <li>
      <UserTopNav currentUser={currentUser} />
    </li>
  </ul>
);

export default UIHeaderNav;
