import React from "react";
import { BrowserRouter, Route, Switch, Redirect } from "react-router-dom";
import { ToastProvider } from "react-toast-notifications";
import { AuthProvider } from "../components/Auth/Auth";
import Header from "../components/UI/Header/Header";
import ScreensProjectList from "./Project/List";
import ScreensProjectForm from "./Project/Form";
import ScreensProject from "./Project/Project";
import Home from "./Home/Home";
import NotFoundPage from "./404";
import ScreensIngestSheet from "./IngestSheet/IngestSheet";
import ScreensIngestSheetForm from "./IngestSheet/Form";
import ScreensWork from "./Work/Work";
import ScreensWorkList from "./Work/List";
import ScreensCollectionList from "./Collection/List";
import ScreensCollection from "./Collection/Collection";
import Login from "./Login";
import PrivateRoute from "../components/Auth/PrivateRoute";

export default class Root extends React.Component {
  render() {
    return (
      <AuthProvider>
        <ToastProvider>
          <BrowserRouter>
            <Header />
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
                path="/project/:id/ingest-sheet/:sheetId"
                component={ScreensIngestSheet}
              />
              <PrivateRoute
                exact
                path="/project/:id"
                component={ScreensProject}
              />
              <PrivateRoute
                exact
                path="/work/list"
                component={ScreensWorkList}
              />
              <PrivateRoute exact path="/work/:id" component={ScreensWork} />
              <PrivateRoute
                exact
                path="/collection/list"
                component={ScreensCollectionList}
              />
              <PrivateRoute
                exact
                path="/collection/:id"
                component={ScreensCollection}
              />
              <PrivateRoute exact path="/" component={Home} />
              <PrivateRoute component={NotFoundPage} />
            </Switch>
          </BrowserRouter>
        </ToastProvider>
      </AuthProvider>
    );
  }
}
