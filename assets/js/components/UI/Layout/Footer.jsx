import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const styles = {
  span: {
    paddingLeft: "1rem"
  }
};

const UILayoutFooter = () => {
  return (
    <footer className="footer has-background-white has-text-grey">
      <div className="container">
        <nav className="level">
          <div className="level-item">
            <a
              className="navbar-item"
              href="https://www.library.northwestern.edu/"
            >
              <figure className="image logo">
                <img
                  src="/images/northwestern-libraries-logo.png"
                  alt="Northwestern Libraries logo"
                />
              </figure>
            </a>
          </div>
          <div className="level-item">
            <div>
              <span className="icon">
                <FontAwesomeIcon icon="leaf" />
              </span>
              <strong>Meadow v1.0</strong> by{" "}
              <a href="https://github.com/nulib" target="_blank">
                @nulib
              </a>
            </div>
          </div>
          <div className="level-item">
            <p>
              An{" "}
              <a href="https://elixir-lang.org/" target="_blank">
                Elixir
              </a>
              /
              <a href="https://reactjs.org/" target="_blank">
                React
              </a>{" "}
              repository application
            </p>
          </div>
        </nav>
      </div>
    </footer>
  );
};

export default UILayoutFooter;
