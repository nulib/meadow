import React from "react";
import PropTypes from "prop-types";
import WorkFilesetListItem from "@js/components/Work/Fileset/ListItem";
import WorkFilesetDraggable from "@js/components/Work/Fileset/Draggable";
import WorkTabsStructureWebVTTModal from "@js/components/Work/Tabs/Structure/WebVTTModal";
import { useWorkState } from "@js/context/work-context";

function SubHead({ children }) {
  return <h3 className="my-4 ml-5 is-size-5">{children}</h3>;
}
function WorkFilesetList({
  fileSets,
  handleWorkImageChange,
  isEditing,
  isReordering,
  workImageFilesetId,
}) {
  const { webVttModal } = useWorkState();

  if (isReordering) {
    return (
      <div data-testid="fileset-draggable-list" className="mb-5">
        {fileSets.access.map((fileSet, index) => (
          <WorkFilesetDraggable
            key={fileSet.id}
            fileSet={fileSet}
            index={index}
          />
        ))}
      </div>
    );
  }
  return (
    <>
      {/* Access Files  */}
      <div data-testid="fileset-list" className="mb-5">
        <SubHead>Access files</SubHead>
        {fileSets.access.map((fileSet) => (
          <WorkFilesetListItem
            key={fileSet.id}
            fileSet={fileSet}
            handleWorkImageChange={handleWorkImageChange}
            isEditing={isEditing}
            workImageFilesetId={workImageFilesetId}
          />
        ))}
      </div>

      {/* Auxillary Files  */}
      {fileSets.auxiliary.length > 0 && (
        <>
          <SubHead>Auxiliary files</SubHead>
          {fileSets.auxiliary.map((fileSet) => (
            <WorkFilesetListItem
              key={fileSet.id}
              fileSet={fileSet}
              handleWorkImageChange={handleWorkImageChange}
              isEditing={isEditing}
              workImageFilesetId={workImageFilesetId}
            />
          ))}
        </>
      )}
      <WorkTabsStructureWebVTTModal isActive={webVttModal?.isOpen} />
    </>
  );
}

WorkFilesetList.propTypes = {
  fileSets: PropTypes.object,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  isReordering: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default WorkFilesetList;
