import React, { useState, useEffect, useRef } from "react";
import CollectionListRow from "../../components/Collection/ListRow";
import { useQuery } from "@apollo/react-hooks";
import { GET_COLLECTIONS } from "../../components/Collection/collection.query";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import { Link } from "react-router-dom";
import debounce from "lodash.debounce";
import Layout from "../Layout";

const ScreensCollectionList = () => {
  const { data, loading, error } = useQuery(GET_COLLECTIONS);
  const [filteredCollections, setFilteredCollections] = useState([]);
  const [searchValue, setSearchValue] = useState("");
  const inputEl = useRef(null);

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
    const searchValue = inputEl.current.value.toLowerCase();

    if (searchValue) {
      setFilteredCollections(
        data.collections.filter(collection =>
          collection.name.toLowerCase().includes(searchValue)
        )
      );
    } else {
      setFilteredCollections(data.collections);
    }
  };

  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Collections</h1>
            <h2 className="subtitle">
              Each <span className="is-italic">Work</span> must live in a
              Collection. <br />
              <strong>Themes</strong> are customized groupings of{" "}
              <span className="is-italic">Works</span>.
            </h2>
            <Link to="/collection/form" className="button is-primary">
              Create collection
            </Link>
          </div>
        </div>
      </section>
      <section className="section">
        <div className="container">
          <ul>
            {filteredCollections.length > 0 &&
              filteredCollections.map(collection => (
                <CollectionListRow
                  key={collection.id}
                  collection={collection}
                />
              ))}
          </ul>
          {data.collections.length === 0 && (
            <p>No collections exist. Why not add one?</p>
          )}
        </div>
      </section>
    </Layout>
  );
};

export default ScreensCollectionList;
