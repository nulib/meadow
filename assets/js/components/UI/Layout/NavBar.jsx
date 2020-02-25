import React, { useContext } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useLocation } from "react-router-dom";
import { AuthContext } from "../../Auth/Auth";
import client from "../../../client";

const UILayoutNavBar = () => {
  const currentUser = useContext(AuthContext);
  const location = useLocation();

  const isActive = matcher => {
    return location.pathname.includes(matcher);
  };

  const handleLogoutClick = e => {
    e.preventDefault();
    client.resetStore();
    window.location.href = "/auth/logout";
  };

  const redirectToLogin = () => {
    window.location.pathname = `/auth/openam`;
  };

  return (
    <nav className="navbar is-dark is-fixed-top">
      <div className="navbar-brand">
        <a className="navbar-item" href="https://www.library.northwestern.edu/">
          <img
            src="/images/northwestern-white.png"
            alt="Northwestern Libraries logo"
          />
        </a>

        <div
          className="navbar-burger burger"
          data-target="navMenuColordark-example"
        >
          <span></span>
          <span></span>
          <span></span>
        </div>
      </div>

      <div id="navMenuColordark-example" className="navbar-menu">
        <div className="navbar-start"></div>

        <div className="navbar-end">
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
            to="/"
            className={`navbar-item ${isActive("user") ? "is-active" : ""}`}
          >
            User Management
          </Link>
          <Link
            to="/work/list"
            className={`navbar-item ${isActive("work") ? "is-active" : ""}`}
          >
            Works
          </Link>
          <Link
            to="/collection/list"
            className={`navbar-item ${
              isActive("collection") ? "is-active" : ""
            }`}
          >
            Themes &amp; Collections
          </Link>
          <Link
            to="/"
            className={`navbar-item ${
              isActive("dashboard") ? "is-active" : ""
            }`}
          >
            Dashboards
          </Link>
          {!currentUser && (
            <div className="navbar-item">
              <button className="button" onClick={redirectToLogin}>
                <strong>Log in</strong>
              </button>
            </div>
          )}
          <div className="navbar-item has-dropdown is-hoverable">
            <a className="navbar-link">
              <FontAwesomeIcon icon="bell" />
            </a>
            <div className="navbar-dropdown is-right">
              <a className="navbar-item">Some alert #1</a>
              <a className="navbar-item">Some alert #2</a>
            </div>
          </div>
          {currentUser && (
            <div className="navbar-item has-dropdown is-hoverable">
              <a className="navbar-link">
                <FontAwesomeIcon icon="user" />
              </a>
              <div className="navbar-dropdown is-right">
                <span className="navbar-item">{currentUser.email}</span>
                <a className="navbar-item" onClick={handleLogoutClick}>
                  Logout
                </a>
              </div>
            </div>
          )}
        </div>
      </div>
    </nav>
  );
};

export default UILayoutNavBar;
