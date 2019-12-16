import React from "react";
import { useLocation } from "react-router-dom";
import { Link } from "react-router-dom";
import BoxIcon from "../../../css/fonts/zondicons/box.svg";
import UserGroupIcon from "../../../css/fonts/zondicons/user-group.svg";
import BookReferenceIcon from "../../../css/fonts/zondicons/book-reference.svg";
import DocumentIcon from "../../../css/fonts/zondicons/document.svg";
import DashboardIcon from "../../../css/fonts/zondicons/dashboard.svg";
import WrenchIcon from "../../../css/fonts/zondicons/wrench.svg";

const Sidebar = () => {
  const location = useLocation();

  const isActive = matcher => {
    return location.pathname.includes(matcher);
  };

  return (
    <div
      id="sidebar"
      className="hidden fixed inset-0 pt-16 h-full z-10 w-full border-b -mb-16 lg:-mb-0 lg:static lg:h-auto lg:overflow-y-visible lg:border-b-0 lg:pt-0 lg:w-1/4 lg:block lg:border-0 xl:w-1/5"
    >
      <div
        id="navWrapper"
        className="h-full overflow-y-auto scrolling-touch lg:h-auto lg:block lg:relative lg:sticky lg:top-0 lg:mt-16 bg-white lg:bg-transparent"
      >
        <nav
          id="nav"
          className="px-6 pt-6 overflow-y-auto text-base lg:text-sm lg:py-16 lg:pl-6 lg:pr-8 sticky?lg:h-(screen-16)"
        >
          <div className="mb-10">
            <ul>
              <li className={`nav-item ${isActive("project") ? "active" : ""}`}>
                <Link to="/project/list" className="nav-link">
                  <BoxIcon className="icon" />
                  Projects
                </Link>
              </li>
              <li className={`nav-item ${isActive("user") ? "active" : ""}`}>
                <Link to="/" className="nav-link">
                  <UserGroupIcon className="icon" />
                  User Management
                </Link>
              </li>
              <li className={`nav-item ${isActive("work") ? "active" : ""}`}>
                <Link to="/work/list" className="nav-link">
                  <DocumentIcon className="icon" />
                  Works
                </Link>
              </li>
              <li
                className={`nav-item ${isActive("collection") ? "active" : ""}`}
              >
                <Link to="/collection/list" className="nav-link">
                  <BookReferenceIcon className="icon" />
                  Collections
                </Link>
              </li>
              <li
                className={`nav-item ${isActive("dashboard") ? "active" : ""}`}
              >
                <Link to="/" className="nav-link">
                  <DashboardIcon className="icon" />
                  Dashboards
                </Link>
              </li>
              <li
                className={`nav-item ${isActive("admin-set") ? "active" : ""}`}
              >
                <Link to="/" className="nav-link">
                  <WrenchIcon className="icon" />
                  Admin Sets
                </Link>
              </li>
            </ul>
          </div>
        </nav>
      </div>
    </div>
  );
};

export default Sidebar;
