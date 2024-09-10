export const COLLECTION_TYPES = [
  { label: "NUL Collection", id: "NUL Collection", value: "NUL Collection" },
  { label: "NUL Theme", id: "NUL Theme", value: "NUL Theme" },
];

export const GOOGLE_TAG_MANAGER_ID = "GTM-5W2MPSH";

export const REACTIVESEARCH_SORT_OPTIONS = [
  {
    sortBy: "desc",
    dataField: "_score",
    label: "Sort By Relevancy",
  },
  {
    sortBy: "asc",
    dataField: "modified_date",
    label: "Sort By Modified Date",
  },
  {
    sortBy: "asc",
    dataField: "title.keyword",
    label: "Sort By Title",
  },
  {
    sortBy: "asc",
    dataField: "accession_number",
    label: "Sort By Accession Number",
  },
];

export const IIIF_SIZES = {
  IIIF_SQUARE: "/square/500,500/0/default.jpg",
  IIIF_FULL: "/full/max/0/default.jpg",
  IIIF_FULL_TIFF: "/full/max/0/default.tif",
};

// Browser localStorage variable used to hold code lists
export const LOCAL_STORAGE_CODELIST_KEY = "meadowCodeLists";

export const VISIBILITY_OPTIONS = [
  { label: "Institution", value: "AUTHENTICATED" },
  { label: "Public", value: "OPEN" },
  { label: "Private", value: "RESTRICTED" },
];

export const URL_PATTERN_MATCH =
  /(((http|https):\/\/)|www\.)(\S+)\.([a-z]{2,}?)(.*?)( |,|$|\.)/gim;

export const URL_PATTERN_START = ["http", "https", "www"];
