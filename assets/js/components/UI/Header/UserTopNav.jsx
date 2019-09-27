import React, { useState } from "react";
import PropTypes from "prop-types";
import UserIcon from "../../../../css/fonts/zondicons/user.svg";
import CheveronDownIcon from "../../../../css/fonts/zondicons/cheveron-down.svg";
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
        <UserIcon width={100} height={100} className="icon" />
        <CheveronDownIcon width={100} height={100} className="icon" />
      </button>
      {dropdownOpen && (
        <ul className="absolute w-32 right-0 text-right my-4 p-2 bg-gray-200">
          <li>{currentUser.displayName}</li>
          <li>
            <button className="btn btn-link" onClick={handleClick}>
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
