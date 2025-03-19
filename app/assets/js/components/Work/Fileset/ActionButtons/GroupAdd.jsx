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
  const [isOpen, setIsOpen] = React.useState(false);

  const add = css`
    position: relative;
    z-index: ${isOpen ? 3 : 1};

    input::placeholder {
      color: var(--colors-richBlack50) !important;
    }
  `;

  const content = css`
    position: absolute;
    z-index: 2;
    display: ${isOpen ? "block" : "none"};
    background: white;
    width: 100%;
    max-height: 200px;
    overflow-y: scroll;
    padding: 0.25rem;

    button {
      display: flex;
      align-items: center;
      background: transparent;
      border: none;
      font-family: var(--fonts-sans);
      cursor: pointer;
      gap: 0.5rem;
      text-transform: none;
      margin-bottom: 0.25rem;
      padding: 0.25rem;
      font-size: 1rem;
      width: 100%;

      &:hover,
      &:focus {
        background: #f0f0f0;
        font-family: var(--fonts-sansBold);
        font-weight: 400;
      }

      &:last-of-type {
        margin-bottom: 0;
      }

      figure {
        width: 24px;
        height: 24px;

        img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          border-radius: 0.25rem;
        }
      }
    }
  `;

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

  return (
    <div css={add} ref={addRef}>
      <input
        className="input"
        type="text"
        placeholder="Attach fileset..."
        aria-haspopup="true"
        aria-controls="searchbox"
        onFocus={() => setIsOpen(!isOpen)}
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
                src={`${iiifServerUrl}${candidate.id}/square/24,24/0/default.jpg`}
                placeholder="Fileset Image"
                data-testid="fileset-image"
              />
            </figure>
            {candidate.coreMetadata.label}
          </button>
        ))}
      </div>
    </div>
  );
};

export default WorkFilesetActionButtonsGroupAdd;
