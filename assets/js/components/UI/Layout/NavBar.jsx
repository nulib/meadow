import React, { useContext, useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useLocation, useHistory } from "react-router-dom";
import { AuthContext } from "../../Auth/Auth";
import client from "../../../client";
import UISearchBar from "../SearchBar";

const UILayoutNavBar = () => {
  const currentUser = useContext(AuthContext);
  const [showSearch, setShowSearch] = useState();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const location = useLocation();
  const history = useHistory();

  useEffect(() => {
    if (
      (location.state && location.state.showSearch) ||
      location.pathname === "/work/list"
    ) {
      setShowSearch(true);
    }
  }, [location]);

  const isActive = (matcher) => {
    return location.pathname.includes(matcher);
  };

  const handleLogoutClick = (e) => {
    e.preventDefault();
    client.resetStore();
    window.location.href = "/auth/logout";
  };

  const handleSearchButtonClick = () => {
    setShowSearch(!showSearch);
    if (location.pathname !== "/work/list") {
      history.push("/work/list", { showSearch: true });
    }
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
                {/* <Link to="/" className="navbar-item">
                  <FontAwesomeIcon icon="home" />
                </Link> */}
                <Link
                  to="/project/list"
                  className={`navbar-item ${
                    isActive("project") ? "is-active" : ""
                  }`}
                >
                  Projects
                </Link>

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
                <Link
                  to="/"
                  className={`navbar-item ${
                    isActive("dashboard") ? "is-active" : ""
                  }`}
                >
                  Dashboards
                </Link>

                <div className="navbar-item has-dropdown is-hoverable">
                  <input
                    type="checkbox"
                    id="dropdown1"
                    aria-haspopup="true"
                    aria-labelledby="dropdown1-label"
                  />
                  <label
                    id="dropdown1-label"
                    htmlFor="dropdown1"
                    className="navbar-link"
                  >
                    <FontAwesomeIcon icon="bell" />
                  </label>

                  <div
                    className="navbar-dropdown is-right"
                    aria-expanded="true"
                  >
                    <a role="menuitem" className="navbar-item">
                      Some alert #1
                    </a>
                    <a role="menuitem" className="navbar-item">
                      Some alert #2
                    </a>
                  </div>
                </div>
                <div className="navbar-item has-dropdown is-hoverable">
                  <input
                    type="checkbox"
                    id="dropdown2"
                    aria-haspopup="true"
                    aria-labelledby="dropdown2-label"
                  />
                  <label
                    id="dropdown2-label"
                    htmlFor="dropdown2"
                    className="navbar-link"
                  >
                    <FontAwesomeIcon icon="user" />
                  </label>
                  <div
                    className="navbar-dropdown is-right"
                    aria-expanded="true"
                  >
                    <span className="navbar-item">
                      {currentUser.displayName}
                    </span>
                    <a
                      role="menuitem"
                      className="navbar-item"
                      onClick={handleLogoutClick}
                    >
                      Logout
                    </a>
                  </div>
                </div>

                <div className="navbar-item">
                  <button
                    className="button is-hidden-touch"
                    onClick={handleSearchButtonClick}
                  >
                    <FontAwesomeIcon icon="search" />
                  </button>

                  <button
                    role="menuitem"
                    className="button is-text is-hidden-desktop"
                    onClick={handleSearchButtonClick}
                  >
                    <span className="icon">
                      <FontAwesomeIcon icon="search" />
                    </span>
                    <span>Search</span>
                  </button>
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
