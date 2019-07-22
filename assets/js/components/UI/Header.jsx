import React from "react";
import { Link } from "react-router-dom";
import NavLink from "./NavLink";
import SearchIcon from '../../../css/fonts/zondicons/search.svg';

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
              <Link to="/" className="text-xl">
                Meadow v1.0
              </Link>
            </div>
          </div>
          <div className="flex flex-grow lg:w-3/4 xl:w-4/5">
            <div className="w-full lg:px-6 xl:w-3/4 xl:px-12">
              <div className="relative">
                <input type="text" placeholder="Search for items" className="transition focus:outline-0 border border-transparent focus:bg-white focus:border-gray-300 placeholder-gray-900 rounded-lg bg-gray-200 py-2 pr-4 pl-10 block w-full appearance-none leading-normal ds-input" />
              <div className="pointer-events-none absolute inset-y-0 left-0 pl-4 flex items-center">
                  <SearchIcon width={50} height={50} className="fill-current pointer-events-none text-gray-600 w-4 h-4" />
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    </div>

    {/* <section className="container mx-auto uppercase">
      <nav className="flex items-center justify-between flex-wrap bg-gray-300 p-6">
        <div className="flex items-center flex-shrink-0 text-white mr-6">
          <Link to="/" className="font-semibold text-xl tracking-tight">
            Meadow
          </Link>
        </div>
        <div className="block lg:hidden">
          <button className="flex items-center px-3 py-2 border rounded border-black hover:text-white hover:border-white">
            <svg
              className="fill-current h-3 w-3"
              viewBox="0 0 20 20"
              xmlns="http://www.w3.org/2000/svg"
            >
              <title>Menu</title>
              <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z" />
            </svg>
          </button>
        </div>
        <div className="w-full block flex-grow lg:flex lg:items-center lg:w-auto">
          <div className="text-sm lg:flex-grow">
            {navLinks.map(item => (
              <NavLink key={item.title} url={item.url} title={item.title} />
            ))}
          </div>
          <div>
            <a href="#" className="btn">
              Login
            </a>
          </div>
        </div>
      </nav>
    </section> */}
  </div>
);

export default Header;
