import React from "react";
import UIMeadowVersion from "@js/components/UI/MeadowVersion";

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
                <span className="is-family-secondary">
                  Meadow <UIMeadowVersion showHoneyVersion />
                </span>
              </div>
            </div>
          </nav>
        </div>
      </div>
    </footer>
  );
};

export default UILayoutFooter;
