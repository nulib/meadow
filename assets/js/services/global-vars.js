export const COLLECTION_TYPES = [
  { label: "NUL Collection", id: "NUL Collection", value: "NUL Collection" },
  { label: "NUL Theme", id: "NUL Theme", value: "NUL Theme" },
];

export const SORT_OPTIONS = [
  {
    sortBy: "desc",
    dataField: "_score",
    label: "Sort By Relevancy",
  },
  {
    sortBy: "asc",
    dataField: "modifiedDate",
    label: "Sort By Modified Date",
  },
  {
    sortBy: "asc",
    dataField: "descriptiveMetadata.title.keyword",
    label: "Sort By Title",
  },
];

export const IIIF_SIZES = {
  IIIF_SQUARE: "/square/500,500/0/default.jpg",
  IIIF_FULL: "/full/full/0/default.jpg",
};

// Browser localStorage variable used to hold code lists
export const LOCAL_STORAGE_CODELIST_KEY = "meadowCodeLists";

export const VISIBILITY_OPTIONS = [
  { label: "Institution", value: "AUTHENTICATED" },
  { label: "Public", value: "OPEN" },
  { label: "Private", value: "RESTRICTED" },
];

export const URL_PATTERN_MATCH = /(((http|https):\/\/)|www\.)(\S+)\.([a-z]{2,}?)(.*?)( |,|$|\.)/gim;
