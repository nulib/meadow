import React from "react";
import PropTypes from "prop-types";
import UILayoutFooter from "../components/UI/Layout/Footer";
import UILayoutNavBar from "../components/UI/Layout/NavBar";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import UILayoutMain from "@js/components/UI/Layout/Main";

const Layout = ({ children }) => {
  return (
    <div id="root">
      <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
        <UILayoutNavBar />
      </ErrorBoundary>
      <div>
        <UILayoutMain>{children}</UILayoutMain>
        <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
          <UILayoutFooter />
        </ErrorBoundary>
      </div>
    </div>
  );
};

Layout.propTypes = {
  children: PropTypes.node.isRequired,
};

export default Layout;
