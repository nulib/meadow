import React, { useState } from "react";
import PropTypes from "prop-types";
import { IIIFProvider } from "../../components/IIIF/IIIFProvider";
import { ReactiveList } from "@appbaseio/reactivesearch";
import WorkListItem from "../../components/Work/ListItem";
import WorkCardItem from "../../components/Work/CardItem";
import UISkeleton from "../../components/UI/Skeleton";
import SearchSelectable from "../../components/Search/Selectable";
import UIResultsDisplaySwitcher from "../../components/UI/ResultsDisplaySwitcher";

const SearchResults = ({ handleSelectItem }) => {
  const [isListView, setIsListView] = useState(false);
  const getWorkItem = (res) => {
    return {
      id: res._id,
      title: res.descriptiveMetadata.title,
      updatedAt: res.modified_date,
      representativeImage: res.representativeFileSet,
      manifestUrl: res.iiifManifest,
      published: res.published,
      visibility: res.visibility,
      fileSets: res.fileSets.length,
      accessionNumber: res.accessionNumber,
      workType: res.workType,
    };
  };

  return (
    <IIIFProvider>
      <div>
        <UIResultsDisplaySwitcher
          isListView={isListView}
          onGridClick={() => setIsListView(false)}
          onListClick={() => setIsListView(true)}
        />
      </div>
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
        loader={<UISkeleton rows={10} />}
        react={{
          and: ["SearchSensor"],
        }}
        renderItem={(res) => {
          if (isListView) {
            return (
              <div key={res._id} className="box">
                <SearchSelectable
                  key={res._id}
                  id={res._id}
                  handleSelectItem={handleSelectItem}
                  wrapsItemType="list"
                >
                  <WorkListItem key={res._id} {...getWorkItem(res)} />
                </SearchSelectable>
              </div>
            );
          }
          return (
            <div
              key={res._id}
              className="column is-half-tablet is-one-third-desktop is-one-quarter-widescreen"
            >
              <SearchSelectable
                key={res._id}
                id={res._id}
                handleSelectItem={handleSelectItem}
                wrapsItemType="card"
              >
                <WorkCardItem key={res._id} {...getWorkItem(res)} />
              </SearchSelectable>
            </div>
          );
        }}
        showResultStats={true}
      />
    </IIIFProvider>
  );
};

SearchResults.propTypes = {
  handleSelectItem: PropTypes.func,
};

export default SearchResults;
