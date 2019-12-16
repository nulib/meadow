import React, { useContext } from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import { AuthContext } from "../../components/Auth/Auth";

const ScreensHome = () => {
  const me = useContext(AuthContext);

  return (
    <>
      <ScreenHeader
        title="Home Dashboard"
        description="View the applications main dashboard features here"
      />
      <ScreenContent>
        <p>Something goes here</p>
      </ScreenContent>
    </>
  );
};

export default ScreensHome;
