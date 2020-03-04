import React from "react";
import Layout from "../Layout";
import Loading from "../../components/UI/Loading";
import SearchResultItem from "../../components/Search/ResultItem";
import { ReactiveList } from "@appbaseio/reactivesearch";

const ScreensWorkList = () => {
  return (
    <Layout>
      <section className="section">
        <div className="container">
          <ReactiveList
            componentId="SearchResult"
            dataField="accession_number"
            defaultQuery={() => ({
              query: {
                bool: {
                  must: [
                    {
                      match: {
                        "model.name": "Image"
                      }
                    }
                  ]
                }
              }
            })}
            innerClass={{
              list: "columns is-multiline",
              resultStats: "is-size-6 has-text-grey"
            }}
            react={{
              and: ["SearchSensor"]
            }}
            renderItem={res => {
              return (
                <div
                  key={res._id}
                  className="column is-half-tablet is-one-third-desktop is-one-quarter-widescreen"
                >
                  <SearchResultItem res={res} />
                </div>
              );
            }}
            showResultStats={true}
          />
        </div>
      </section>
    </Layout>
  );
};

export default ScreensWorkList;
