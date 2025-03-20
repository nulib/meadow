/** @jsx jsx */

import React, { useEffect } from "react";
import { css, jsx } from "@emotion/react";

const WorkFilesetActionButtonsGroupAdd = ({
  fileSetId,
  candidateFileSets,
  handleUpdateFileSet,
  iiifServerUrl,
}) => {
  const addRef = React.useRef(null);
  const inputRef = React.useRef(null);
  const [isOpen, setIsOpen] = React.useState(false);

  useEffect(() => {
    const handleClick = (e) => {
      if (addRef.current.contains(e.target)) {
        return;
      }

      setIsOpen(false);
    };

    const handleEscape = (e) => {
      if (e.key === "Escape") {
        setIsOpen(false);
      }
    };

    document.addEventListener("click", handleClick);
    document.addEventListener("keydown", handleEscape);

    return () => {
      document.removeEventListener("click", handleClick);
      document.removeEventListener("keydown", handleEscape);
    };
  }, []);

  const handleFocus = () => {
    setIsOpen(true);
    inputRef.current.style.width = "300px";
  };

  const handleBlur = () => {
    setIsOpen(false);
    inputRef.current.style.width = "150px";
  };

  const add = css`
    position: relative;
    z-index: ${isOpen ? 3 : 1};

    input {
      width: 150px;
      transition: width 0.25s ease;
    }

    input::placeholder {
      color: var(--colors-richBlack50) !important;
    }
  `;

  const content = css`
    position: absolute;
    right: 0;
    z-index: 2;
    display: block;
    background: white;
    width: 300px;
    height: ${isOpen ? "300px" : "0px"};
    transition: all 0.25s ease;
    max-height: 300px;
    overflow-x: hidden;
    overflow-y: ${isOpen ? "auto" : "hidden"};
    opacity: ${isOpen ? 1 : 0};
    padding: 0.5rem;

    button {
      display: flex;
      width: 100%;
      align-items: flex-start;
      background: transparent;
      border: none;
      font-family: var(--fonts-sans);
      cursor: pointer;
      gap: 0.5rem;
      text-transform: none;
      margin-bottom: 0.25rem;
      padding: 0.5rem;
      font-size: 1rem;

      div {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        gap: 0.25rem;
        overflow: hidden;
        flex-grow: 1;
        text-align: left;
        font-size: 0.8333rem;

        label,
        span {
          width: 100%;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
      }

      &:hover,
      &:focus {
        background: #f0f0f0;

        label {
          font-family: var(--fonts-sansBold);
          font-weight: 400;
        }
      }

      &:last-of-type {
        margin-bottom: 0;
      }

      figure {
        width: 32px;
        height: 32px;
        flex-shrink: 0;

        img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          border-radius: 0.25rem;
        }
      }
    }
  `;

  return (
    <div ref={addRef} css={add}>
      <input
        ref={inputRef}
        className="input"
        type="text"
        placeholder="Attach filesets..."
        aria-haspopup="true"
        aria-controls="searchbox"
        onFocus={handleFocus}
        onBlur={handleBlur}
      />
      <div
        className="box"
        css={content}
        role="searchbox"
        aria-expanded={isOpen}
      >
        {candidateFileSets.map((candidate) => (
          <button
            key={candidate.id}
            value={candidate.id}
            type="button"
            onClick={() => {
              handleUpdateFileSet(candidate.id, fileSetId);
              setIsOpen(false);
            }}
          >
            <figure>
              <img
                src={`${iiifServerUrl}${candidate.id}/square/32,32/0/default.jpg`}
                placeholder="Fileset Image"
                data-testid="fileset-image"
              />
            </figure>
            <div>
              <label>{candidate.coreMetadata.label}</label>
              <span className="is-muted">{candidate.accessionNumber}</span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
};

export default WorkFilesetActionButtonsGroupAdd;
