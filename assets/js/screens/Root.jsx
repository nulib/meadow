import React from "react";
import { BrowserRouter, Route, Switch } from "react-router-dom";
import { AuthProvider } from "../components/Auth/Auth";
import ScreensProjectList from "./Project/List";
import ScreensProjectForm from "./Project/Form";
import ScreensProject from "./Project/Project";
import Home from "./Home/Home";
import NotFound from "./404";
import ScreensIngestSheet from "./IngestSheet/IngestSheet";
import ScreensIngestSheetForm from "./IngestSheet/Form";
import ScreensWork from "./Work/Work";
import ScreensSearch from "./Search/Search";
import ScreensCollectionList from "./Collection/List";
import ScreensCollection from "./Collection/Collection";
import ScreensCollectionForm from "./Collection/Form";
import ScreensBatchEdit from "./BatchEdit/BatchEdit";
import Login from "./Login";
import PrivateRoute from "../components/Auth/PrivateRoute";
import ScrollToTop from "../components/ScrollToTop";
import { ReactiveBase } from "@appbaseio/reactivesearch";
import {
  ELASTICSEARCH_PROXY_ENDPOINT,
  ELASTICSEARCH_INDEX_NAME,
} from "../services/elasticsearch";
import { REACTIVE_SEARCH_THEME } from "../services/reactive-search";
import { BatchProvider } from "../context/batch-edit-context";

export default class Root extends React.Component {
  render() {
    return (
      <ReactiveBase
        app={ELASTICSEARCH_INDEX_NAME}
        theme={REACTIVE_SEARCH_THEME}
        url={ELASTICSEARCH_PROXY_ENDPOINT}
      >
        <AuthProvider>
          <BatchProvider>
            <BrowserRouter>
              <ScrollToTop />
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

                <PrivateRoute exact path="/work/:id" component={ScreensWork} />
                <PrivateRoute
                  exact
                  path="/collection/list"
                  component={ScreensCollectionList}
                />
                <PrivateRoute
                  exact
                  path="/collection/form/:id?"
                  component={ScreensCollectionForm}
                />
                <PrivateRoute
                  exact
                  path="/collection/:id"
                  component={ScreensCollection}
                />
                <PrivateRoute exact path="/search" component={ScreensSearch} />
                <PrivateRoute
                  exact
                  path="/batch-edit"
                  component={ScreensBatchEdit}
                />
                <PrivateRoute exact path="/" component={Home} />
                <PrivateRoute component={NotFound} />
              </Switch>
            </BrowserRouter>
          </BatchProvider>
        </AuthProvider>
      </ReactiveBase>
    );
  }
}
