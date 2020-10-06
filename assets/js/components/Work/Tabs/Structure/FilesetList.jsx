import React from "react";
import PropTypes from "prop-types";
import WorkTabsStructureFileset from "./Fileset";

function FilesetList({ filesets, ...restProps }) {
  return (
    <div data-testid="fileset-list" className="mb-5">
      {filesets.map((fileset, index) => (
        <WorkTabsStructureFileset
          key={fileset.id}
          fileset={fileset}
          index={index}
          {...restProps}
        />
      ))}
    </div>
  );
}

FilesetList.propTypes = {
  filesets: PropTypes.array,
  handleDownloadClick: PropTypes.func,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default FilesetList;
