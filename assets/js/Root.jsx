import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";

import Header from "./components/Header";
import CounterPage from "./pages/counter";
import HomePage from "./pages";

export default class Root extends React.Component {
  render() {
    return (
      <>
        <Header />
        <BrowserRouter>
          <Switch>
            <Route exact path="/" component={HomePage} />
            <Route path="/counter" component={CounterPage} />
          </Switch>
        </BrowserRouter>
      </>
    );
  }
}
