import React from "react";
import { Link } from "react-router-dom";
import NavLink from "./NavLink";
import SearchIcon from "../../../css/fonts/zondicons/search.svg";
import UserIcon from "../../../css/fonts/zondicons/user.svg";

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
    url: "/",
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

const Header = () => (
  <div id="header">
    <div className="flex bg-white border-b border-gray-200 fixed top-0 inset-x-0 z-100 h-16 items-center">
      <div className="w-full container relative mx-auto px-6">
        <div className="flex items-center -mx-6">
          <div className="lg:w-1/4 xl:w-1/5 pl-6 pr-6 lg:pr-8">
            <div className="flex items-center">
              <img
                src="/images/northwestern-libraries-logo.png"
                alt="Northwestern Libraries logo"
                className="opacity-50"
              />
            </div>
          </div>
          <div className="flex flex-grow lg:w-3/4 xl:w-4/5">
            <div className="w-full lg:px-6 xl:w-3/4 xl:px-12">
              <div className="relative">
                <input
                  type="text"
                  placeholder="Search for items"
                  className="transition focus:outline-0 border border-transparent focus:bg-white focus:border-gray-300 placeholder-gray-900 rounded-lg bg-gray-200 py-2 pr-4 pl-10 block w-full appearance-none leading-normal ds-input"
                />
                <div className="pointer-events-none absolute inset-y-0 left-0 pl-4 flex items-center">
                  <SearchIcon
                    width={50}
                    height={50}
                    className="fill-current pointer-events-none text-gray-600 w-4 h-4"
                  />
                </div>
              </div>
            </div>
            <div className="hidden lg:flex lg:items-center lg:justify-between xl:w-1/4 px-6 text-gray-500">
              <Link to="/">Meadow v1.0</Link>
              <UserIcon
                width={100}
                height={100}
                className="fill-current pointer-events-none text-gray-600 w-5 h-5"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
);

export default Header;
