import React, { useContext, useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useLocation } from "react-router-dom";
import { AuthContext } from "../../Auth/Auth";
import client from "../../../client";
import UISearchBar from "../SearchBar";
import UILayoutNavDropdown from "@js/components/UI/Layout/NavDropdown";
import UILayoutNavDropdownHeader from "./NavDropdownHeader";
import UILayoutNavDropdownBody from "@js/components/UI/Layout/NavDropdownBody";
import UILayoutNavDropdownItem from "@js/components/UI/Layout/NavDropdownItem";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const navBarStyle = css`
  z-index: 200 !important;
`;

const UILayoutNavBar = () => {
  const currentUser = useContext(AuthContext);
  const [showSearch, setShowSearch] = useState();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [activeHoverNav, setActiveHoverNav] = useState("adam");
  const location = useLocation();

  const isActive = (matcher) => {
    return location.pathname.includes(matcher);
  };

  const handleLogoutClick = (e) => {
    e.preventDefault();
    client.resetStore();
    window.location.href = "/auth/logout";
  };

  const handleMobileMenuClick = () => {
    setMobileNavOpen(!mobileNavOpen);
  };

  const redirectToLogin = () => {
    window.location.pathname = `/auth/nusso`;
  };

  return (
    <>
      <nav
        role="navigation"
        className="navbar is-fixed-top"
        aria-label="main navigation"
        id="main-navigation"
        css={navBarStyle}
      >
        <div className="navbar-brand">
          <Link className="navbar-item" to="/">
            <div className="level is-mobile">
              <div className="level-left">
                <div className="level-item">
                  <img
                    src="/images/N-purple-120.png"
                    alt="Northwestern Libraries logo"
                  />
                </div>

                <div className="level-item is-family-secondary is-size-4">
                  <div>
                    Meadow{" "}
                    <span className="has-text-grey is-size-6">v 1.x.x</span>
                  </div>
                </div>
              </div>
            </div>
          </Link>
          <button
            role="button"
            aria-label="menu"
            aria-expanded={mobileNavOpen}
            aria-controls="navbarMenu"
            className={`button navbar-burger burger ${
              mobileNavOpen ? "is-active" : ""
            }`}
            data-target="navbarMenu"
            onClick={handleMobileMenuClick}
          >
            <span></span>
            <span></span>
            <span></span>
          </button>
        </div>

        <div
          id="navbarMenu"
          className={`navbar-menu ${mobileNavOpen ? "is-active" : ""}`}
        >
          {!currentUser && (
            <div className="navbar-end">
              <div className="navbar-item">
                <button className="button" onClick={redirectToLogin}>
                  <strong>Log in</strong>
                </button>
              </div>
            </div>
          )}
          {currentUser && (
            <>
              <div className="navbar-start">
                <AuthDisplayAuthorized>
                  <Link
                    className={`navbar-item ${
                      isActive("project") ? "is-active" : ""
                    }`}
                    to="/project/list"
                  >
                    Projects
                  </Link>
                </AuthDisplayAuthorized>

                <Link
                  to="/collection/list"
                  className={`navbar-item ${
                    isActive("collection") ? "is-active" : ""
                  }`}
                >
                  Themes &amp; Collections
                </Link>
              </div>

              <div className="navbar-end">
                <AuthDisplayAuthorized>
                  <UILayoutNavDropdown
                    onMouseEnter={() => setActiveHoverNav("Dashboards")}
                    onMouseLeave={() => setActiveHoverNav("")}
                  >
                    <UILayoutNavDropdownHeader label="Dashboards">
                      Dashboards
                    </UILayoutNavDropdownHeader>
                    <UILayoutNavDropdownBody
                      isExpanded={activeHoverNav === "Dashboards"}
                    >
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/batch-edit">Batch Edit</Link>
                      </UILayoutNavDropdownItem>
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/csv-metadata-update">
                          CSV Metadata Update
                        </Link>
                      </UILayoutNavDropdownItem>
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/nul-local-authorities">
                          NUL Local Authorities
                        </Link>
                      </UILayoutNavDropdownItem>
                    </UILayoutNavDropdownBody>
                  </UILayoutNavDropdown>
                </AuthDisplayAuthorized>

                <UILayoutNavDropdown
                  onMouseEnter={() => setActiveHoverNav("User")}
                  onMouseLeave={() => setActiveHoverNav("")}
                >
                  <UILayoutNavDropdownHeader label="User">
                    <FontAwesomeIcon icon="user" />
                  </UILayoutNavDropdownHeader>
                  <UILayoutNavDropdownBody>
                    <UILayoutNavDropdownItem>
                      {currentUser.displayName}
                    </UILayoutNavDropdownItem>
                    <UILayoutNavDropdownItem>
                      <a
                        role="menuitem"
                        className="navbar-item"
                        onClick={handleLogoutClick}
                      >
                        Logout
                      </a>
                    </UILayoutNavDropdownItem>
                  </UILayoutNavDropdownBody>
                </UILayoutNavDropdown>

                <div className="navbar-item">
                  {/* Desktop search button */}
                  <Link to="/search" className="button is-hidden-touch">
                    <FontAwesomeIcon icon="search" />
                  </Link>

                  {/* Mobile search button */}
                  <Link
                    to="/search"
                    className="button is-text is-hidden-desktop"
                  >
                    <span className="icon">
                      <FontAwesomeIcon icon="search" />
                    </span>
                    <span>Search</span>
                  </Link>
                </div>
              </div>
            </>
          )}
        </div>
      </nav>
      {showSearch && <UISearchBar />}
    </>
  );
};

export default UILayoutNavBar;
