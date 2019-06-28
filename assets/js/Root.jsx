import React from 'react';
import { BrowserRouter, Route, Switch } from 'react-router-dom';

import Header from './components/Header';
import CounterPage from './pages/counter';
import FetchDataPage from './pages/fetch-data';
import HomePage from './pages';
import IngestPage from './pages/ingest';
import CreateIngestProjectPage from './pages/create-ingest-project';

export default class Root extends React.Component {
  render() {
    return (
      <>
        <BrowserRouter>
          <Header />
          <Switch>
            <Route exact path="/" component={HomePage} />
            <Route path="/counter" component={CounterPage} />
            <Route path="/fetch-data" component={FetchDataPage} />
            <Route path="/ingest" component={IngestPage} />
            <Route
              path="/create-ingest-project"
              component={CreateIngestProjectPage}
            />
          </Switch>
        </BrowserRouter>
      </>
    );
  }
}
