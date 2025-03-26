import React, { useState } from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { DragDropContext } from "react-beautiful-dnd";
import WorkFilesetList from "@js/components/Work/Fileset/List";

function reorder(list, startIndex, endIndex) {
  const result = Array.from(list);
  const [removed] = result.splice(startIndex, 1);
  result.splice(endIndex, 0, removed);

  return result;
}

function FilesetsDragAndDrop({
  fileSets,
  handleCancelReorder,
  handleSaveReorder,
  handleGroupWithUpdate,
}) {
  const [state, setState] = useState({ fileSets });

  const indexArray = state.fileSets.map((fs) => ({
    id: fs.id,
    group_with: fs.group_with,
    droppableId: fs.group_with ? fs.group_with : "access",
  }));

  function handleSaveClick() {
    // Update order of all filesets
    handleSaveReorder(state.fileSets.map((fs) => fs.id));

    // Update group_with values for applicable filesets
    const updateGroupWith = state.fileSets.filter((fs) =>
      fileSets.find(
        (fs2) => fs2.id === fs.id && fs2.group_with !== fs.group_with,
      ),
    );

    handleGroupWithUpdate(updateGroupWith);
  }

  function handleCancelClick() {
    setState({ fileSets });
    handleCancelReorder();
  }

  function onDragEnd(result) {
    if (!result.destination) return;
    if (result.destination.index === result.source.index) return;

    const { source, destination } = result;

    // 1) Find absolute start index
    const sourceSubset = indexArray.filter(
      (fs) => fs.droppableId === source.droppableId,
    );
    const draggedItem = sourceSubset[source.index];
    const startIndex = indexArray.findIndex((fs) => fs.id === draggedItem?.id);

    // 2) Find absolute end index
    const destinationSubset = indexArray.filter(
      (fs) => fs.droppableId === destination.droppableId,
    );

    let endIndex;
    if (destination.index >= destinationSubset.length) {
      // Dropping at the end of the subset
      endIndex =
        indexArray.findIndex(
          (fs) => fs.id === destinationSubset[destinationSubset.length - 1]?.id,
        ) + 1;
    } else {
      const targetItem = destinationSubset[destination.index];
      endIndex = indexArray.findIndex((fs) => fs.id === targetItem?.id);
    }

    if (startIndex === -1 || endIndex === -1) return;

    // 3) Reorder the state
    const updatedFileSets = reorder(state.fileSets, startIndex, endIndex);
    setState({ fileSets: updatedFileSets });
  }

  function handleUpdateFileSet(id, groupWith) {
    const updatedFileSets = state.fileSets.map((fs) => {
      if (fs.id === id) {
        return { ...fs, group_with: groupWith };
      }
      return fs;
    });

    setState({ fileSets: updatedFileSets });
  }

  return (
    <div data-testid="fileset-dnd-wrapper">
      <div className="has-text-centered">
        <div className="buttons is-justify-content-center my-4">
          <Button
            isPrimary
            onClick={handleSaveClick}
            data-testid="button-reorder-save"
          >
            Save
          </Button>
          <Button
            onClick={handleCancelClick}
            data-testid="button-reorder-cancel"
          >
            Cancel
          </Button>
        </div>
      </div>
      <DragDropContext onDragEnd={onDragEnd}>
        <WorkFilesetList
          fileSets={{ access: state.fileSets }}
          handleUpdateFileSet={handleUpdateFileSet}
          isReordering
        />
      </DragDropContext>
    </div>
  );
}

FilesetsDragAndDrop.propTypes = {
  fileSets: PropTypes.array,
  handleCancelReorder: PropTypes.func,
  handleSaveReorder: PropTypes.func,
};

export default FilesetsDragAndDrop;
