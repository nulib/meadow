import React, { useState } from "react";
import { useQuery } from "@apollo/client";
import { GET_COLLECTIONS } from "@js/components/Collection/collection.gql";
import { GET_TRANSCRIBABLE_FILE_SETS } from "./transcription.gql";
import { iiifUrl, useDebounced } from "./hooks";
import type { PickedImage, TranscribableFileSet } from "./types";

export const PAGE_SIZE = 10;

const THUMBNAIL = "square/128,128/0/default.jpg";

export const labelOf = (fileSet: TranscribableFileSet) =>
  fileSet.label || fileSet.accessionNumber || fileSet.id;

const pick = (fileSet: TranscribableFileSet): PickedImage => ({
  id: fileSet.id,
  label: labelOf(fileSet),
  thumbnail: iiifUrl(fileSet.representativeImageUrl, THUMBNAIL),
});

interface Props {
  selected: PickedImage[];
  onChange: (next: PickedImage[]) => void;
}

/**
 * A paged grid of the file sets the transcriber can read (access files that are
 * images), to tick the ones to transcribe. What is ticked stays ticked across pages and
 * filters.
 */
export default function FileSetPicker({ selected, onChange }: Props) {
  const [collectionId, setCollectionId] = useState("");
  const [work, setWork] = useState("");
  const [page, setPage] = useState(0);
  const workFilter = useDebounced(work.trim());

  const { data: collectionData } = useQuery(GET_COLLECTIONS);
  const collections: { id: string; title: string }[] = [
    ...(collectionData?.collections ?? []),
  ].sort((a, b) => (a.title ?? "").localeCompare(b.title ?? ""));

  const { data, previousData, loading, error } = useQuery(
    GET_TRANSCRIBABLE_FILE_SETS,
    {
      variables: {
        limit: PAGE_SIZE,
        offset: page * PAGE_SIZE,
        collectionId: collectionId || null,
        work: workFilter || null,
      },
    },
  );

  // The page before stays up while the next one loads, so the grid does not jump.
  const shown = (data ?? previousData)?.transcribableFileSets;
  const fileSets: TranscribableFileSet[] = shown?.fileSets ?? [];
  const total: number = shown?.total ?? 0;
  const first = total ? page * PAGE_SIZE + 1 : 0;
  const last = Math.min(total, (page + 1) * PAGE_SIZE);
  const isSelected = (id: string) => selected.some((image) => image.id === id);

  const flip = (fileSet: TranscribableFileSet) =>
    onChange(
      isSelected(fileSet.id)
        ? selected.filter((image) => image.id !== fileSet.id)
        : [...selected, pick(fileSet)],
    );

  return (
    <div data-testid="bench-file-set-picker">
      <div className="field is-horizontal mb-4">
        <div className="field-body">
          <div className="field is-narrow">
            <label className="label is-small" htmlFor="bench-collection">
              Collection
            </label>
            <div className="control">
              <div className="select is-fullwidth">
                <select
                  id="bench-collection"
                  value={collectionId}
                  onChange={(event) => {
                    setCollectionId(event.target.value);
                    setPage(0);
                  }}
                >
                  <option value="">All collections</option>
                  {collections.map((collection) => (
                    <option key={collection.id} value={collection.id}>
                      {collection.title}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>
          <div className="field">
            <label className="label is-small" htmlFor="bench-work">
              Work
            </label>
            <div className="control">
              <input
                id="bench-work"
                className="input"
                type="search"
                placeholder="Work id, accession number or title"
                value={work}
                onChange={(event) => {
                  setWork(event.target.value);
                  setPage(0);
                }}
              />
            </div>
          </div>
        </div>
      </div>

      {error && (
        <p className="notification is-danger is-light">{error.message}</p>
      )}

      <ul className="bench-image-grid" aria-busy={loading}>
        {fileSets.map((fileSet) => {
          const checked = isSelected(fileSet.id);
          const thumbnail = iiifUrl(fileSet.representativeImageUrl, THUMBNAIL);
          return (
            <li key={fileSet.id}>
              <label
                className={`bench-image-card ${checked ? "is-selected" : ""}`}
              >
                <input
                  type="checkbox"
                  checked={checked}
                  onChange={() => flip(fileSet)}
                  aria-label={`Transcribe ${labelOf(fileSet)}`}
                />
                <span className="bench-image-card-thumbnail">
                  {thumbnail && <img src={thumbnail} alt="" loading="lazy" />}
                </span>
                <span className="bench-image-card-text">
                  <strong title={labelOf(fileSet)}>{labelOf(fileSet)}</strong>
                  <span title={fileSet.accessionNumber ?? ""}>
                    {fileSet.accessionNumber}
                  </span>
                  <span
                    className="has-text-grey"
                    title={fileSet.workTitle ?? ""}
                  >
                    {fileSet.workTitle ||
                      fileSet.workAccessionNumber ||
                      "No work"}
                  </span>
                </span>
              </label>
            </li>
          );
        })}
      </ul>

      {!loading && !error && fileSets.length === 0 && (
        <p className="notification is-light">
          No transcribable files match. The bench lists access files with an
          image MIME type.
        </p>
      )}

      <nav
        className="level is-mobile mt-3"
        aria-label="Pages of transcribable files"
      >
        <div className="level-left">
          <p className="level-item is-size-7 has-text-grey">
            {loading && !shown ? "Loading…" : `${first}–${last} of ${total}`}
          </p>
        </div>
        <div className="level-right">
          <div className="level-item buttons are-small">
            <button
              type="button"
              className="button"
              disabled={page === 0}
              onClick={() => setPage(page - 1)}
            >
              Previous
            </button>
            <button
              type="button"
              className="button"
              disabled={last >= total}
              onClick={() => setPage(page + 1)}
            >
              Next
            </button>
          </div>
        </div>
      </nav>

      <div className="bench-selected">
        <span className="has-text-weight-semibold is-size-7">
          Selected ({selected.length})
        </span>
        {selected.length === 0 && (
          <span className="is-size-7 has-text-grey">
            Tick the images to transcribe.
          </span>
        )}
        <span className="tags mb-0">
          {selected.map((image) => (
            <span key={image.id} className="tag is-primary is-light mb-0">
              {image.label}
              <button
                type="button"
                className="delete is-small"
                aria-label={`Remove ${image.label}`}
                onClick={() =>
                  onChange(selected.filter((each) => each.id !== image.id))
                }
              />
            </span>
          ))}
        </span>
        {selected.length > 0 && (
          <button
            type="button"
            className="button is-small is-text"
            onClick={() => onChange([])}
          >
            Clear
          </button>
        )}
      </div>
    </div>
  );
}
