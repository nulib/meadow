import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";

const ScreensHome = () => {
  return (
    <>
      <ScreenHeader
        title="Home Dashboard"
        description="View the applications main dashboard features here"
      />
      <ScreenContent>
        <p>Stuff goes here</p>
      </ScreenContent>
    </>
  );
};

export default ScreensHome;
