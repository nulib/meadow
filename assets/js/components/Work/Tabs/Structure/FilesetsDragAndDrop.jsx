import React, { useState } from "react";
import WorkTabsStructureFilesetList from "@js/components/Work/Tabs/Structure/FilesetList";
import PropTypes from "prop-types";
import { DragDropContext, Droppable } from "react-beautiful-dnd";

const reorder = (list, startIndex, endIndex) => {
  const result = Array.from(list);
  const [removed] = result.splice(startIndex, 1);
  result.splice(endIndex, 0, removed);

  return result;
};

function FilesetsDragAndDrop({
  filesets,
  handleDownloadClick,
  handleWorkImageChange,
  isEditing,
  workImageFilesetId,
}) {
  const [state, setState] = useState({ filesets });

  function onDragEnd(result) {
    if (!result.destination) {
      return;
    }

    if (result.destination.index === result.source.index) {
      return;
    }

    const updatedFilesets = reorder(
      state.filesets,
      result.source.index,
      result.destination.index
    );

    setState({ filesets: updatedFilesets });
  }

  return (
    <DragDropContext onDragEnd={onDragEnd}>
      <Droppable droppableId="list">
        {(provided) => (
          <div ref={provided.innerRef} {...provided.droppableProps}>
            <WorkTabsStructureFilesetList
              filesets={state.filesets}
              handleDownloadClick={handleDownloadClick}
              handleWorkImageChange={handleWorkImageChange}
              isEditing={isEditing}
              workImageFilesetId={workImageFilesetId}
            />
            {provided.placeholder}
          </div>
        )}
      </Droppable>
    </DragDropContext>
  );
}

FilesetsDragAndDrop.propTypes = {
  filesets: PropTypes.array,
  handleDownloadClick: PropTypes.func,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default FilesetsDragAndDrop;
