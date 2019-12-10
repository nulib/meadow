import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Collection from "../../components/Collection/Collection";

const ScreensCollection = () => {
  const createCrumbs = () => {
    return [
      {
        label: "Collections",
        link: "/collection/list"
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Collection"
        description="Collection details."
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <Collection collection={null} />
      </ScreenContent>
    </>
  );
};

export default ScreensCollection;
