import React from "react";
import PropTypes from "prop-types";
import WorkFilesetListItem from "@js/components/Work/Fileset/ListItem";
import WorkFilesetDraggable from "@js/components/Work/Fileset/Draggable";
import WorkTabsStructureWebVTTModal from "@js/components/Work/Tabs/Structure/WebVTTModal";
import { useWorkState } from "@js/context/work-context";
import { Droppable } from "react-beautiful-dnd";

function SubHead({ children }) {
  return <h3 className="my-4 ml-5 is-size-5">{children}</h3>;
}
function WorkFilesetList({
  fileSets,
  handleUpdateFileSet,
  handleWorkImageChange,
  isEditing,
  isReordering,
  workImageFilesetId,
  work,
}) {
  const { webVttModal } = useWorkState();

  const uniqueGroupWithValues = fileSets.access
    .filter((fs) => fs.group_with !== null)
    .map((fs) => fs.group_with)
    .filter((value, index, self) => self.indexOf(value) === index);

  if (isReordering) {
    return (
      <Droppable droppableId="access" type="fileset">
        {(provided) => (
          <div ref={provided.innerRef} {...provided.droppableProps}>
            <div data-testid="fileset-draggable-list" className="mb-5">
              {fileSets.access
                .filter((fileSet) => !fileSet.group_with)
                .map((fileSet, index) => {
                  const groupedFileSets = fileSets.access.filter(
                    (entry) => entry.group_with === fileSet.id,
                  );

                  const candidateFileSets = fileSets.access.filter((fs) => {
                    return (
                      fs.id !== fileSet.id &&
                      fs.group_with === null &&
                      !uniqueGroupWithValues.includes(fs.id)
                    );
                  });

                  return (
                    <WorkFilesetDraggable
                      key={fileSet.id}
                      fileSet={fileSet}
                      candidateFileSets={candidateFileSets}
                      groupedFileSets={groupedFileSets}
                      handleUpdateFileSet={handleUpdateFileSet}
                      index={index}
                    />
                  );
                })}
            </div>
            {provided.placeholder}
          </div>
        )}
      </Droppable>
    );
  }

  return (
    <>
      {/* Access Files  */}
      <div data-testid="fileset-list" className="mb-5">
        <SubHead>Access files</SubHead>
        {fileSets.access
          .filter((fileSet) => !fileSet.group_with)
          .map((fileSet) => {
            // get all filesets that have a group_with value matching fileSet.id
            const groupedFileSets = fileSets.access.filter(
              (entry) => entry.group_with === fileSet.id,
            );

            return (
              <>
                <WorkFilesetListItem
                  key={fileSet.id}
                  fileSet={fileSet}
                  handleWorkImageChange={handleWorkImageChange}
                  isEditing={isEditing}
                  workImageFilesetId={workImageFilesetId}
                  groupedFileSets={groupedFileSets}
                />
              </>
            );
          })}
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
  work: PropTypes.shape({
    id: PropTypes.string,
    behavior: PropTypes.shape({
      id: PropTypes.string,
      label: PropTypes.string,
    })
  }),
};

export default WorkFilesetList;
