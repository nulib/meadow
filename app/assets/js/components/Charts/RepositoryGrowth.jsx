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

export default function ChartsRepositoryGrowth({ worksCreatedByWeek = [] }) {
  return (
    <div className="box">
      <h3 className="subtitle is-3">Repository Growth</h3>
      <div style={{ width: "100%", height: "400px" }}>
        <ResponsiveContainer>
          <LineChart
            width={500}
            height={300}
            data={worksCreatedByWeek}
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
            <Legend formatter={(value) => "Works"} />
            <Line
              type="monotone"
              dataKey="works"
              stroke="#5091cd"
              activeDot={{ r: 8 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
