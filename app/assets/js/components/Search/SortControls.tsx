import {
  IconSortAlphaDown,
  IconSortAlphaDownAlt,
  IconSortAmountDown,
  IconSortAmountDownAlt,
  IconSortNumericDown,
  IconSortNumericDownAlt,
} from "@js/components/Icon";
import {
  SEARCH_SORT_FIELDS,
  findSearchSortField,
  searchSortForField,
  toggleSearchSortDirection,
} from "@js/services/search-sort";

import React from "react";

export interface SearchSort {
  field: string;
  direction: "asc" | "desc";
}

interface SearchSortControlsProps {
  sort: SearchSort;
  onChange: (sort: SearchSort) => void;
}

// Font Awesome's "Alt" variants are the reversed glyphs: alpha Z→A, numeric
// 9→1, and amount narrow→wide. So "Alt" is descending for text and numbers but
// ascending for amounts.
const DIRECTION_ICONS: Record<
  string,
  { asc: React.ComponentType; desc: React.ComponentType }
> = {
  alpha: { asc: IconSortAlphaDown, desc: IconSortAlphaDownAlt },
  numeric: { asc: IconSortNumericDown, desc: IconSortNumericDownAlt },
  amount: { asc: IconSortAmountDownAlt, desc: IconSortAmountDown },
};

// Lowercase a direction label for use mid-sentence, leaving "A to Z" style
// labels alone.
const midSentence = (label: string) =>
  /^[A-Z] /.test(label) ? label : label.toLowerCase();

/**
 * Field select plus a direction toggle for the Search results. The toggle is
 * hidden for Relevancy, which has no meaningful reverse.
 */
const SearchSortControls: React.FC<SearchSortControlsProps> = ({
  sort,
  onChange,
}) => {
  const field = findSearchSortField(sort.field);
  const otherDirection = sort.direction === "asc" ? "desc" : "asc";
  const currentLabel = field.directionLabels[sort.direction];
  const otherLabel = midSentence(field.directionLabels[otherDirection]);
  const icons = DIRECTION_ICONS[field.iconStyle] || DIRECTION_ICONS.amount;
  const DirectionIcon = icons[sort.direction];

  return (
    <div
      className="is-flex is-align-items-center"
      data-testid="search-sort-controls"
    >
      <label
        className="is-size-7 has-text-grey mr-2"
        htmlFor="search-sort-field"
        style={{ whiteSpace: "nowrap" }}
      >
        Sort by
      </label>
      <div className="select is-small">
        <select
          data-testid="search-sort-field"
          id="search-sort-field"
          onChange={(e) => onChange(searchSortForField(e.target.value))}
          value={sort.field}
        >
          {SEARCH_SORT_FIELDS.map((option) => (
            <option key={option.key} value={option.key}>
              {option.label}
            </option>
          ))}
        </select>
      </div>
      {field.directional && (
        <button
          aria-label={`${currentLabel}. Switch to ${otherLabel}`}
          className="button is-small ml-2"
          data-direction={sort.direction}
          data-testid="search-sort-direction"
          onClick={() => onChange(toggleSearchSortDirection(sort))}
          title={`${currentLabel} (click for ${otherLabel})`}
          type="button"
        >
          <span className="icon is-small">
            <DirectionIcon />
          </span>
        </button>
      )}
    </div>
  );
};

export default SearchSortControls;
