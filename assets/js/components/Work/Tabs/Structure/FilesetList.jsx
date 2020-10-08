import React from "react";
import PropTypes from "prop-types";
import WorkTabsStructureFileset from "./Fileset";
import WorkTabsStructureFilesetDraggable from "./FilesetDraggable";

function FilesetList({ fileSets, isReordering, ...restProps }) {
  if (isReordering) {
    return (
      <div data-testid="fileset-draggable-list" className="mb-5">
        {fileSets.map((fileSet, index) => (
          <WorkTabsStructureFilesetDraggable
            key={fileSet.id}
            fileSet={fileSet}
            index={index}
          />
        ))}
      </div>
    );
  }
  return (
    <div data-testid="fileset-list" className="mb-5">
      {fileSets.map((fileSet) => (
        <WorkTabsStructureFileset
          key={fileSet.id}
          fileSet={fileSet}
          {...restProps}
        />
      ))}
    </div>
  );
}

FilesetList.propTypes = {
  fileSets: PropTypes.array,
  handleDownloadClick: PropTypes.func,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  isReordering: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default FilesetList;
