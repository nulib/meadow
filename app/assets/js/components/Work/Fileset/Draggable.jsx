/** @jsx jsx */

import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Draggable, Droppable } from "react-beautiful-dnd";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { css, jsx } from "@emotion/react";

function WorkFilesetDraggable({
  fileSet,
  index,
  isGrouped = false,
  groupedFileSets = [],
}) {
  const iiifServerUrl = useContext(IIIFContext);

  const article = css`
    position: relative;
    z-index: 0;
    background: white;
    transition: all 0.25s ease;
    padding: 1rem;
    outline: none;
    margin-top: 0;

    &[data-is-dragging="true"] {
      background: rgb(233, 244, 255);
      outline: 2px solid #5091cd;

      article[data-is-grouped="true"] {
        background: rgb(233, 244, 255) !important;
      }
    }
  `;

  const figure = css`
    width: 48px;
    height: 48px;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 0.25rem;
    }
  `;

  const content = css`
    gap: 1rem;
  `;

  const fileSetGroup = css`
    position: relative;
    z-index: 1;
    margin-top: 1rem;
    padding: 1.5rem;
    background: #0001;
    border-radius: 0.25rem;
  `;

  return (
    <Draggable draggableId={fileSet.id} index={index}>
      {(provided, snapshot) => (
        <>
          <article
            ref={provided.innerRef}
            {...provided.draggableProps}
            {...provided.dragHandleProps}
            className="box"
            css={article}
            data-testid="fileset-draggable-item"
            data-is-dragging={snapshot.isDragging}
            data-is-grouped={isGrouped}
          >
            <div css={content} className="is-flex">
              <figure css={figure}>
                <img
                  src={`${iiifServerUrl}${fileSet.id}/square/64,64/0/default.jpg`}
                  placeholder="Fileset Image"
                  data-testid="fileset-image"
                />
              </figure>
              <div>
                <span data-testid="fileset-label" className="is-bold">
                  {fileSet.coreMetadata.label}
                </span>
                <p data-testid="fileset-description" className="is-muted">
                  {fileSet.coreMetadata.description}
                </p>
              </div>
            </div>

            {groupedFileSets.length ? (
              <div css={fileSetGroup}>
                <Droppable droppableId={fileSet.id} type="fileset-group-with">
                  {(provided) => (
                    <div ref={provided.innerRef} {...provided.droppableProps}>
                      {groupedFileSets.map((groupedFileSet, index) => (
                        <WorkFilesetDraggable
                          key={groupedFileSet.id}
                          fileSet={groupedFileSet}
                          index={index}
                          isGrouped={true}
                        />
                      ))}
                      {provided.placeholder}
                    </div>
                  )}
                </Droppable>
              </div>
            ) : (
              <></>
            )}
          </article>
        </>
      )}
    </Draggable>
  );
}

WorkFilesetDraggable.propTypes = {
  fileSet: PropTypes.object,
  index: PropTypes.number,
};

export default WorkFilesetDraggable;
