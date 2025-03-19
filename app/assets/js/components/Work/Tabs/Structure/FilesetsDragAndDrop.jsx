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
}) {
  const [state, setState] = useState({ fileSets });

  const indexArray = state.fileSets.map((fs) => ({
    id: fs.id,
    group_with: fs.group_with,
    droppableId: fs.group_with ? fs.group_with : "access",
  }));

  function handleSaveClick() {
    handleSaveReorder(state.fileSets.map((fs) => fs.id));
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

  return (
    <div data-testid="fileset-dnd-wrapper">
      <div className="has-text-centered">
        <div className="buttons is-justify-content-center my-4">
          <Button
            isPrimary
            onClick={handleSaveClick}
            data-testid="button-reorder-save"
          >
            Save Fileset Order
          </Button>
          <Button
            isText
            onClick={handleCancelClick}
            data-testid="button-reorder-cancel"
          >
            Cancel
          </Button>
        </div>
      </div>
      <DragDropContext onDragEnd={onDragEnd}>
        <WorkFilesetList fileSets={{ access: state.fileSets }} isReordering />
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
