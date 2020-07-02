import React, { useState } from "react";
import Layout from "../Layout";
import { ReactiveList, SelectedFilters } from "@appbaseio/reactivesearch";
import { IIIFProvider } from "../../components/IIIF/IIIFProvider";
import WorkCardItem from "../../components/Work/CardItem";
import WorkListItem from "../../components/Work/ListItem";
import { Link } from "react-router-dom";
import UIResultsDisplaySwitcher from "../../components/UI/ResultsDisplaySwitcher";
import SearchBar from "../../components/UI/SearchBar";

const ScreensSearch = () => {
  const [isListView, setIsListView] = useState(false);

  const getWorkItem = (res) => {
    return {
      id: res._id,
      title: res.title,
      updatedAt: res.modified_date,
      representativeImage: res.representative_file_set,
      manifestUrl: res.iiif_manifest,
      published: res.published,
      visibility: res.visibility_term,
      fileSets: res.file_sets.length,
      accessionNumber: res.accession_number,
      workType: res.work_type,
    };
  };

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <div className="box">
            <div className="columns">
              <div className="column">
                <h1 className="title">Search</h1>
              </div>
              <div className="column is-hidden-touch">
                <UIResultsDisplaySwitcher
                  isListView={isListView}
                  onGridClick={() => setIsListView(false)}
                  onListClick={() => setIsListView(true)}
                />
              </div>
            </div>
            <SearchBar />
            <div className="mt-2">
              <SelectedFilters />
            </div>

            <hr />
            <p className="py-3">
              <Link to="/batch-edit">Go to batch edit</Link>
            </p>
          </div>
        </div>

        <div className="container">
          <IIIFProvider>
            <ReactiveList
              componentId="SearchResult"
              dataField="accession_number"
              defaultQuery={() => ({
                query: {
                  bool: {
                    must: [
                      {
                        match: {
                          "model.name": "Image",
                        },
                      },
                    ],
                  },
                },
              })}
              innerClass={{
                list: `${isListView ? "" : "columns is-multiline"}`,
                resultStats: "column is-size-6 has-text-grey",
              }}
              react={{
                and: ["SearchSensor"],
              }}
              renderItem={(res) => {
                if (isListView) {
                  return (
                    <div key={res._id} className="box">
                      <WorkListItem key={res._id} {...getWorkItem(res)} />
                    </div>
                  );
                }
                return (
                  <div
                    key={res._id}
                    className="column is-half-tablet is-one-third-desktop is-one-quarter-widescreen"
                  >
                    <WorkCardItem key={res._id} {...getWorkItem(res)} />
                  </div>
                );
              }}
              showResultStats={true}
            />
          </IIIFProvider>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensSearch;
