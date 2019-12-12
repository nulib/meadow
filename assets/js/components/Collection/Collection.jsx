import React from "react";
import PropTypes, { shape } from "prop-types";
import EditIcon from "../../../css/fonts/zondicons/edit-pencil.svg";
import CollectionSearch from "./Search";
import UIButton from "../UI/Button";

const Collection = ({ id, name, description, keywords = [] }) => {
  return (
    <div data-testid="collection">
      <header className="flex flex-row justify-between mb-4">
        <h1>{name}</h1>
        <UIButton>
          <EditIcon className="icon" /> Edit
        </UIButton>
      </header>
      <section className="flex flex-col sm:flex-row mb-12">
        <div className="sm:w-1/2">
          <img
            src="/images/placeholder-content.png"
            alt="Placeholder for collection"
          />
        </div>
        <div className="pl-4 sm:w-1/2">
          <div className="h-32 border border-gray-300 overflow-y-scroll mb-4 p-2">
            {description}
          </div>
          <p>Admin@admin.com</p>
          <p>Finding aid</p>
          <dl>
            <dt>Keywords</dt>
            <dd>{keywords.join(", ")}</dd>
          </dl>
        </div>
      </section>
      <CollectionSearch />
    </div>
  );
};

Collection.propTypes = {
  collection: shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string,
    description: PropTypes.string,
    keywords: PropTypes.array
  })
};

export default Collection;
