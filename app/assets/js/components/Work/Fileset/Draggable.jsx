/** @jsx jsx */

import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Draggable, Droppable } from "react-beautiful-dnd";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { css, jsx } from "@emotion/react";
import WorkFilesetActionButtonsGroupRemove from "./ActionButtons/GroupRemove";
import WorkFilesetActionButtonsGroupAdd from "./ActionButtons/GroupAdd";

function WorkFilesetDraggable({
  fileSet,
  handleUpdateFileSet,
  index,
  isGrouped = false,
  candidateFileSets = [],
  groupedFileSets = [],
}) {
  const iiifServerUrl = useContext(IIIFContext);

  const article = css`
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
    flex-shrink: 0;

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

  const metadata = css`
    flex-grow: 1;
  `;

  const actions = css`
    min-width: 150px;
    flex-shrink: 0;
    justify-content: flex-end;
    display: flex;
  `;

  const fileSetGroup = css`
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
            data-fileset-id={fileSet.id}
          >
            <div css={content} className="is-flex">
              <figure css={figure}>
                <img
                  src={`${iiifServerUrl}${fileSet.id}/square/64,64/0/default.jpg`}
                  placeholder="Fileset Image"
                  data-testid="fileset-image"
                />
              </figure>
              <div css={metadata}>
                <span data-testid="fileset-label" className="is-bold">
                  {fileSet.coreMetadata.label}
                </span>
                <p data-testid="fileset-accession-number" className="is-muted">
                  {fileSet.accessionNumber}
                </p>
              </div>
              <div css={actions}>
                {fileSet.group_with ? (
                  <WorkFilesetActionButtonsGroupRemove
                    fileSetId={fileSet.id}
                    handleUpdateFileSet={handleUpdateFileSet}
                  />
                ) : (
                  <WorkFilesetActionButtonsGroupAdd
                    fileSetId={fileSet.id}
                    candidateFileSets={candidateFileSets}
                    handleUpdateFileSet={handleUpdateFileSet}
                    iiifServerUrl={iiifServerUrl}
                  />
                )}
              </div>
            </div>

            {groupedFileSets.length ? (
              <div css={fileSetGroup}>
                <Droppable
                  droppableId={fileSet.id}
                  type={`fileset-group-with-${fileSet.id}`}
                >
                  {(provided) => (
                    <div ref={provided.innerRef} {...provided.droppableProps}>
                      {groupedFileSets.map((groupedFileSet, index) => (
                        <WorkFilesetDraggable
                          key={groupedFileSet.id}
                          fileSet={groupedFileSet}
                          index={index}
                          isGrouped={true}
                          handleUpdateFileSet={handleUpdateFileSet}
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
