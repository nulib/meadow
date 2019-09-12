import React from "react";
import Sidebar from "../components/UI/Sidebar";
import ContentWrapper from "../components/UI/ContentWrapper";

const Layout = ({ children }) => {
  return (
    <div className="w-full container mx-auto px-6">
      <div className="lg:flex -mx-6">
        <Sidebar />
        <ContentWrapper>{children}</ContentWrapper>
      </div>
    </div>
  );
};

export default Layout;
