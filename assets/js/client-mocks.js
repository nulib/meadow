export const codeListMock = (scheme) => {
  switch (scheme) {
    case "AUTHORITY":
      return authorityMock;
      break;
    case "RIGHTS_STATEMENT":
      return rightsStatementMock;
      break;
    case "PRESERVATION_LEVEL":
      return preservationLevelMock;
      break;
    case "LICENSE":
      return licenseMock;
      break;
    case "MARC_RELATOR":
      return marcRelatorMock;
      break;
    case "PRESERVATION_LEVEL":
      return preservationLevelMock;
      break;
    case "STATUS":
      return statusMock;
      break;
    case "SUBJECT_ROLE":
      return subjectRoleMock;
      break;
    case "WORK_TYPE":
      return workTypeMock;
      break;
    case "VISIBILITY":
      return visibilityMock;
      break;
    default:
      return [];
  }
};

export const rightsStatementMock = [
  {
    id: "http://rightsstatements.org/vocab/InC/1.0/",
    label: "In Copyright",
    __typename: "CodedTerm",
  },
  {
    id: "http://rightsstatements.org/vocab/InC-OW-EU/1.0/",
    label: "In Copyright - EU Orphan Work",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/InC-EDU/1.0/",
    label: "In Copyright - Educational Use Permitted",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/InC-NC/1.0/",
    label: "In Copyright - Non-Commercial Use Permitted",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/InC-RUU/1.0/",
    label: "In Copyright - Rights-holder(s) Unlocatable or Unidentifiable",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/NoC-CR/1.0/",
    label: "No Copyright - Contractual Restrictions",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/NoC-NC/1.0/",
    label: "No Copyright - Non-Commercial Use Only ",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/NoC-OKLR/1.0/",
    label: "No Copyright - Other Known Legal Restrictions",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/NoC-US/1.0/",
    label: "No Copyright - United States",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/CNE/1.0/",
    label: "Copyright Not Evaluated",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/UND/1.0/",
    label: "Copyright Undelabelined",
    __typename: "CodedTerm",
  },
  {
    id: " http://rightsstatements.org/vocab/NKC/1.0/  ",
    label: "No Known Copyright",
    __typename: "CodedTerm",
  },
];

export const preservationLevelMock = [
  { label: "Level 1", id: "1", __typename: "CodedTerm" },
  { label: "Level 2", id: "2", __typename: "CodedTerm" },
  { label: "Level 3", id: "3", __typename: "CodedTerm" },
];

export const visibilityMock = [
  {
    label: "Institution",
    id: "AUTHENTICATED",
    __typename: "CodedTerm",
  },
  { label: "Public", id: "OPEN", __typename: "CodedTerm" },
  { label: "Private", id: "RESTRICTED", __typename: "CodedTerm" },
];

export const licenseMock = [
  {
    id: "http://creativecommons.org/licenses/by/3.0/us/",
    label: "Attribution 3.0 United States",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/licenses/by-sa/3.0/us/",
    label: "Attribution-ShareAlike 3.0 United States",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/licenses/by-nc/3.0/us/",
    label: "Attribution-NonCommercial 3.0 United States",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/licenses/by-nd/3.0/us/",
    label: "Attribution-NoDerivs 3.0 United States",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/licenses/by-nc-nd/3.0/us/",
    label: "Attribution-NonCommercial-NoDerivs 3.0 United States",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/licenses/by-nc-sa/3.0/us/",
    label: " Attribution-NonCommercial-ShareAlike 3.0 United States",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/publicdomain/mark/1.0/",
    label: "Public Domain Mark 1.0",
    __typename: "CodedTerm",
  },
  {
    id: "http://creativecommons.org/publicdomain/zero/1.0/",
    label: "CC0 1.0 Universal",
    __typename: "CodedTerm",
  },
  {
    id: "http://www.europeana.eu/portal/rights/rr-r.html",
    label: "All rights reserved",
    __typename: "CodedTerm",
  },
  {
    id: "https://creativecommons.org/licenses/by/4.0/",
    label: "Attribution 4.0 International",
    __typename: "CodedTerm",
  },
  {
    id: "https://creativecommons.org/licenses/by-sa/4.0/",
    label: "Attribution-ShareAlike 4.0 International",
    __typename: "CodedTerm",
  },
  {
    id: "https://creativecommons.org/licenses/by-nc/4.0/",
    label: "Attribution-NonCommercial 4.0 International",
    __typename: "CodedTerm",
  },
  {
    id: "https://creativecommons.org/licenses/by-nd/4.0/",
    label: "Attribution-NoDerivatives 4.0 International",
    __typename: "CodedTerm",
  },
  {
    id: "https://creativecommons.org/licenses/by-nc-nd/4.0/",
    label: "Attribution-NonCommercial-NoDerivatives 4.0 International",
    __typename: "CodedTerm",
  },
  {
    id: "https://creativecommons.org/licenses/by-nc-sa/4.0/",
    label: "Attribution-NonCommercial-ShareAlike 4.0 International",
    __typename: "CodedTerm",
  },
];

