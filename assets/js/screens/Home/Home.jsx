import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";

const ScreensHome = () => {
  return (
    <>
      <ScreenHeader
        title="Home Dashboard"
        description="View the applications main dashboard features here"
        breadCrumbs={[{ label: "Home", link: "/" }]}
      />
      <ScreenContent>
        <img className="w-screen" src="/images/placeholder-content.png" />
      </ScreenContent>
    </>
  );
};

export default ScreensHome;
