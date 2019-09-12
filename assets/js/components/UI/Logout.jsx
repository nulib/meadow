import React, { Component } from "react";
import { withRouter } from "react-router-dom";
import client from "../../client";

const handleClick = () => {
  client.resetStore();
  location.pathname = `/auth/logout`;
};

const Logout = props => {
  return <button onClick={handleClick}>Logout</button>;
};

export default withRouter(Logout);
