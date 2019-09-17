import React from "react";
import SearchIcon from "../../../../css/fonts/zondicons/search.svg";

const UIHeaderGlobalSearch = ({ currentUser }) => (
  <div className="w-full lg:px-6 md:w-2/3 xl:px-12">
    <div className="relative">
      {currentUser && (
        <>
          <input
            type="text"
            placeholder="Search for items"
            className="transition focus:outline-0 text-gray-700 border border-transparent focus:bg-white focus:border-gray-300 placeholder-gray-500 rounded-lg bg-gray-200 py-2 pr-4 pl-10 block w-full appearance-none leading-tight ds-input"
          />
          <div className="pointer-events-none absolute inset-y-0 left-0 pl-4 flex items-center">
            <SearchIcon width={50} height={50} className="icon" />
          </div>
        </>
      )}
    </div>
  </div>
);

export default UIHeaderGlobalSearch;
