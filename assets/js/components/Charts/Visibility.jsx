import React from "react";
import {
  BarChart,
  Bar,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";

export default function ChartsVisibility({ data = [] }) {
  return (
    <div style={{ width: "100%", height: "300px" }}>
      <ResponsiveContainer>
        <BarChart
          data={data}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 5,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Bar dataKey="published" stackId="a" fill="#5091cd" />
          <Bar dataKey="unpublished" stackId="a" fill="#bbb8b8" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
