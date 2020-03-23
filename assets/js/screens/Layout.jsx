import React from "react";
import PropTypes from "prop-types";
import UILayoutFooter from "../components/UI/Layout/Footer";
import UILayoutNavBar from "../components/UI/Layout/NavBar";

const Layout = ({ children }) => {
  return (
    <>
      <UILayoutNavBar />
      <div>
        <main>{children}</main>
        <UILayoutFooter />
      </div>
    </>
  );
};

Layout.propTypes = {
  children: PropTypes.node.isRequired,
};

export default Layout;
