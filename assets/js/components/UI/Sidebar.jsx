import React from "react";
import { Link } from "react-router-dom";

const navLinks = [
  {
    url: "/project/list",
    title: "Projects"
  },
  {
    url: "/",
    title: "User Management"
  },
  {
    url: "/work/list",
    title: "Works"
  },
  {
    url: "/",
    title: "Collections"
  },
  {
    url: "/",
    title: "Dashboards"
  },
  {
    url: "/",
    title: "Admin Sets"
  }
];

const Sidebar = () => {
  return (
    <div
      id="sidebar"
      className="hidden fixed inset-0 pt-16 h-full bg-white z-90 w-full border-b -mb-16 lg:-mb-0 lg:static lg:h-auto lg:overflow-y-visible lg:border-b-0 lg:pt-0 lg:w-1/4 lg:block lg:border-0 xl:w-1/5"
    >
      <div
        id="navWrapper"
        className="h-full overflow-y-auto scrolling-touch lg:h-auto lg:block lg:relative lg:sticky lg:top-0 lg:mt-16 bg-white lg:bg-transparent"
      >
        <nav
          id="nav"
          className="px-6 pt-6 overflow-y-auto text-base lg:text-sm lg:py-12 lg:pl-6 lg:pr-8 sticky?lg:h-(screen-16)"
        >
          <div className="mb-10">
            <ul>
              {navLinks.map(item => (
                <li key={item.title} className="mb-3 lg:mb-1">
                  <Link
                    to={item.url}
                    className="px-2 -mx-2 py-1 transition-fast relative block hover:translate-r-2px hover:text-gray-900 text-gray-600 font-medium"
                  >
                    {item.title}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </nav>
      </div>
    </div>
  );
};

export default Sidebar;
