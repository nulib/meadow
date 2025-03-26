/** @jsx jsx */

import { useWorkDispatch, useWorkState } from "@js/context/work-context";

import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import PropTypes from "prop-types";
import React, { useContext } from "react";
import { Tag } from "@nulib/design-system";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import WorkFilesetActionButtonsAccess from "@js/components/Work/Fileset/ActionButtons/Access";
import WorkFilesetActionButtonsAuxillary from "@js/components/Work/Fileset/ActionButtons/Auxillary";
import useFileSet from "@js/hooks/useFileSet";
import { css, jsx } from "@emotion/react";

function WorkFilesetListItem({
  fileSet,
  handleWorkImageChange,
  isEditing,
  workImageFilesetId,
  groupedFileSets,
}) {
  const { id, coreMetadata, group_with, accessionNumber } = fileSet;
  const { hasRepresentativeImage, isImage, isMedia, isPDF, isZip } =
    useFileSet();
  const workContextState = useWorkState();

  // Helper for media type file sets
  const isCurrentStateFileSet =
    workContextState?.activeMediaFileSet?.id === fileSet?.id;

  // https://stackoverflow.com/questions/34097560/react-js-replace-img-src-onerror
  const [imgState, setImgState] = React.useState({
    errored: false, // This prevents a potential infinite loop
    src: `${fileSet.representativeImageUrl}/${
      isMedia(fileSet) ? "full" : "square"
    }/100,/0/default.jpg`,
  });

  const figure = css`
    width: 100px;
    height: 100px;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 0.25rem;
    }
  `;

  const flex = css`
    display: flex;
    gap: 1em;
  `;

  const fileSetGroup = css`
    margin-top: 2rem;
    padding: 1.5rem;
    background: #0001;
    border-radius: 0.25rem;
  `;

  const handleError = (e) => {
    if (!imgState.errored) {
      setImgState({
        errored: true,
        src: placeholderImage(fileSet),
      });
    }
  };

  const placeholderImage = (fileSet) => {
    if (isMedia(fileSet)) {
      return "/images/video-placeholder2.png";
    } else if (isPDF(fileSet)) {
      return "/images/placeholder-pdf.png";
    } else if (isZip(fileSet)) {
      return "/images/placeholder-zip.png";
    } else {
      return "/images/placeholder.png";
    }
  };

  const showWorkImageToggle = () => {
    if (fileSet.role.id === "A" && workContextState.workTypeId === "AUDIO") {
      return false;
    } else {
      return isImage(fileSet) || hasRepresentativeImage(fileSet);
    }
  };

  return (
    <article
      className={`box is-relative`}
      data-testid="fileset-item"
      style={{
        zIndex: group_with ? 0 : 1,
      }}
    >
      <div css={flex}>
        <div>
          <figure css={figure}>
            <img
              src={imgState.src}
              placeholder="Fileset Image"
              data-testid="fileset-image"
              onError={handleError}
            />
          </figure>
        </div>
        <div className="is-flex-grow-1">
          {isMedia(fileSet) && isCurrentStateFileSet && (
            <span className="mb-4 is-inline-block">
              <Tag isInfo>Now Playing</Tag>
            </span>
          )}

          <UIFormField label="Label">
            {isEditing ? (
              <UIFormInput
                isReactHookForm
                required
                label="Label"
                name={`${id}.label`}
                data-testid="input-label"
                placeholder="Label"
                defaultValue={coreMetadata.label}
              />
            ) : (
              <p>{coreMetadata.label}</p>
            )}
          </UIFormField>

          <UIFormField label="Description">
            {isEditing ? (
              <UIFormTextarea
                isReactHookForm
                name={`${id}.description`}
                data-testid="textarea-metadata-description"
                defaultValue={coreMetadata.description}
                label="Description"
                rows="2"
              />
            ) : (
              <p>{coreMetadata.description}</p>
            )}
          </UIFormField>

          <UIFormField label="Accession Number">
            <p>{accessionNumber}</p>
          </UIFormField>
        </div>
        <div className="has-text-right is-clearfix">
          {!isEditing && (
            <>
              {showWorkImageToggle() && !fileSet.group_with && (
                <AuthDisplayAuthorized>
                  <div className="field">
                    <input
                      id={`checkbox-work-switch-${id}`}
                      type="checkbox"
                      name={`checkbox-work-switch-${id}`}
                      className="switch is-info"
                      checked={workImageFilesetId === id}
                      onChange={() => handleWorkImageChange(id)}
                      data-testid="work-image-selector"
                    />
                    <label htmlFor={`checkbox-work-switch-${id}`}>
                      Work image
                    </label>
                  </div>
                </AuthDisplayAuthorized>
              )}

              {fileSet.role.id === "A" && (
                <WorkFilesetActionButtonsAccess fileSet={fileSet} />
              )}
              {fileSet.role.id === "X" && (
                <WorkFilesetActionButtonsAuxillary fileSet={fileSet} />
              )}
            </>
          )}
        </div>
      </div>

      {groupedFileSets?.length ? (
        <div css={fileSetGroup}>
          {groupedFileSets.map((groupedFileSet) => (
            <WorkFilesetListItem
              key={groupedFileSet.id}
              fileSet={groupedFileSet}
              handleWorkImageChange={handleWorkImageChange}
              isEditing={isEditing}
              workImageFilesetId={workImageFilesetId}
            />
          ))}
        </div>
      ) : (
        <></>
      )}
    </article>
  );
}

WorkFilesetListItem.propTypes = {
  fileSet: PropTypes.object,
  handleWorkImageChange: PropTypes.func,
  isEditing: PropTypes.bool,
  workImageFilesetId: PropTypes.string,
};

export default WorkFilesetListItem;
