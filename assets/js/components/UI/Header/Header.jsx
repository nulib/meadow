import React, { useContext } from "react";
import { AuthContext } from "../../Auth/Auth";
import PropTypes from "prop-types";
import UIHeaderLogo from "./Logo";
import UIHeaderGlobalSearch from "./GlobalSearch";
import UIHeaderNav from "./Nav";

const Header = () => {
  const me = useContext(AuthContext);

  return (
    <div id="header">
      <div className="flex bg-white border-b border-gray-200 fixed top-0 inset-x-0 z-100 h-16 items-center">
        <div className="w-full container relative mx-auto px-6">
          <div className="flex items-center -mx-6">
            <div className="sm:w-1/2 md:w-1/3 lg:w-1/4 xl:w-1/5 pl-6 pr-6 lg:pr-8">
              <UIHeaderLogo />
            </div>
            <div className="flex flex-grow lg:w-3/4 xl:w-4/5">
              <UIHeaderGlobalSearch currentUser={me} />
              <UIHeaderNav currentUser={me} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

Header.propTypes = {
  username: PropTypes.string
};

export default Header;
