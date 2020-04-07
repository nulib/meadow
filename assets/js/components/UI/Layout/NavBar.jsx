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

  const isActive = matcher => {
    return location.pathname.includes(matcher);
  };

  const handleLogoutClick = e => {
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
    console.log(mobileNavOpen);
  };

  const redirectToLogin = () => {
    window.location.pathname = `/auth/nusso`;
  };

  const NavbarStartLinks = () => {
    return (
      <>
        <Link to="/" className="navbar-item">
          <FontAwesomeIcon icon="home" />
        </Link>
        <Link
          to="/project/list"
          className={`navbar-item ${isActive("project") ? "is-active" : ""}`}
        >
          Projects
        </Link>

        <Link
          to="/collection/list"
          className={`navbar-item ${isActive("collection") ? "is-active" : ""}`}
        >
          Themes &amp; Collections
        </Link>
      </>
    );
  };
  const NavbarEndLinks = () => {
    return (
      <>
        <div className="navbar-item has-dropdown is-hoverable">
          <a className="navbar-link">
            <FontAwesomeIcon icon="bell" />
          </a>
          <div className="navbar-dropdown is-right">
            <a className="navbar-item">Some alert #1</a>
            <a className="navbar-item">Some alert #2</a>
          </div>
        </div>
        <div className="navbar-item has-dropdown is-hoverable">
          <a className="navbar-link">
            <FontAwesomeIcon icon="user" />
          </a>
          <div className="navbar-dropdown is-right">
            <span className="navbar-item">{currentUser.displayName}</span>
            <a className="navbar-item" onClick={handleLogoutClick}>
              Logout
            </a>
          </div>
        </div>
        <div className="navbar-item">
          <button className="button is-dark" onClick={handleSearchButtonClick}>
            <FontAwesomeIcon icon="search" size="2x" />
          </button>
        </div>
      </>
    );
  };

  return (
    <>
      <nav
        id="mobile-nav"
        className="navbar"
        aria-expanded={mobileNavOpen ? true : false}
        aria-hidden={mobileNavOpen ? false : false}
        style={mobileNavOpen ? { display: "block" } : { display: "none" }}
      >
        {!currentUser && (
          <div className="navbar-item">
            <button className="button" onClick={redirectToLogin}>
              <strong>Log in</strong>
            </button>
          </div>
        )}
        {currentUser && (
          <div>
            <NavbarStartLinks />

            <Link
              to="/"
              className={`navbar-item ${
                isActive("dashboard") ? "is-active" : ""
              }`}
            >
              Dashboards
            </Link>

            <NavbarEndLinks />
          </div>
        )}
      </nav>
      <nav className="navbar is-dark is-fixed-top">
        <div className="navbar-brand">
          <a
            className="navbar-item"
            href="https://www.library.northwestern.edu/"
          >
            <img
              src="/images/northwestern-white.png"
              alt="Northwestern Libraries logo"
            />
          </a>
          <div
            className={`navbar-burger burger ${
              mobileNavOpen ? "is-active" : ""
            }`}
            data-target="navMenuColordark-example"
            onClick={handleMobileMenuClick}
          >
            <span></span>
            <span></span>
            <span></span>
          </div>
        </div>

        <div id="navMenuColordark-example" className="navbar-menu">
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
                <NavbarStartLinks />
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
                <NavbarEndLinks />
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