export const workTypeMock = [
  {
    id: "IMAGE",
    label: "Image",
    __typename: "CodedTerm",
  },
  {
    id: "VIDEO",
    label: "Video",
    __typename: "CodedTerm",
  },
  {
    id: "DOCUMENT",
    label: "Document",
    __typename: "CodedTerm",
  },
  {
    id: "AUDIO",
    label: "Audio",
    __typename: "CodedTerm",
  },
];

export const statusMock = [
  {
    id: "STARTED",
    label: "Started",
    __typename: "CodedTerm",
  },
  {
    id: "IN PROGRESS",
    label: "In Progresss",
    __typename: "CodedTerm",
  },
  {
    id: "DONE",
    label: "Done",
    __typename: "CodedTerm",
  },
];

export const subjectRoleMock = [
  {
    id: "GEOGRAPHICAL",
    label: "Geographical",
    __typename: "CodedTerm",
  },
  {
    id: "TOPICAL",
    label: "Topical",
    __typename: "CodedTerm",
  },
];

export const authorityMock = [
  {
    id: "AAT",
    label: "Getty Art & Architecture Thesaurus© (AAT)",
    __typename: "CodedTerm",
  },
  {
    id: "FAST",
    label: "OCLC FAST (Faceted Application of Subject Terminology)",
    __typename: "CodedTerm",
  },
  {
    id: "GEONAMES",
    label: "Geonames",
    __typename: "CodedTerm",
  },
  {
    id: "LCNAF",
    label: "Library of Congress Name Authority File (LCNAF) ",
    __typename: "CodedTerm",
  },
  {
    id: "LCSH",
    label: "Library of Congress Subject Headings (LCSH)",
    __typename: "CodedTerm",
  },
  {
    id: "ULAN",
    label: "Getty Union List of Artist Names® (ULAN)",
    __typename: "CodedTerm",
  },
  {
    id: "VIAF",
    label: "Virtual International Authority File",
    __typename: "CodedTerm",
  },
];

