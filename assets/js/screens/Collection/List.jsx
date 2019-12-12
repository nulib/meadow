import React, { useState, useEffect } from "react";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import CollectionListRow from "../../components/Collection/ListRow";
import { useQuery } from "@apollo/react-hooks";
import { GET_COLLECTIONS } from "../../components/Collection/collection.query";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import AddOutlineIcon from "../../../css/fonts/zondicons/add-outline.svg";
import { Link } from "react-router-dom";

const ScreensCollectionList = () => {
  const { data, loading, error } = useQuery(GET_COLLECTIONS);
  const [filteredCollections, setFilteredCollections] = useState([]);

  useEffect(() => {
    if (data && data.collections) {
      setFilteredCollections(data.collections);
    }
  }, [data]);

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
    const searchValue = e.target.value;

    if (searchValue) {
      setFilteredCollections(
        filteredCollections.filter(
          collection => collection.name.indexOf(searchValue) > -1
        )
      );
    } else {
      setFilteredCollections(data.collections);
    }
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
          <Link to="/" className="btn">
            <AddOutlineIcon className="icon" />
            Create collection
          </Link>
        </section>
        <ul>
          {filteredCollections.length > 0 &&
            filteredCollections.map(collection => (
              <CollectionListRow key={collection.id} collection={collection} />
            ))}
        </ul>
      </ScreenContent>
    </>
  );
};

export default ScreensCollectionList;
