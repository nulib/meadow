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
  const [filteredCandidateFileSets, setFilteredCandidateFileSets] =
    React.useState(candidateFileSets);

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

  useEffect(() => {
    setFilteredCandidateFileSets(candidateFileSets);
  }, [candidateFileSets]);

  const handleFocus = () => {
    setIsOpen(!isOpen);
    inputRef.current.style.width = "300px";
  };

  const handleBlur = () => {
    inputRef.current.style.width = "150px";
  };

  const handleChange = (e) => {
    const value = e.target.value.toLowerCase().normalize();
    if (value === "") {
      setFilteredCandidateFileSets(candidateFileSets);
      return;
    }

    // get the filtered filesets matching label or accession number
    const filtered = candidateFileSets.filter(
      (candidate) =>
        candidate.coreMetadata.label
          .toLowerCase()
          .normalize()
          .includes(value) ||
        candidate.accessionNumber.toLowerCase().normalize().includes(value),
    );

    setFilteredCandidateFileSets(filtered);
  };

  const handleOnClick = (candidateId) => {
    handleUpdateFileSet(candidateId, fileSetId);
    setIsOpen(false);
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
    display: ${isOpen ? "block" : "none"};
    background: white;
    width: 300px;
    max-height: 300px;
    transition: all 0.25s ease;
    overflow-x: hidden;
    overflow-y: scroll;};
    padding: 0.5rem;

    button.candidate-option {
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
    <div ref={addRef} css={add} data-testid="fileset-group-add">
      <input
        ref={inputRef}
        className="input"
        type="text"
        placeholder="Attach filesets..."
        aria-haspopup="true"
        aria-controls="searchbox"
        onFocus={handleFocus}
        onBlur={handleBlur}
        onChange={handleChange}
      />
      <div
        className="box"
        css={content}
        role="searchbox"
        aria-expanded={isOpen}
      >
        {filteredCandidateFileSets.length ? (
          filteredCandidateFileSets.map((candidate) => (
            <button
              key={candidate.id}
              value={candidate.id}
              className="candidate-option"
              data-testid="fileset-group-add-candidate"
              type="button"
              onClick={() => handleOnClick(candidate.id, fileSetId)}
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
          ))
        ) : (
          <p>Applicable fileset(s) not found.</p>
        )}
      </div>
    </div>
  );
};

export default WorkFilesetActionButtonsGroupAdd;
