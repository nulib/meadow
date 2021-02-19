import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const UILayoutFooter = () => {
  return (
    <footer className="footer has-background-white has-text-grey">
      <div className="container has-text-centered">
        <div className="column is-half is-inline-block">
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
                    style={{ opacity: 0.5 }}
                  />
                </figure>
              </a>
            </div>
            <div className="level-item">
              <div>
                <span className="is-family-secondary">Meadow v1.x.x</span> by{" "}
                <a href="https://github.com/nulib" target="_blank">
                  @nulib
                </a>
              </div>
            </div>
          </nav>
        </div>
      </div>
    </footer>
  );
};

export default UILayoutFooter;
