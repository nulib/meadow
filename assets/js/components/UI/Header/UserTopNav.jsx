import React, { useState } from "react";
import PropTypes from "prop-types";
import { withRouter } from "react-router-dom";
import client from "../../../client";

const UIUserTopNav = ({ currentUser }) => {
  if (!currentUser) return null;

  const [dropdownOpen, setDropdownOpen] = useState(false);

  const handleClick = () => {
    client.resetStore();
    window.location.href = `/auth/logout`;
  };

  return (
    <div className="relative">
      <button onClick={() => setDropdownOpen(!dropdownOpen)}>
        User icon Chevron goes here?
      </button>
      {dropdownOpen && (
        <ul className="">
          <li>{currentUser.displayName}</li>
          <li>
            <button className="" onClick={handleClick}>
              Logout
            </button>
          </li>
        </ul>
      )}
    </div>
  );
};

UIUserTopNav.propTypes = {
  currentUser: PropTypes.object
};

export default withRouter(UIUserTopNav);
