import React, { useState, useEffect } from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";
import UIFormInput from "../UI/Form/Input";
import UIFormField from "../UI/Form/Field";
import WorkCardItem from "../Work/CardItem";
import { prepWorkItemForDisplay } from "../../services/helpers";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";

const CollectionSearch = ({ collection }) => {
  const [filteredWorks, setFilteredWorks] = useState(collection.works);

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

        <UIFormField childClass="has-icons-left">
          <UIFormInput
            placeholder="Search collection works"
            onChange={handleFilterChange}
            name="collectionSearch"
            label="Filter collections by works"
          />
          <span className="icon is-small is-left">
            <FontAwesomeIcon icon="search" />
          </span>
        </UIFormField>

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
            <DisplayAuthorized action="edit">
              <div className="level-item">
                <button className="button">Batch Edit Records</button>
              </div>
            </DisplayAuthorized>
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
              <WorkCardItem {...prepWorkItemForDisplay(work)} id={work.id} />
            </li>
          ))}
        </ul>
      </section>
    </>
  );
};

export default CollectionSearch;
