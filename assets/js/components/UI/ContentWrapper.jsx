import React from "react";
import Main from "./Main";

const ContentWrapper = ({ children }) => (
  <div className="min-h-screen w-full lg:static lg:max-h-full lg:overflow-visible">
    <div id="content" className="flex">
      <Main>{children}</Main>
    </div>
  </div>
);

export default ContentWrapper;
