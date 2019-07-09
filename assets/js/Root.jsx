import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

import Header from "./components/Header";
import FetchDataPage from "./pages/fetch-data";
import IngestPage from "./pages/ingest";
import CreateIngestProjectPage from "./pages/create-ingest-project";
import ProjectPage from "./pages/project";
import HomePage from "./pages/home";
import NotFoundPage from "./pages/404";

export default class Root extends React.Component {
  render() {
    return (
      <>
        <BrowserRouter>
          <Header />
          <ToastContainer position="top-right" hideProgressBar />
          <Switch>
            <Route path="/fetch-data" component={FetchDataPage} />
            <Route
              path="/create-ingest-project"
              component={CreateIngestProjectPage}
            />
            <Route path="/projects" component={IngestPage} />
            <Route path="/project/:id" component={ProjectPage} />
            <Route exact path="/" component={HomePage} />
            <Route component={NotFoundPage} />
          </Switch>
        </BrowserRouter>
      </>
    );
  }
}