export const marcRelatorMock = [
         {
           id: "abr",
           label: "Abridger",
           __typename: "CodedTerm",
         },
         {
           id: "acp",
           label: "Art copyist",
           __typename: "CodedTerm",
         },
         {
           id: "act",
           label: "Actor",
           __typename: "CodedTerm",
         },
         {
           id: "adi",
           label: "Art director",
           __typename: "CodedTerm",
         },
         {
           id: "adp",
           label: "Adapter",
           __typename: "CodedTerm",
         },
         {
           id: "aft",
           label: "Author of afterword, colophon, etc.",
           __typename: "CodedTerm",
         },
         {
           id: "anl",
           label: "Analyst",
           __typename: "CodedTerm",
         },

         {
           id: "anm",
           label: "Animator",
           __typename: "CodedTerm",
         },

         {
           id: "ann",
           label: "Annotator",
           __typename: "CodedTerm",
         },

         {
           id: "ant",
           label: "Bibliographic antecedent",
           __typename: "CodedTerm",
         },

         {
           id: "ape",
           label: "Appellee",
           __typename: "CodedTerm",
         },

         {
           id: "apl",
           label: "Appellant",
           __typename: "CodedTerm",
         },

         {
           id: "app",
           label: "Applicant",
           __typename: "CodedTerm",
         },

         {
           id: "aqt",
           label: "Author in quotations or text abstracts",
           __typename: "CodedTerm",
         },

         {
           id: "arc",
           label: "Architect",
           __typename: "CodedTerm",
         },

         {
           id: "ard",
           label: "Artistic director",
           __typename: "CodedTerm",
         },

         {
           id: "arr",
           label: "Arranger",
           __typename: "CodedTerm",
         },

         {
           id: "art",
           label: "Artist",
           __typename: "CodedTerm",
         },

         {
           id: "asg",
           label: "Assignee",
           __typename: "CodedTerm",
         },

         {
           id: "asn",
           label: "Associated name",
           __typename: "CodedTerm",
         },

         {
           id: "ato",
           label: "Autographer",
           __typename: "CodedTerm",
         },

         {
           id: "att",
           label: "Attributed name",
           __typename: "CodedTerm",
         },

         {
           id: "auc",
           label: "Auctioneer",
           __typename: "CodedTerm",
         },

         {
           id: "aud",
           label: "Author of dialog",
           __typename: "CodedTerm",
         },

         {
           id: "aui",
           label: "Author of introduction, etc.",
           __typename: "CodedTerm",
         },

         {
           id: "aus",
           label: "Screenwriter",
           __typename: "CodedTerm",
         },

         {
           id: "aut",
           label: "Author",
           __typename: "CodedTerm",
         },

         {
           id: "bdd",
           label: "Binding designer",
           __typename: "CodedTerm",
         },

         {
           id: "bjd",
           label: "Bookjacket designer",
           __typename: "CodedTerm",
         },

         {
           id: "bkd",
           label: "Book designer",
           __typename: "CodedTerm",
         },

         {
           id: "bkp",
           label: "Book producer",
           __typename: "CodedTerm",
         },

         {
           id: "blw",
           label: "Blurb writer",
           __typename: "CodedTerm",
         },

         {
           id: "bnd",
           label: "Binder",
           __typename: "CodedTerm",
         },

         {
           id: "bpd",
           label: "Bookplate designer",
           __typename: "CodedTerm",
         },

         {
           id: "brd",
           label: "Broadcaster",
           __typename: "CodedTerm",
         },

         {
           id: "brl",
           label: "Braille embosser",
           __typename: "CodedTerm",
         },

         {
           id: "bsl",
           label: "Bookseller",
           __typename: "CodedTerm",
         },

         {
           id: "cas",
           label: "Caster",
           __typename: "CodedTerm",
         },

         {
           id: "ccp",
           label: "Conceptor",
           __typename: "CodedTerm",
         },

         {
           id: "chr",
           label: "Choreographer",
           __typename: "CodedTerm",
         },

         {
           id: "-cl",
           label: "	Collaborator",
           __typename: "CodedTerm",
         },

         {
           id: "cli",
           label: "Client",
           __typename: "CodedTerm",
         },

         {
           id: "cll",
           label: "Calligrapher",
           __typename: "CodedTerm",
         },

         {
           id: "clr",
           label: "Colorist",
           __typename: "CodedTerm",
         },

         {
           id: "clt",
           label: "Collotyper",
           __typename: "CodedTerm",
         },

         {
           id: "cmm",
           label: "Commentator",
           __typename: "CodedTerm",
         },

         {
           id: "cmp",
           label: "Composer",
           __typename: "CodedTerm",
         },

         {
           id: "cmt",
           label: "Compositor",
           __typename: "CodedTerm",
         },

         {
           id: "cnd",
           label: "Conductor",
           __typename: "CodedTerm",
         },

         {
           id: "cng",
           label: "Cinematographer",
           __typename: "CodedTerm",
         },

         {
           id: "cns",
           label: "Censor",
           __typename: "CodedTerm",
         },

         {
           id: "coe",
           label: "Contestant-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "col",
           label: "Collector",
           __typename: "CodedTerm",
         },

         {
           id: "com",
           label: "Compiler",
           __typename: "CodedTerm",
         },

         {
           id: "con",
           label: "Conservator",
           __typename: "CodedTerm",
         },

         {
           id: "cor",
           label: "Collection registrar",
           __typename: "CodedTerm",
         },

         {
           id: "cos",
           label: "Contestant",
           __typename: "CodedTerm",
         },

         {
           id: "cot",
           label: "Contestant-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "cou",
           label: "Court governed",
           __typename: "CodedTerm",
         },

         {
           id: "cov",
           label: "Cover designer",
           __typename: "CodedTerm",
         },

         {
           id: "cpc",
           label: "Copyright claimant",
           __typename: "CodedTerm",
         },

         {
           id: "cpe",
           label: "Complainant-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "cph",
           label: "Copyright holder",
           __typename: "CodedTerm",
         },

         {
           id: "cpl",
           label: "Complainant",
           __typename: "CodedTerm",
         },

         {
           id: "cpt",
           label: "Complainant-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "cre",
           label: "Creator",
           __typename: "CodedTerm",
         },

         {
           id: "crp",
           label: "Correspondent",
           __typename: "CodedTerm",
         },

         {
           id: "crr",
           label: "Corrector",
           __typename: "CodedTerm",
         },

         {
           id: "crt",
           label: "Court reporter",
           __typename: "CodedTerm",
         },

         {
           id: "csl",
           label: "Consultant",
           __typename: "CodedTerm",
         },

         {
           id: "csp",
           label: "Consultant to a project",
           __typename: "CodedTerm",
         },

         {
           id: "cst",
           label: "Costume designer",
           __typename: "CodedTerm",
         },

         {
           id: "ctb",
           label: "Contributor",
           __typename: "CodedTerm",
         },

         {
           id: "cte",
           label: "Contestee-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "ctg",
           label: "Cartographer",
           __typename: "CodedTerm",
         },

         {
           id: "ctr",
           label: "Contractor",
           __typename: "CodedTerm",
         },

         {
           id: "cts",
           label: "Contestee",
           __typename: "CodedTerm",
         },

         {
           id: "ctt",
           label: "Contestee-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "cur",
           label: "Curator",
           __typename: "CodedTerm",
         },

         {
           id: "cwt",
           label: "Commentator for written text",
           __typename: "CodedTerm",
         },

         {
           id: "dbp",
           label: "Distribution place",
           __typename: "CodedTerm",
         },

         {
           id: "dfd",
           label: "Defendant",
           __typename: "CodedTerm",
         },

         {
           id: "dfe",
           label: "Defendant-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "dft",
           label: "Defendant-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "dgg",
           label: "Degree granting institution",
           __typename: "CodedTerm",
         },

         {
           id: "dgs",
           label: "Degree supervisor",
           __typename: "CodedTerm",
         },

         {
           id: "dis",
           label: "Dissertant",
           __typename: "CodedTerm",
         },

         {
           id: "dln",
           label: "Delineator",
           __typename: "CodedTerm",
         },

         {
           id: "dnc",
           label: "Dancer",
           __typename: "CodedTerm",
         },

         {
           id: "dnr",
           label: "Donor",
           __typename: "CodedTerm",
         },

         {
           id: "dpc",
           label: "Depicted",
           __typename: "CodedTerm",
         },

         {
           id: "dpt",
           label: "Depositor",
           __typename: "CodedTerm",
         },

         {
           id: "drm",
           label: "Draftsman",
           __typename: "CodedTerm",
         },

         {
           id: "drt",
           label: "Director",
           __typename: "CodedTerm",
         },

         {
           id: "dsr",
           label: "Designer",
           __typename: "CodedTerm",
         },

         {
           id: "dst",
           label: "Distributor",
           __typename: "CodedTerm",
         },

         {
           id: "dtc",
           label: "Data contributor",
           __typename: "CodedTerm",
         },

         {
           id: "dte",
           label: "Dedicatee",
           __typename: "CodedTerm",
         },

         {
           id: "dtm",
           label: "Data manager",
           __typename: "CodedTerm",
         },

         {
           id: "dto",
           label: "Dedicator",
           __typename: "CodedTerm",
         },

         {
           id: "dub",
           label: "Dubious author",
           __typename: "CodedTerm",
         },

         {
           id: "edc",
           label: "Editor of compilation",
           __typename: "CodedTerm",
         },

         {
           id: "edm",
           label: "Editor of moving image work",
           __typename: "CodedTerm",
         },

         {
           id: "edt",
           label: "Editor",
           __typename: "CodedTerm",
         },

         {
           id: "egr",
           label: "Engraver",
           __typename: "CodedTerm",
         },

         {
           id: "elg",
           label: "Electrician",
           __typename: "CodedTerm",
         },

         {
           id: "elt",
           label: "Electrotyper",
           __typename: "CodedTerm",
         },

         {
           id: "eng",
           label: "Engineer",
           __typename: "CodedTerm",
         },

         {
           id: "enj",
           label: "Enacting jurisdiction",
           __typename: "CodedTerm",
         },

         {
           id: "etr",
           label: "Etcher",
           __typename: "CodedTerm",
         },

         {
           id: "evp",
           label: "Event place",
           __typename: "CodedTerm",
         },

         {
           id: "exp",
           label: "Expert",
           __typename: "CodedTerm",
         },

         {
           id: "fac",
           label: "Facsimilist",
           __typename: "CodedTerm",
         },

         {
           id: "fds",
           label: "Film distributor",
           __typename: "CodedTerm",
         },

         {
           id: "fld",
           label: "Field director",
           __typename: "CodedTerm",
         },

         {
           id: "flm",
           label: "Film editor",
           __typename: "CodedTerm",
         },

         {
           id: "fmd",
           label: "Film director",
           __typename: "CodedTerm",
         },

         {
           id: "fmk",
           label: "Filmmaker",
           __typename: "CodedTerm",
         },

         {
           id: "fmo",
           label: "Former owner",
           __typename: "CodedTerm",
         },

         {
           id: "fmp",
           label: "Film producer",
           __typename: "CodedTerm",
         },

         {
           id: "fnd",
           label: "Funder",
           __typename: "CodedTerm",
         },

         {
           id: "fpy",
           label: "First party",
           __typename: "CodedTerm",
         },

         {
           id: "frg",
           label: "Forger",
           __typename: "CodedTerm",
         },

         {
           id: "gis",
           label: "Geographic information specialist",
           __typename: "CodedTerm",
         },

         {
           id: "-gr",
           label: "	Graphic technician",
           __typename: "CodedTerm",
         },

         {
           id: "his",
           label: "Host institution",
           __typename: "CodedTerm",
         },

         {
           id: "hnr",
           label: "Honoree",
           __typename: "CodedTerm",
         },

         {
           id: "hst",
           label: "Host",
           __typename: "CodedTerm",
         },

         {
           id: "ill",
           label: "Illustrator",
           __typename: "CodedTerm",
         },

         {
           id: "ilu",
           label: "Illuminator",
           __typename: "CodedTerm",
         },

         {
           id: "ins",
           label: "Inscriber",
           __typename: "CodedTerm",
         },

         {
           id: "inv",
           label: "Inventor",
           __typename: "CodedTerm",
         },

         {
           id: "isb",
           label: "Issuing body",
           __typename: "CodedTerm",
         },

         {
           id: "itr",
           label: "Instrumentalist",
           __typename: "CodedTerm",
         },

         {
           id: "ive",
           label: "Interviewee",
           __typename: "CodedTerm",
         },

         {
           id: "ivr",
           label: "Interviewer",
           __typename: "CodedTerm",
         },

         {
           id: "jud",
           label: "Judge",
           __typename: "CodedTerm",
         },

         {
           id: "jug",
           label: "Jurisdiction governed",
           __typename: "CodedTerm",
         },

         {
           id: "lbr",
           label: "Laboratory",
           __typename: "CodedTerm",
         },

         {
           id: "lbt",
           label: "Librettist",
           __typename: "CodedTerm",
         },

         {
           id: "ldr",
           label: "Laboratory director",
           __typename: "CodedTerm",
         },

         {
           id: "led",
           label: "Lead",
           __typename: "CodedTerm",
         },

         {
           id: "lee",
           label: "Libelee-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "lel",
           label: "Libelee",
           __typename: "CodedTerm",
         },

         {
           id: "len",
           label: "Lender",
           __typename: "CodedTerm",
         },

         {
           id: "let",
           label: "Libelee-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "lgd",
           label: "Lighting designer",
           __typename: "CodedTerm",
         },

         {
           id: "lie",
           label: "Libelant-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "lil",
           label: "Libelant",
           __typename: "CodedTerm",
         },

         {
           id: "lit",
           label: "Libelant-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "lsa",
           label: "Landscape architect",
           __typename: "CodedTerm",
         },

         {
           id: "lse",
           label: "Licensee",
           __typename: "CodedTerm",
         },

         {
           id: "lso",
           label: "Licensor",
           __typename: "CodedTerm",
         },

         {
           id: "ltg",
           label: "Lithographer",
           __typename: "CodedTerm",
         },

         {
           id: "lyr",
           label: "Lyricist",
           __typename: "CodedTerm",
         },

         {
           id: "mcp",
           label: "Music copyist",
           __typename: "CodedTerm",
         },

         {
           id: "mdc",
           label: "Metadata contact",
           __typename: "CodedTerm",
         },

         {
           id: "med",
           label: "Medium",
           __typename: "CodedTerm",
         },

         {
           id: "mfp",
           label: "Manufacture place",
           __typename: "CodedTerm",
         },

         {
           id: "mfr",
           label: "Manufacturer",
           __typename: "CodedTerm",
         },

         {
           id: "mod",
           label: "Moderator",
           __typename: "CodedTerm",
         },

         {
           id: "mon",
           label: "Monitor",
           __typename: "CodedTerm",
         },

         {
           id: "mrb",
           label: "Marbler",
           __typename: "CodedTerm",
         },

         {
           id: "mrk",
           label: "Markup editor",
           __typename: "CodedTerm",
         },

         {
           id: "msd",
           label: "Musical director",
           __typename: "CodedTerm",
         },

         {
           id: "mte",
           label: "Metal-engraver",
           __typename: "CodedTerm",
         },

         {
           id: "mtk",
           label: "Minute taker",
           __typename: "CodedTerm",
         },

         {
           id: "mus",
           label: "Musician",
           __typename: "CodedTerm",
         },

         {
           id: "nrt",
           label: "Narrator",
           __typename: "CodedTerm",
         },

         {
           id: "opn",
           label: "Opponent",
           __typename: "CodedTerm",
         },

         {
           id: "org",
           label: "Originator",
           __typename: "CodedTerm",
         },

         {
           id: "orm",
           label: "Organizer",
           __typename: "CodedTerm",
         },

         {
           id: "osp",
           label: "Onscreen presenter",
           __typename: "CodedTerm",
         },

         {
           id: "oth",
           label: "Other",
           __typename: "CodedTerm",
         },

         {
           id: "own",
           label: "Owner",
           __typename: "CodedTerm",
         },

         {
           id: "pan",
           label: "Panelist",
           __typename: "CodedTerm",
         },

         {
           id: "pat",
           label: "Patron",
           __typename: "CodedTerm",
         },

         {
           id: "pbd",
           label: "Publishing director",
           __typename: "CodedTerm",
         },

         {
           id: "pbl",
           label: "Publisher",
           __typename: "CodedTerm",
         },

         {
           id: "pdr",
           label: "Project director",
           __typename: "CodedTerm",
         },

         {
           id: "pfr",
           label: "Proofreader",
           __typename: "CodedTerm",
         },

         {
           id: "pht",
           label: "Photographer",
           __typename: "CodedTerm",
         },

         {
           id: "plt",
           label: "Platemaker",
           __typename: "CodedTerm",
         },

         {
           id: "pma",
           label: "Permitting agency",
           __typename: "CodedTerm",
         },

         {
           id: "pmn",
           label: "Production manager",
           __typename: "CodedTerm",
         },

         {
           id: "pop",
           label: "Printer of plates",
           __typename: "CodedTerm",
         },

         {
           id: "ppm",
           label: "Papermaker",
           __typename: "CodedTerm",
         },

         {
           id: "ppt",
           label: "Puppeteer",
           __typename: "CodedTerm",
         },

         {
           id: "pra",
           label: "Praeses",
           __typename: "CodedTerm",
         },

         {
           id: "prc",
           label: "Process contact",
           __typename: "CodedTerm",
         },

         {
           id: "prd",
           label: "Production personnel",
           __typename: "CodedTerm",
         },

         {
           id: "pre",
           label: "Presenter",
           __typename: "CodedTerm",
         },

         {
           id: "prf",
           label: "Performer",
           __typename: "CodedTerm",
         },

         {
           id: "prg",
           label: "Programmer",
           __typename: "CodedTerm",
         },

         {
           id: "prm",
           label: "Printmaker",
           __typename: "CodedTerm",
         },

         {
           id: "prn",
           label: "Production company",
           __typename: "CodedTerm",
         },

         {
           id: "pro",
           label: "Producer",
           __typename: "CodedTerm",
         },

         {
           id: "prp",
           label: "Production place",
           __typename: "CodedTerm",
         },

         {
           id: "prs",
           label: "Production designer",
           __typename: "CodedTerm",
         },

         {
           id: "prt",
           label: "Printer",
           __typename: "CodedTerm",
         },

         {
           id: "prv",
           label: "Provider",
           __typename: "CodedTerm",
         },

         {
           id: "pta",
           label: "Patent applicant",
           __typename: "CodedTerm",
         },

         {
           id: "pte",
           label: "Plaintiff-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "ptf",
           label: "Plaintiff",
           __typename: "CodedTerm",
         },

         {
           id: "pth",
           label: "Patent holder",
           __typename: "CodedTerm",
         },

         {
           id: "ptt",
           label: "Plaintiff-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "pup",
           label: "Publication place",
           __typename: "CodedTerm",
         },

         {
           id: "rbr",
           label: "Rubricator",
           __typename: "CodedTerm",
         },

         {
           id: "rcd",
           label: "Recordist",
           __typename: "CodedTerm",
         },

         {
           id: "rce",
           label: "Recording engineer",
           __typename: "CodedTerm",
         },

         {
           id: "rcp",
           label: "Addressee",
           __typename: "CodedTerm",
         },

         {
           id: "rdd",
           label: "Radio director",
           __typename: "CodedTerm",
         },

         {
           id: "red",
           label: "Redaktor",
           __typename: "CodedTerm",
         },

         {
           id: "ren",
           label: "Renderer",
           __typename: "CodedTerm",
         },

         {
           id: "res",
           label: "Researcher",
           __typename: "CodedTerm",
         },

         {
           id: "rev",
           label: "Reviewer",
           __typename: "CodedTerm",
         },

         {
           id: "rpc",
           label: "Radio producer",
           __typename: "CodedTerm",
         },

         {
           id: "rps",
           label: "Repository",
           __typename: "CodedTerm",
         },

         {
           id: "rpt",
           label: "Reporter",
           __typename: "CodedTerm",
         },

         {
           id: "rpy",
           label: "Responsible party",
           __typename: "CodedTerm",
         },

         {
           id: "rse",
           label: "Respondent-appellee",
           __typename: "CodedTerm",
         },

         {
           id: "rsg",
           label: "Restager",
           __typename: "CodedTerm",
         },

         {
           id: "rsp",
           label: "Respondent",
           __typename: "CodedTerm",
         },

         {
           id: "rsr",
           label: "Restorationist",
           __typename: "CodedTerm",
         },

         {
           id: "rst",
           label: "Respondent-appellant",
           __typename: "CodedTerm",
         },

         {
           id: "rth",
           label: "Research team head",
           __typename: "CodedTerm",
         },

         {
           id: "rtm",
           label: "Research team member",
           __typename: "CodedTerm",
         },

         {
           id: "sad",
           label: "Scientific advisor",
           __typename: "CodedTerm",
         },

         {
           id: "sce",
           label: "Scenarist",
           __typename: "CodedTerm",
         },

         {
           id: "scl",
           label: "Sculptor",
           __typename: "CodedTerm",
         },

         {
           id: "scr",
           label: "Scribe",
           __typename: "CodedTerm",
         },

         {
           id: "sds",
           label: "Sound designer",
           __typename: "CodedTerm",
         },

         {
           id: "sec",
           label: "Secretary",
           __typename: "CodedTerm",
         },

         {
           id: "sgd",
           label: "Stage director",
           __typename: "CodedTerm",
         },

         {
           id: "sgn",
           label: "Signer",
           __typename: "CodedTerm",
         },

         {
           id: "sht",
           label: "Supporting host",
           __typename: "CodedTerm",
         },

         {
           id: "sll",
           label: "Seller",
           __typename: "CodedTerm",
         },

         {
           id: "sng",
           label: "Singer",
           __typename: "CodedTerm",
         },

         {
           id: "spk",
           label: "Speaker",
           __typename: "CodedTerm",
         },

         {
           id: "spn",
           label: "Sponsor",
           __typename: "CodedTerm",
         },

         {
           id: "spy",
           label: "Second party",
           __typename: "CodedTerm",
         },

         {
           id: "srv",
           label: "Surveyor",
           __typename: "CodedTerm",
         },

         {
           id: "std",
           label: "Set designer",
           __typename: "CodedTerm",
         },

         {
           id: "stg",
           label: "Setting",
           __typename: "CodedTerm",
         },

         {
           id: "stl",
           label: "Storyteller",
           __typename: "CodedTerm",
         },

         {
           id: "stm",
           label: "Stage manager",
           __typename: "CodedTerm",
         },

         {
           id: "stn",
           label: "Standards body",
           __typename: "CodedTerm",
         },

         {
           id: "str",
           label: "Stereotyper",
           __typename: "CodedTerm",
         },

         {
           id: "tcd",
           label: "Technical director",
           __typename: "CodedTerm",
         },

         {
           id: "tch",
           label: "Teacher",
           __typename: "CodedTerm",
         },

         {
           id: "ths",
           label: "Thesis advisor",
           __typename: "CodedTerm",
         },

         {
           id: "tld",
           label: "Television director",
           __typename: "CodedTerm",
         },

         {
           id: "tlp",
           label: "Television producer",
           __typename: "CodedTerm",
         },

         {
           id: "trc",
           label: "Transcriber",
           __typename: "CodedTerm",
         },

         {
           id: "trl",
           label: "Translator",
           __typename: "CodedTerm",
         },

         {
           id: "tyd",
           label: "Type designer",
           __typename: "CodedTerm",
         },

         {
           id: "tyg",
           label: "Typographer",
           __typename: "CodedTerm",
         },

         {
           id: "uvp",
           label: "University place",
           __typename: "CodedTerm",
         },

         {
           id: "vac",
           label: "Voice actor",
           __typename: "CodedTerm",
         },

         {
           id: "vdg",
           label: "Videographer",
           __typename: "CodedTerm",
         },

         {
           id: "-vo",
           label: "	Vocalist",
           __typename: "CodedTerm",
         },

         {
           id: "wac",
           label: "Writer of added commentary",
           __typename: "CodedTerm",
         },

         {
           id: "wal",
           label: "Writer of added lyrics",
           __typename: "CodedTerm",
         },

         {
           id: "wam",
           label: "Writer of accompanying material",
           __typename: "CodedTerm",
         },

         {
           id: "wat",
           label: "Writer of added text",
           __typename: "CodedTerm",
         },

         {
           id: "wdc",
           label: "Woodcutter",
           __typename: "CodedTerm",
         },

         {
           id: "wde",
           label: "Wood engraver",
           __typename: "CodedTerm",
         },

         {
           id: "win",
           label: "Writer of introduction",
           __typename: "CodedTerm",
         },

         {
           id: "wit",
           label: "Witness",
           __typename: "CodedTerm",
         },

         {
           id: "wpr",
           label: "Writer of preface",
           __typename: "CodedTerm",
         },

         {
           id: "wst",
           label: "Writer of supplementary textual content",
           __typename: "CodedTerm",
         },
       ];
