import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import CurrentUser from "../../components/Auth/CurrentUser";

const ScreensHome = () => {
  return (
    <>
      <ScreenHeader
        title="Home Dashboard"
        description="View the applications main dashboard features here"
        breadCrumbs={[{ label: "Home", link: "/" }]}
      />
      <ScreenContent>
        <>
          <CurrentUser>
            {currentUser => <div>Hello {currentUser.displayName}!</div>}
          </CurrentUser>
        </>
      </ScreenContent>
    </>
  );
};

export default ScreensHome;
