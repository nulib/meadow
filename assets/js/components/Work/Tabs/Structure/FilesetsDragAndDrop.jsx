import React, { useState } from "react";
import WorkTabsStructureFilesetList from "@js/components/Work/Tabs/Structure/FilesetList";
import PropTypes from "prop-types";
import { DragDropContext, Droppable } from "react-beautiful-dnd";
import { Button } from "@nulib/admin-react-components";

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
      <div className="columns">
        <div className="column">
          <Button
            className="is-fullwidth"
            isPrimary
            onClick={() => handleSaveReorder(state.fileSets.map((fs) => fs.id))}
            data-testid="button-reorder-save"
          >
            Save Order
          </Button>
        </div>
        <div className="column">
          <Button
            isText
            className="is-fullwidth"
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
              <WorkTabsStructureFilesetList
                fileSets={state.fileSets}
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
