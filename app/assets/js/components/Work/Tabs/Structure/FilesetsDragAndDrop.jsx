import React, { useState } from "react";
import WorkFilesetList from "@js/components/Work/Fileset/List";
import PropTypes from "prop-types";
import { DragDropContext, Droppable } from "react-beautiful-dnd";
import { Button } from "@nulib/design-system";

const reorder = (list, startIndex, endIndex) => {
  const result = Array.from(list);
  const [removed] = result.splice(startIndex, 1);
  result.splice(endIndex, 0, removed);

  return result;
};

function FilesetsDragAndDrop({
  fileSets,
  handleCancelReorder,
  handleSaveReorder,
}) {
  const [state, setState] = useState({ fileSets });

  function handleCancelClick() {
    setState({ fileSets });
    handleCancelReorder();
  }

  function onDragEnd(result) {
    if (!result.destination) {
      return;
    }

    if (result.destination.index === result.source.index) {
      return;
    }

    const updatedFileSets = reorder(
      state.fileSets,
      result.source.index,
      result.destination.index
    );

    setState({ fileSets: updatedFileSets });
  }

  return (
    <div data-testid="fileset-dnd-wrapper">
      <div className="has-text-centered">
        <div className="buttons is-justify-content-center my-4">
          <Button
            isPrimary
            onClick={() => handleSaveReorder(state.fileSets.map((fs) => fs.id))}
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
        <Droppable droppableId="list">
          {(provided) => (
            <div ref={provided.innerRef} {...provided.droppableProps}>
              <WorkFilesetList
                fileSets={{ access: state.fileSets }}
                isReordering
              />
              {provided.placeholder}
            </div>
          )}
        </Droppable>
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
