import React from "react";

export type Stat = {
  heading: string;
  title: string | number;
};

function LevelItem({ heading, title }: Stat) {
  return (
    <div className="has-text-centered py-3">
      <div>
        <p className="heading is-size-6">{heading}</p>
        <p className="title is-size-2 is-campton-bold">{title}</p>
      </div>
    </div>
  );
}

function HomeStatsRow({ stats }: { stats: Stat[] }) {
  return (
    <>
      <div
        data-testid="stats-row"
        className="box notification is-primary is-light has-text-centered"
      >
        {stats.map((stat) => (
          <LevelItem
            key={stat.heading}
            heading={stat.heading}
            title={stat.title}
          />
        ))}
      </div>
    </>
  );
}

export default HomeStatsRow;
