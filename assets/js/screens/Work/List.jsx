import React, { useState } from "react";
import Layout from "../Layout";
import { ReactiveList } from "@appbaseio/reactivesearch";
import { IIIFProvider } from "../../components/IIIF/IIIFProvider";
import WorkCardItem from "../../components/Work/CardItem";
import WorkListItem from "../../components/Work/ListItem";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";
import { prepWorkItemForDisplay } from "../../services/helpers";

const ScreensWorkList = () => {
  const [isListView, setIsListView] = useState(false);

  return (
    <Layout>
      <section className="section">
        <div className="column is-hidden-touch">
          <div className="buttons is-right ">
            <button
              className="button is-text"
              onClick={() => setIsListView(false)}
              title="Grid View"
            >
              <span className={`icon ${isListView ? "has-text-grey" : ""}`}>
                <FontAwesomeIcon size="2x" icon="th-large" />
              </span>
            </button>

            <button
              className="button is-text"
              onClick={() => setIsListView(true)}
              title="List View"
            >
              <span className={`icon ${!isListView ? "has-text-grey" : ""}`}>
                <FontAwesomeIcon size="2x" icon="th-list" />
              </span>
            </button>
          </div>
        </div>
        <div className="container">
          <p>
            <Link to="/batch-edit">Go to batch edit</Link>
          </p>
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
                      <WorkListItem
                        key={res._id}
                        {...prepWorkItemForDisplay(res)}
                      />
                    </div>
                  );
                }
                return (
                  <div
                    key={res._id}
                    className="column is-half-tablet is-one-third-desktop is-one-quarter-widescreen"
                  >
                    <WorkCardItem
                      key={res._id}
                      {...prepWorkItemForDisplay(res)}
                    />
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

export default ScreensWorkList;
