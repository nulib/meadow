import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import CollectionList from "../../components/Collection/List";

const ScreensCollectionList = () => {
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
        title="Collections"
        description="All collections in the system."
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <CollectionList collections={[]} />
      </ScreenContent>
    </>
  );
};

export default ScreensCollectionList;
