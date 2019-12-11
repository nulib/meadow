import React from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import CollectionListRow from "../../components/Collection/ListRow";
import { useQuery } from "@apollo/react-hooks";
import { GET_COLLECTIONS } from "../../components/Collection/collection.query";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";

const ScreensCollectionList = () => {
  const { data, loading, error } = useQuery(GET_COLLECTIONS);

  if (loading) {
    return <Loading />;
  }
  if (error) {
    return <Error error={error} />;
  }

  const createCrumbs = () => {
    return [
      {
        label: "Collections",
        link: "/collection/list"
      }
    ];
  };

  const handleFilterChange = e => {
    console.log("filter change");
  };

  return (
    <>
      <ScreenHeader
        title="Collections"
        description="All collections in the system."
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <section className="flex justify-between mb-8">
          <input
            className="text-input max-w-sm"
            placeholder="Filter collections"
            onChange={handleFilterChange}
          />

          <button className="btn">Create collection</button>
        </section>
        <ul>
          {data.collections.length > 0 &&
            data.collections.map(collection => (
              <CollectionListRow key={collection.id} collection={collection} />
            ))}
        </ul>
      </ScreenContent>
    </>
  );
};

export default ScreensCollectionList;
