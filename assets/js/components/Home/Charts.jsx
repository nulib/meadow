import React from "react";
import MockAreaChart from "@js/components/Home/MockAreaChart";
import MockRadialBarChart from "@js/components/Home/MockRadialBarChart";
import MockBarChart from "@js/components/Home/MockBarChart";
import MockPieChart from "@js/components/Home/MockPieChart";

export default function Charts() {
  return (
    <div className="columns">
      <div className="column ">
        <MockAreaChart />
      </div>
      <div className="column ">
        <MockBarChart />
      </div>
      <div className="column ">
        <MockPieChart />
      </div>
    </div>
  );
}
