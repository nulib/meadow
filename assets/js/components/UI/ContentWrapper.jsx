import React from "react";
import Main from "./Main";

const ContentWrapper = ({ children }) => (
  <div className="min-h-screen w-full lg:static lg:max-h-full lg:overflow-visible lg:w-3/4 xl:w-4/5">
    <div id="content" className="flex">
      <Main>{children}</Main>
    </div>
  </div>
);

export default ContentWrapper;
