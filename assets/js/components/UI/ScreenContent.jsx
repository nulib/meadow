import React from "react";

const ScreenContent = ({ children }) => {
  return (
    <div data-testid="screen-content" className="flex">
      <div className="markdown px-6 xl:px-12 w-full  mx-auto lg:ml-0 lg:mr-auto xl:mx-0">
        {children}
      </div>
    </div>
  );
};

export default ScreenContent;
