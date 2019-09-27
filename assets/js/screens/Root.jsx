import React from "react";
import { BrowserRouter, Route, Switch, Redirect } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

import { AuthProvider } from "../components/Auth/Auth";
import Header from "../components/UI/Header/Header";
import ScreensProjectList from "./Project/List";
import ScreensProjectForm from "./Project/Form";
import ScreensProject from "./Project/Project";
import Home from "./Home/Home";
import NotFoundPage from "./404";
import ScreensIngestSheet from "./IngestSheet/IngestSheet";
import ScreensIngestSheetForm from "./IngestSheet/Form";
import Login from "./Login";
import PrivateRoute from "../components/Auth/PrivateRoute";

export default class Root extends React.Component {
  render() {
    return (
      <AuthProvider>
        <BrowserRouter>
          <Header />
          <ToastContainer
            position="top-center"
            hideProgressBar
            autoClose={7000}
          />

          <Switch>
            <Route exact path="/login" component={Login} />
            <PrivateRoute
              exact
              path="/project/list"
              component={ScreensProjectList}
            />
            <PrivateRoute
              exact
              path="/project/create"
              component={ScreensProjectForm}
            />
            <PrivateRoute
              exact
              path="/project/:id/ingest-sheet/upload"
              component={ScreensIngestSheetForm}
            />
            <PrivateRoute
              exact
              path="/project/:id/ingest-sheet/:ingestSheetId"
              component={ScreensIngestSheet}
            />
            <PrivateRoute
              exact
              path="/project/:id"
              component={ScreensProject}
            />
            <PrivateRoute exact path="/" component={Home} />
            <PrivateRoute component={NotFoundPage} />
          </Switch>
        </BrowserRouter>
      </AuthProvider>
    );
  }
}
