import React from "react";
import PropTypes from "prop-types";

function LevelItem({ heading, title }) {
  return (
    <div className="has-text-centered py-3">
      <div>
        <p className="heading is-size-6">{heading}</p>
        <p className="title is-size-2 is-campton-bold">{title}</p>
      </div>
    </div>
  );
}

function HomeStatsRow({ stats }) {
  return (
    <div
      data-testid="stats-row"
      className="box notification is-info is-light has-text-centered"
    >
      {stats.map((stat) => (
        <LevelItem
          key={stat.heading}
          heading={stat.heading}
          title={stat.title}
        />
      ))}
    </div>
  );
}

HomeStatsRow.propTypes = {
  heading: PropTypes.string,
  title: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

export default HomeStatsRow;
