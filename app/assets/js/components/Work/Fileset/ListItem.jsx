import { Button, Tag } from "@nulib/design-system";
import React, { useContext } from "react";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IconPlay } from "@js/components/Icon";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import WorkFilesetActionButtonsAccess from "@js/components/Work/Fileset/ActionButtons/Access";
import WorkFilesetActionButtonsAuxillary from "@js/components/Work/Fileset/ActionButtons/Auxillary";
import useFileSet from "@js/hooks/useFileSet";

function WorkFilesetListItem({
  fileSet,
  handleWorkImageChange,
  isEditing,
  workImageFilesetId,
}) {
  const iiifServerUrl = useContext(IIIFContext);
  const { id, coreMetadata } = fileSet;
  const dispatch = useWorkDispatch();
  const {isImage, isMedia, isPDF, isZip } = useFileSet();
  const workContextState = useWorkState();

  // Helper for media type file sets
  const isCurrentStateFileSet =
    workContextState?.activeMediaFileSet?.id === fileSet?.id;

  // https://stackoverflow.com/questions/34097560/react-js-replace-img-src-onerror
  const [imgState, setImgState] = React.useState({
    errored: false, // This prevents a potential infinite loop
    src: `${fileSet.representativeImageUrl}/${
      isMedia(fileSet) ? "full" : "square"
    }/500,/0/default.jpg`,
  });

  const handleError = (e) => {
    if (!imgState.errored) {
      setImgState({
        errored: true,
        src: placeholderImage(fileSet),
      });
    }
  };

  const placeholderImage = (fileSet) =>  {
    if (isMedia(fileSet)) {
      return "/images/video-placeholder2.png";
    } else if (isPDF(fileSet)) {  
      return "/images/placeholder-pdf.png";
    } else if (isZip(fileSet)) {  
      return "/images/placeholder-zip.png";
    } else {
      return "/images/placeholder.png";
    }
  }

  const showWorkImageToggle = () => {
    if (fileSet.role.id === "A" && workContextState.workTypeId === "AUDIO") {
      return false;
    } else {
      return isImage(fileSet);
    }
  }

  return (
    <article className="box" data-testid="fileset-item">
      <div className="columns">
        <div className="column is-2">
          <figure className="image">
            <img
              src={imgState.src}
              placeholder="Fileset Image"
              data-testid="fileset-image"
              onError={handleError}
            />
          </figure>
        </div>
        <div className="column">
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
        </div>
        <div className="column is-5 has-text-right is-clearfix">
          {!isEditing && (
            <>
              {(
                showWorkImageToggle()
              ) && (
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
              {fileSet.role.id === "S" && (
                <WorkFilesetActionButtonsSupplemental fileSet={fileSet} />
              )}
            </>
          )}
        </div>
      </div>
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
