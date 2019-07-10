import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

import Header from "../components/UI/Header";
import FetchDataPage from "./fetch-data";
import ProjectList from "./Project/List";
import ProjectForm from "./Project/Form";
import Project from "./Project/Project";
import Home from "./Home/Home";
import NotFoundPage from "./404";

export default class Root extends React.Component {
  render() {
    return (
      <>
        <BrowserRouter>
          <Header />
          <ToastContainer position="top-right" hideProgressBar />
          <Switch>
            <Route path="/fetch-data" component={FetchDataPage} />
            <Route path="/project/list" component={ProjectList} />
            <Route path="/project/create" component={ProjectForm} />
            <Route path="/project/:id" component={Project} />
            <Route path="/" component={Home} />
            <Route component={NotFoundPage} />
          </Switch>
        </BrowserRouter>
      </>
    );
  }
}
