import React from "react";

const CollectionSearch = () => {
  let items = [];

  for (let i = 0; i < 20; i++) {
    items.push(
      <li className="sm:w-1/4 p-2" key={i}>
        <img src="/images/placeholder-content.png" />
        <p className="text-center">{`Image title ${i} `}</p>
      </li>
    );
  }

  return (
    <div data-testid="collection-search" className="mt-12">
      <input
        className="text-input mb-2 max-w-lg block"
        placeholder="Search collections"
      ></input>
      <button className="btn-link mb-8 text-sm">Show Filters</button>
      <div className="flex mb-2 max-w-xl">
        <div className="font-bold mr-3">3000 results</div>
        <div className="mr-3">(Batch Edit Records)</div>
        <div>(Export CSV)</div>
      </div>
      <section>
        <ul className="flex flex-wrap">{items}</ul>
      </section>
    </div>
  );
};

export default CollectionSearch;
