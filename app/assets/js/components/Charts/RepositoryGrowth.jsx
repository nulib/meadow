import React from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import moment from "moment";

function formatDate(tickItem) {
  return moment(tickItem).format("MMM Do YY");
}

function mergeChartData(works, fileSets) {
  let worksIndex = 0;
  let fileSetsIndex = 0;
  let result = [];

  while (worksIndex < works.length && fileSetsIndex < fileSets.length) {
    if (works[worksIndex].timestamp < fileSets[fileSetsIndex].timestamp) {
      worksIndex++;
    } else if (
      works[worksIndex].timestamp > fileSets[fileSetsIndex].timestamp
    ) {
      fileSetsIndex++;
    } else {
      result.push({
        ...works[worksIndex],
        ...fileSets[fileSetsIndex],
      });
      worksIndex++;
      fileSetsIndex++;
    }
  }

  return result;
}

export default function ChartsRepositoryGrowth({
  worksCreatedByWeek = [],
  fileSetsCreatedByWeek = [],
}) {
  const data = mergeChartData(worksCreatedByWeek, fileSetsCreatedByWeek);

  return (
    <div className="box">
      <h3 className="subtitle is-3">Repository Growth</h3>
      <div style={{ width: "100%", height: "400px" }}>
        <ResponsiveContainer>
          <LineChart
            width={500}
            height={300}
            data={data}
            margin={{
              top: 5,
              right: 30,
              left: 20,
              bottom: 5,
            }}
          >
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="timestamp" tickFormatter={formatDate} />
            <YAxis />
            <Tooltip labelFormatter={formatDate} />
            <Legend />
            <Line
              type="monotone"
              dataKey="works"
              name="Works"
              stroke="#5091cd"
              activeDot={{ r: 8 }}
            />
            <Line
              type="monotone"
              dataKey="fileSets"
              name="File Sets"
              stroke="#EF553F"
              activeDot={{ r: 8 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
