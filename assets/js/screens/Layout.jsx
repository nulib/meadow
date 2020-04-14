import React from "react";
import PropTypes from "prop-types";
import UILayoutFooter from "../components/UI/Layout/Footer";
import UILayoutNavBar from "../components/UI/Layout/NavBar";

const Layout = ({ children }) => {
  return (
    <div id="root">
      <UILayoutNavBar />
      <div>
        <main>{children}</main>
        <UILayoutFooter />
      </div>
    </div>
  );
};

Layout.propTypes = {
  children: PropTypes.node.isRequired
};

export default Layout;
