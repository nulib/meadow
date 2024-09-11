import React, { useEffect, useRef, useState } from "react";
import S3ObjectProvider from './S3ObjectProvider';
import { styled } from '@stitches/react';

import {
  ChonkyActions,
  FileBrowser,
  FileList,
  FileNavbar,
  FileToolbar,
} from "chonky";
import { ChonkyIconFA } from "chonky-icon-fontawesome";

const StyledFilePicker = styled('div', {
  "& .chonky-toolbarRight": {
    display: "none"
  }
});

const S3ObjectPicker = ({
  onFileSelect,
  fileSetRole,
  workTypeId,
  defaultPrefix = "",
}) => {
  const [prefix, setPrefix] = useState(defaultPrefix);
  const [selectedFile, setSelectedFile] = useState(null);
  const [error, setError] = useState(null);

  const fileBrowserRef = useRef(null);
  const providerRef = useRef(null);

  useEffect(() => {
    const fileSet = providerRef?.current?.findFileSetByUri(selectedFile);
    fileSet && onFileSelect && onFileSelect(fileSet);
  }, [selectedFile]);

  const handleFileAction = (action) => {
    switch (action.id) {
      case ChonkyActions.OpenFiles.id:
        const { targetFile } = action.payload;
        if (targetFile.isDir) {
          setPrefix(action.payload.targetFile.id);
        }
        break;

      case ChonkyActions.ChangeSelection.id:
        if (
          action.payload.selection.size == 0 &&
          files.find(({ id }) => selectedFile == id)
        ) {
          fileBrowserRef.current.setFileSelection(new Set([selectedFile]));
          return;
        }

        const selectedFiles = [...action.payload.selection];
        const clicked = selectedFiles[selectedFiles.length - 1];

        if (selectedFiles.length > 1) {
          // Reject multiselect
          fileBrowserRef.current.setFileSelection(new Set([clicked]));
        } else if (
          clicked &&
          clicked.match(/^s3:/) &&
          selectedFile != clicked
        ) {
          setSelectedFile(clicked);
        }
        break;
    }
  };

  return (
    <StyledFilePicker className="file-picker" data-testid="file-picker">
      {error && <div className="error">{error}</div>}
      <S3ObjectProvider fileSetRole={fileSetRole} workTypeId={workTypeId} prefix={prefix} ref={providerRef}>
        <FileBrowser          
          ref={fileBrowserRef}
          defaultFileViewActionId={ChonkyActions.EnableListView.id}
          onFileAction={handleFileAction}
          iconComponent={ChonkyIconFA}
        >
          <FileNavbar />
          <FileToolbar />
          <FileList/>
        </FileBrowser>
      </S3ObjectProvider>
    </StyledFilePicker>
  );
};

export default S3ObjectPicker;
