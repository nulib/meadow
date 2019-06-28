import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";

import Header from "./components/Header";
import FetchDataPage from "./pages/fetch-data";
import IngestPage from "./pages/ingest";
import CreateIngestProjectPage from "./pages/create-ingest-project";

export default class Root extends React.Component {
  render() {
    return (
      <>
        <BrowserRouter>
          <Header />
          <Switch>
            <Route path="/fetch-data" component={FetchDataPage} />
            <Route
              path="/create-ingest-project"
              component={CreateIngestProjectPage}
            />
            <Route path="/" component={IngestPage} />
          </Switch>
        </BrowserRouter>
      </>
    );
  }
}
