import * as Dialog from "@radix-ui/react-dialog";

import {
  DialogClose,
  DialogContent,
  DialogOverlay,
  DialogTitle,
  DialogTrigger,
} from "@js/components/UI/Dialog/Dialog.styled";
import {
  IconArrowDown,
  IconBinaryFile,
  IconBucket,
  IconCopyToClipboard,
  IconList,
  IconReplace,
  IconTrashCan,
  IconView,
} from "@js/components/Icon";
import React, { useState } from "react";

import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { Icon } from "@nulib/design-system";
import WorkTabsPreservationTechnical from "@js/components/Work/Tabs/Preservation/Technical";
import classNames from "classnames";
import { toastWrapper } from "@js/services/helpers";
import { useClipboard } from "use-clipboard-copy";

const PreservationActionsCol = ({
  deleteFilesetModal,
  fileset,
  handleConfirmDeleteFileset,
  handleDeleteFilesetClick,
  handleTechnicalMetaClick,
  handleReplaceFilesetClick,
  handleViewFilesetActionStates,
  technicalMetadata,
  work,
}) => {
  const [isActionsOpen, setIsActionsOpen] = React.useState(false);

  const dropdownRef = React.useRef(null);
  const actionItemClasses = `dropdown-item is-flex is-align-items-center`;

  const handleActionsToggle = () => {
    setIsActionsOpen(!isActionsOpen);
  };

  React.useEffect(() => {
    const handleClickOutside = (event) => {
      if (
        isActionsOpen &&
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target)
      )
        setIsActionsOpen(false);
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [isActionsOpen, dropdownRef]);

  const clipboard = useClipboard({
    onSuccess() {
      toastWrapper("is-success", `Copied successfully.`);
    },
    onError() {
      toastWrapper("is-danger", "Failed to copy.");
    },
  });

  return (
    <div
      data-testid="fileset-actions"
      className={classNames("dropdown", "is-right", {
        "is-active": isActionsOpen,
      })}
    >
      <div className="dropdown-trigger">
        <button
          type="button"
          className="button"
          aria-haspopup="true"
          aria-controls="dropdown-menu"
          onClick={handleActionsToggle}
        >
          <span>Actions</span>
          <IconArrowDown className="icon" />
        </button>
      </div>
      <div
        className="dropdown-menu"
        id="dropdown-menu"
        role="menu"
        ref={dropdownRef}
      >
        <div className="dropdown-content">
          <a
            className={actionItemClasses}
            onClick={() => clipboard.copy(fileset.id)}
          >
            <IconCopyToClipboard />
            <span style={{ marginLeft: "0.5rem" }}>Copy id to clipboard</span>
          </a>
          <a
            className={actionItemClasses}
            onClick={() => {
              let digests = {
                ...fileset.coreMetadata.digests,
              };
              delete digests["__typename"];
              return clipboard.copy(JSON.stringify(digests));
            }}
          >
            <IconBinaryFile />
            <span style={{ marginLeft: "0.5rem" }}>
              Copy checksums to clipboard
            </span>
          </a>
          <a
            className={actionItemClasses}
            onClick={() => clipboard.copy(fileset.coreMetadata.location)}
          >
            <IconBucket />
            <span style={{ marginLeft: "0.5rem" }}>
              Copy preservation location to clipboard
            </span>
          </a>
          <div>
            <Dialog.Root>
              <DialogTrigger asChild>
                <a
                  className={actionItemClasses}
                  onClick={() => handleTechnicalMetaClick(fileset)}
                >
                  <IconView />
                  <span
                    style={{
                      marginLeft: "0.5rem",
                    }}
                  >
                    View technical metadata
                  </span>
                </a>
              </DialogTrigger>
              <DialogOverlay />
              <DialogContent>
                <DialogClose>
                  <Icon isSmall aria-label="Close">
                    <Icon.Close />
                  </Icon>
                </DialogClose>
                <DialogTitle css={{ textAlign: "left" }}>
                  Technical Metadata
                </DialogTitle>
                <WorkTabsPreservationTechnical
                  fileSet={technicalMetadata.fileSet}
                />
              </DialogContent>
            </Dialog.Root>
          </div>
          <div>
            <a
              className={actionItemClasses}
              onClick={() => {
                handleViewFilesetActionStates(fileset.id);
                setIsActionsOpen(false);
              }}
            >
              <IconList />
              <span style={{ marginLeft: "0.5rem" }}>
                View fileset action states
              </span>
            </a>
          </div>
          <AuthDisplayAuthorized>
            <a
              className={actionItemClasses}
              onClick={() => handleReplaceFilesetClick(fileset)}
            >
              <IconReplace />
              <span style={{ marginLeft: "0.5rem" }}>Replace fileset</span>
            </a>
          </AuthDisplayAuthorized>
          <AuthDisplayAuthorized>
            <Dialog.Root>
              <DialogTrigger asChild>
                <a
                  className={actionItemClasses}
                  onClick={() => handleDeleteFilesetClick(fileset)}
                >
                  <IconTrashCan />
                  <span style={{ marginLeft: "0.5rem" }}>Delete fileset</span>
                </a>
              </DialogTrigger>
              <DialogOverlay />
              <DialogContent css={{ textAlign: "left" }}>
                <DialogClose>
                  <Icon isSmall aria-label="Close">
                    <Icon.Close />
                  </Icon>
                </DialogClose>
                <DialogTitle>
                  Delete
                  {`Fileset: ${
                    deleteFilesetModal.fileset.coreMetadata
                      ? deleteFilesetModal.fileset.coreMetadata.label
                      : ""
                  }`}
                </DialogTitle>
                {work && (
                  <div
                    style={{ marginTop: "0.5rem" }}
                    data-testid="delete-fileset-modal"
                  >
                    <p className="text-gray-600">
                      This action cannot be undone.
                    </p>
                    <div className="buttons is-right">
                      <Dialog.Close className="button is-text">
                        Cancel
                      </Dialog.Close>
                      <button
                        className="button is-danger"
                        onClick={handleConfirmDeleteFileset}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                )}
              </DialogContent>
            </Dialog.Root>
          </AuthDisplayAuthorized>
        </div>
      </div>
    </div>
  );
};

export default PreservationActionsCol;
