export const DONUT_URL =
  process.env.REACT_APP_DONUT_URL || "http://devbox.library.northwestern.edu/";

export const ELASTICSEARCH_PROXY_BASE =
  process.env.REACT_APP_ELASTICSEARCH_PROXY_BASE || "http://localhost:3334";

export const SOLR_BASE =
  process.env.REACT_APP_SOLR_BASE || "/solr/development-core/select?";

export const IIIF_LOGIN_URL = process.env.REACT_APP_IIIF_LOGIN_URL;

export const IIIF_SMALL_ITEM_REGION =
  process.env.REACT_APP_IIIF_SMALL_ITEM_REGION ||
  "/pct:10,10,60,60/175,175/0/default.jpg";

export const IIIF_MEDIUM_ITEM_REGION =
  process.env.REACT_APP_IIIF_MEDIUM_ITEM_REGION ||
  "/square/500,500/0/default.jpg";

export const IIIF_PHOTO_FEATURE_REGION =
  process.env.REACT_APP_IIIF_PHOTO_FEATURE_REGION ||
  "/pct:10,10,60,60/480,350/0/default.jpg";

export const IIIF_FEATURE_BOX_REGION =
  process.env.REACT_APP_IIIF_FEATURE_BOX_REGION ||
  "/pct:10,10,60,38.4/345,/0/default.jpg";

export const IIIF_LARGE_FEATURE_REGION =
  process.env.REACT_APP_IIIF_LARGE_FEATURE_REGION || "/full/300,/0/default.jpg";

export const IIIF_LARGE_IMAGE_REGION =
  process.env.IIIF_LARGE_IMAGE_REGION || "/full/800,/0/default.jpg";

export const IMAGE_MODEL = "Image";
export const COLLECTION_MODEL = "Collection";

export const HONEYBADGER_API_KEY = process.env.REACT_APP_HONEYBADGER_API_KEY;
export const HONEYBADGER_ENV = process.env.REACT_APP_HONEYBADGER_ENV;

// This array holds Keyword Metadata values set in Donut, which are used to group Collections
// on the Homepage
export const HOMEPAGE_COLLECTION_GROUP_KEYWORDS = [
  "Posters",
  "Photography",
  "Evanston"
];

// Mobile breakpoint
export const MOBILE_BREAKPOINT = 768;

// Production ids (needed for hardcoding hero images on homepage and collections on the About page)
export const productionIds = {
  berkeley: "18ec4c6b-192a-4ab8-9903-ea0f393c35f7",
  bursarsOffice: "c2a8a3e0-af0f-4e04-8721-91698fc14574",
  fava: "c373ecd2-2c45-45f2-9f9e-52dc244870bd",
  hamidNaficy: "4ed2338d-c715-4a86-8ac6-6b4030a42be5",
  kateAndLou: "81061b51-1ed0-4495-bf37-30d46f35c63b",
  jimmyJohnson: "db98ed75-1810-46d3-a838-176c0685cd01",
  ramonCasas: "ba35820a-525a-4cfa-8f23-4891c9f798c4",
  vernonMcKay: "1d849df1-eb32-43f4-b7b9-e435cff18f7c",
  wpa: "c708f479-db91-4585-8267-874c5e7da73f",
  wwII: "faf4f60e-78e0-4fbf-96ce-4ca8b4df597a"
};

// <title> tag ending
export const titleTagEnd =
  "Digital Collections - Libraries - Northwestern University";

export const productionUrl =
  "https://digitalcollections.library.northwestern.edu";

// Google Tag Manager
export const GOOGLE_TAG_MANAGER_ID = "GTM-MJ7RNV3";

// React-router route config values
export const ROUTES = {
  ABOUT: {
    title: "About",
    path: "/about"
  },
  COLLECTION: {
    title: "",
    path: "/collections/:id"
  },
  COLLECTIONS_ALL: {
    title: "All Collections",
    path: "/collections"
  },
  CONTACT: {
    title: "Contact Us",
    path: "/contact-us"
  },
  HOME: {
    title: "Home",
    path: "/"
  },
  ITEM_DETAIL: {
    title: "",
    path: "/items/:id"
  },
  PAGE_NOT_FOUND: {
    title: "404 Page Not Found",
    path: "/notfound"
  },
  SEARCH: {
    title: "Search",
    path: "/search"
  }
};

// Admin Set contact emails
export const ADMIN_SET_CONTACTS = [
  {
    id: "b3771d7c-5117-4b48-a237-a0a6f02bc048",
    email: "special.collections@northwestern.edu",
    title: "Charles Deering McCormick Library of Special Collections"
  },
  {
    id: "ce79271f-aeeb-42a0-bb7b-d945223aadce",
    email: "govinfo@northwestern.edu",
    title: "Government & Geographic Information Collection"
  },
  {
    id: "fb560cc3-ea2b-41b0-bc0f-5e495c4f3f7f",
    email: "africana@northwestern.edu",
    title: "Herskovits Library of African Studies"
  },
  {
    id: "4d090cfa-f802-4ac3-9fe4-b5adc0294e80",
    email: "transportationlibrary@northwestern.edu",
    title: "Transportation Library"
  },
  {
    id: "810fb25f-bc4a-47f9-9de3-d57f6513699f",
    email: "archives@northwestern.edu",
    title: "University Archives"
  }
];
// Extras not currently in production yet:
/**
Art Library artlibrary@northwestern.edu
Charles Deering McCormick Library of Special Collections special.collections@northwestern.edu
Faculty Collections repository@northwestern.edu
Government & Geographic Information Collection govinfo@northwestern.edu
Herskovits Library of African Studies africana@northwestern.edu
Music Library musiclibrary@northwestern.edu
Transportation Library transportationlibrary@northwestern.edu
University (MAIN) Library library@northwestern.edu
University Archives archives@northwestern.edu
 */
