import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Draggable } from "react-beautiful-dnd";
import UIFormField from "@js/components/UI/Form/Field";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

const content = css`
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
`;

function WorkFilesetDraggable({ fileSet, index }) {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <Draggable draggableId={fileSet.id} index={index}>
      {(provided) => (
        <article
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          className="box"
          data-testid="fileset-draggable-item"
        >
          <div css={content}>
            <figure className="image mr-4">
              <img
                src={`${iiifServerUrl}${fileSet.id}/square/64,64/0/default.jpg`}
                placeholder="Fileset Image"
                data-testid="fileset-image"
              />
            </figure>
            <UIFormField label="Label">
              <p className="mr-6" data-testid="fileset-label">
                {fileSet.coreMetadata.label}
              </p>
            </UIFormField>

            <UIFormField label="Description">
              <p data-testid="fileset-description">
                {fileSet.coreMetadata.description}
              </p>
            </UIFormField>
          </div>
        </article>
      )}
    </Draggable>
  );
}

WorkFilesetDraggable.propTypes = {
  fileSet: PropTypes.object,
  index: PropTypes.number,
};

export default WorkFilesetDraggable;
