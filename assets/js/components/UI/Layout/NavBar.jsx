import React, { useContext, useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useLocation } from "react-router-dom";
import { AuthContext } from "../../Auth/Auth";
import client from "../../../client";
import UISearchBar from "../SearchBar";
import UILayoutNavDropdown from "@js/components/UI/Layout/NavDropdown";
import UILayoutNavDropdownHeader from "@js/components/UI/Layout/NavDropdownHeader";
import UILayoutNavDropdownBody from "@js/components/UI/Layout/NavDropdownBody";
import UILayoutNavDropdownItem from "@js/components/UI/Layout/NavDropdownItem";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import RoleNavDropdown from "@js/components/Role/NavDropdown";
import Honeybadger from "@honeybadger-io/js";
import { GrDocumentCsv, GrMultiple } from "react-icons/gr";
import IconChart from "@js/components/Icon/Chart";
import IconText from "@js/components/UI/IconText";
import IconCheck from "@js/components/Icon/Check";
import NLogo from "@js/components/northwesternN.svg";
import UIMeadowVersion from "@js/components/UI/MeadowVersion";
import UIDevBgToggle from "@js/components/UI/DevBgToggle";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const navBarStyle = css`
  z-index: 200 !important;
`;

const UILayoutNavBar = () => {
  const currentUser = useContext(AuthContext);
  const [showSearch, setShowSearch] = useState();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [activeHoverNav, setActiveHoverNav] = useState();
  const location = useLocation();

  const isActive = (matcher) => {
    return location.pathname.includes(matcher);
  };

  const handleLogoutClick = (e) => {
    e.preventDefault();
    client.resetStore();
    Honeybadger.resetContext();
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
          <div className="navbar-item">
            <div className="level is-mobile">
              <div className="level-left">
                <div className="level-item">
                  <Link to="/">
                    <img
                      src="/images/N-purple-120.png"
                      alt="Northwestern Libraries logo"
                    />
                  </Link>
                </div>

                <div className="level-item is-family-secondary is-size-4">
                  <div>
                    <Link to="/">Meadow</Link>{" "}
                    <span className="has-text-grey is-size-6">
                      <UIMeadowVersion />
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
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
                <AuthDisplayAuthorized level="EDITOR">
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
                  Collections
                </Link>
              </div>

              <div className="navbar-end">
                <AuthDisplayAuthorized level="EDITOR">
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
                        <Link to="/dashboards/batch-edit">
                          <IconText icon={<GrMultiple />}>
                            Batch Edit Dashboard
                          </IconText>
                        </Link>
                      </UILayoutNavDropdownItem>
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/csv-metadata-update">
                          <IconText icon={<GrDocumentCsv />}>
                            CSV Metadata Update
                          </IconText>
                        </Link>
                      </UILayoutNavDropdownItem>
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/analytics">
                          <IconText icon={<IconChart />}>
                            Digital Collections Analytics
                          </IconText>
                        </Link>
                      </UILayoutNavDropdownItem>
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/nul-local-authorities">
                          <IconText icon={<NLogo width="14px" height="14px" />}>
                            Local Authorities
                          </IconText>
                        </Link>
                      </UILayoutNavDropdownItem>
                      <UILayoutNavDropdownItem>
                        <Link to="/dashboards/preservation-checks">
                          <IconText icon={<IconCheck />}>
                            Preservation Checks
                          </IconText>
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
                      {currentUser.displayName} ({currentUser.role})
                    </UILayoutNavDropdownItem>
                    <AuthDisplayAuthorized level="ADMINISTRATOR">
                      <RoleNavDropdown />
                    </AuthDisplayAuthorized>
                    <UILayoutNavDropdownItem>
                      <a role="menuitem" onClick={handleLogoutClick}>
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

                <UIDevBgToggle />
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
