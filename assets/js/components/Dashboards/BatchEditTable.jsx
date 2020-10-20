import React from "react";
import faker from "faker";

function buildData() {
  let data = [];
  for (let i = 0; i < 10; i++) {
    data.push({
      started: faker.date.past(),
      id: faker.random.uuid(),
      user: faker.internet.email(),
      nickname: faker.lorem.words(),
      status: faker.lorem.word(),
      worksUpdated: faker.random.number(),
      details: faker.lorem.sentence(),
    });
  }
  return data;
}

export default function BatchEditTable() {
  return (
    <table className="table is-striped is-fullwidth">
      <thead>
        <tr>
          <th>Started</th>
          <th>ID</th>
          <th>User</th>
          <th>Nickname</th>
          <th>Status</th>
          <th>Works updated</th>
          <th>Details</th>
        </tr>
      </thead>
      <tbody>
        {buildData().map(
          ({ started, id, user, nickname, status, worksUpdated, details }) => (
            <tr key={id}>
              <td>{started.toString()}</td>
              <td>{id}</td>
              <td>{user}</td>
              <td>{nickname}</td>
              <td>
                <span className="tag">{status}</span>
              </td>
              <td>{worksUpdated}</td>
              <td>{details}</td>
            </tr>
          )
        )}
      </tbody>
    </table>
  );
}
