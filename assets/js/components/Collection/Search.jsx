import React, { useState, useEffect } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";

const CollectionSearch = ({ collection }) => {
  const [filteredWorks, setFilteredWorks] = useState(collection.works);
  // useEffect(() => {
  //   setFilteredWorks(collection ? collection.works : []);
  // }, []);

  const handleFilterChange = (e) => {
    const filterValue = e.target.value.toUpperCase();
    if (!filterValue) {
      return setFilteredWorks(collection ? collection.works : []);
    }
    const filteredList = collection.works.filter((work) => {
      return work.descriptiveMetadata.title
        ? work.descriptiveMetadata.title.toUpperCase().indexOf(filterValue) > -1
        : false;
    });
    setFilteredWorks(filteredList);
  };

  return (
    <>
      <section data-testid="collection-search" className="box">
        <h2 className="title is-size-4">Collection Works</h2>
        <div className="field">
          <div className="control has-icons-left">
            <input
              className="input"
              type="text"
              placeholder="Search collection works"
              onChange={handleFilterChange}
            />
            <span className="icon is-small is-left">
              <FontAwesomeIcon icon="search" />
            </span>
          </div>
        </div>
        <p className="field">
          <a>Show Filters</a>
        </p>
        <nav className="level">
          <div className="level-left">
            <div className="level-item">
              <p
                className="is-size-5 has-text-weight-bold"
                data-testid="number-of-works"
              >
                {filteredWorks.length} results...
              </p>
            </div>
          </div>
          <div className="level-right">
            <div className="level-item">
              <button className="button">Batch Edit Records</button>
            </div>
            <div className="level-item">
              <button className="button">Export CSV</button>
            </div>
          </div>
        </nav>
        <ul className="columns is-multiline">
          {filteredWorks.map((work) => (
            <li
              className="column is-one-quarter-desktop is-half-tablet"
              key={work.id}
            >
              <Link to={`/work/${work.id}`}>
                <figure className="image is-square">
                  <img
                    data-testid={`work-image-${work.id}`}
                    src={`${
                      work.representativeImage
                        ? work.representativeImage +
                          "/square/500,500/0/default.jpg"
                        : "/images/480x480.png"
                    }`}
                  />
                </figure>
                <p
                  className="text-center"
                  data-testid={`work-title-${work.id}`}
                >{`${
                  work.descriptiveMetadata.title
                    ? work.descriptiveMetadata.title
                    : "Untitled"
                }`}</p>
              </Link>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
};

export default CollectionSearch;
