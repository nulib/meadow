/* eslint-disable */
export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
export type Exact<T extends { [key: string]: unknown }> = {
  [K in keyof T]: T[K];
};
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & {
  [SubKey in K]?: Maybe<T[SubKey]>;
};
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & {
  [SubKey in K]: Maybe<T[SubKey]>;
};
export type MakeEmpty<
  T extends { [key: string]: unknown },
  K extends keyof T,
> = { [_ in K]?: never };
export type Incremental<T> =
  | T
  | {
      [P in keyof T]?: P extends " $fragmentName" | "__typename" ? T[P] : never;
    };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: { input: string; output: string };
  String: { input: string; output: string };
  Boolean: { input: boolean; output: boolean };
  Int: { input: number; output: number };
  Float: { input: number; output: number };
  /**
   * The `DateTime` scalar type represents a date and time in the UTC
   * timezone. The DateTime appears in a JSON response as an ISO8601 formatted
   * string, including UTC timezone ("Z"). The parsed date and time string will
   * be converted to UTC if there is an offset.
   */
  DateTime: { input: any; output: any };
};

/** Action outcomes */
export enum ActionOutcome {
  /** Action failed; see notes field for details */
  Error = "ERROR",
  /** Action completed successfully */
  Ok = "OK",
  /** Action skipped due to upstream error(s) */
  Skipped = "SKIPPED",
  /** Action has been initiated but not yet completed */
  Started = "STARTED",
  /** Action is pending but not yet started */
  Waiting = "WAITING",
}

/** The state of a single action within a pipeline */
export type ActionState = {
  __typename?: "ActionState";
  /** The module name of the action */
  action?: Maybe<Scalars["String"]["output"]>;
  insertedAt: Scalars["DateTime"]["output"];
  /** Additional details regarding the success or failure of the action */
  notes?: Maybe<Scalars["String"]["output"]>;
  /** The ID of the Work or FileSet target of the action */
  objectId: Scalars["String"]["output"];
  /** The most recent outcome of the action */
  outcome?: Maybe<ActionOutcome>;
  updatedAt: Scalars["DateTime"]["output"];
};

export type ApiToken = {
  __typename?: "ApiToken";
  expires: Scalars["DateTime"]["output"];
  token: Scalars["String"]["output"];
};

/** Fields for a `batch` object */
export type Batch = {
  __typename?: "Batch";
  add?: Maybe<Scalars["String"]["output"]>;
  delete?: Maybe<Scalars["String"]["output"]>;
  error?: Maybe<Scalars["String"]["output"]>;
  id?: Maybe<Scalars["ID"]["output"]>;
  nickname?: Maybe<Scalars["String"]["output"]>;
  query?: Maybe<Scalars["String"]["output"]>;
  replace?: Maybe<Scalars["String"]["output"]>;
  started?: Maybe<Scalars["DateTime"]["output"]>;
  status?: Maybe<BatchStatus>;
  type?: Maybe<BatchType>;
  user?: Maybe<Scalars["String"]["output"]>;
  worksUpdated?: Maybe<Scalars["Int"]["output"]>;
};

/** Input fields available for batch add (append) operations on works administrative metadata */
export type BatchAddAdministrativeMetadataInput = {
  projectDesc?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectManager?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectProposer?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectTaskNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
};

/** Input fields available for batch add (append) operations on works descriptive metadata */
export type BatchAddDescriptiveMetadataInput = {
  abstract?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  alternateTitle?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  boxName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  boxNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  caption?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  catalogKey?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  contributor?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  creator?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  culturalContext?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  dateCreated?: InputMaybe<Array<InputMaybe<EdtfDateInput>>>;
  description?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  folderName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  folderNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  genre?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  identifier?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  keywords?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  language?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  legacyIdentifier?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  location?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  notes?: InputMaybe<Array<InputMaybe<NoteEntryInput>>>;
  physicalDescriptionMaterial?: InputMaybe<
    Array<InputMaybe<Scalars["String"]["input"]>>
  >;
  physicalDescriptionSize?: InputMaybe<
    Array<InputMaybe<Scalars["String"]["input"]>>
  >;
  provenance?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  publisher?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  relatedMaterial?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  relatedUrl?: InputMaybe<Array<InputMaybe<RelatedUrlEntryInput>>>;
  rightsHolder?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  scopeAndContents?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  series?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  source?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  stylePeriod?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  subject?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  tableOfContents?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  technique?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
};

/** Input fields for batch add operations */
export type BatchAddInput = {
  administrativeMetadata?: InputMaybe<BatchAddAdministrativeMetadataInput>;
  descriptiveMetadata?: InputMaybe<BatchAddDescriptiveMetadataInput>;
};

/** Input fields for batch delete operations */
export type BatchDeleteInput = {
  contributor?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  creator?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  genre?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  language?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  location?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  stylePeriod?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  subject?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  technique?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
};

/** Input fields available for batch replace operations on works administrative metadata */
export type BatchReplaceAdministrativeMetadataInput = {
  libraryUnit?: InputMaybe<CodedTermInput>;
  preservationLevel?: InputMaybe<CodedTermInput>;
  projectCycle?: InputMaybe<Scalars["String"]["input"]>;
  projectDesc?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectManager?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectProposer?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectTaskNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  status?: InputMaybe<CodedTermInput>;
};

/** Input fields available for batch replace operations on works descriptive metadata */
export type BatchReplaceDescriptiveMetadataInput = {
  abstract?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  alternateTitle?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  boxName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  boxNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  caption?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  catalogKey?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  culturalContext?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  dateCreated?: InputMaybe<Array<InputMaybe<EdtfDateInput>>>;
  description?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  folderName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  folderNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  identifier?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  keywords?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  legacyIdentifier?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  license?: InputMaybe<CodedTermInput>;
  notes?: InputMaybe<Array<InputMaybe<NoteEntryInput>>>;
  physicalDescriptionMaterial?: InputMaybe<
    Array<InputMaybe<Scalars["String"]["input"]>>
  >;
  physicalDescriptionSize?: InputMaybe<
    Array<InputMaybe<Scalars["String"]["input"]>>
  >;
  provenance?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  publisher?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  relatedMaterial?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  relatedUrl?: InputMaybe<Array<InputMaybe<RelatedUrlEntryInput>>>;
  rightsHolder?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  rightsStatement?: InputMaybe<CodedTermInput>;
  scopeAndContents?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  series?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  source?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  tableOfContents?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  termsOfUse?: InputMaybe<Scalars["String"]["input"]>;
  title?: InputMaybe<Scalars["String"]["input"]>;
};

/** Input fields for batch replace operations */
export type BatchReplaceInput = {
  administrativeMetadata?: InputMaybe<BatchReplaceAdministrativeMetadataInput>;
  collectionId?: InputMaybe<Scalars["ID"]["input"]>;
  descriptiveMetadata?: InputMaybe<BatchReplaceDescriptiveMetadataInput>;
  published?: InputMaybe<Scalars["Boolean"]["input"]>;
  visibility?: InputMaybe<CodedTermInput>;
};

/** Batch status values */
export enum BatchStatus {
  /** Completed Successfully */
  Complete = "COMPLETE",
  /** Error */
  Error = "ERROR",
  /** In Progress */
  InProgress = "IN_PROGRESS",
  /** queued */
  Queued = "QUEUED",
}

/** Batch type values */
export enum BatchType {
  /** Batch Delete */
  Delete = "DELETE",
  /** Batch Update */
  Update = "UPDATE",
}

/** Schemes for code list table. (Ex: Subjects, MARC relators, prevervation levels, etc) */
export enum CodeListScheme {
  /** Authority */
  Authority = "AUTHORITY",
  /** IIIF Behavior */
  Behavior = "BEHAVIOR",
  /** File Set Role */
  FileSetRole = "FILE_SET_ROLE",
  /** Library Unit */
  LibraryUnit = "LIBRARY_UNIT",
  /** License */
  License = "LICENSE",
  /** MARC Relator */
  MarcRelator = "MARC_RELATOR",
  /** Note Type */
  NoteType = "NOTE_TYPE",
  /** Preservation Level */
  PreservationLevel = "PRESERVATION_LEVEL",
  /** Related URL */
  RelatedUrl = "RELATED_URL",
  /** Rights Statement */
  RightsStatement = "RIGHTS_STATEMENT",
  /** Status */
  Status = "STATUS",
  /** Subject Role */
  SubjectRole = "SUBJECT_ROLE",
  /** Visibility */
  Visibility = "VISIBILITY",
  /** Work Type */
  WorkType = "WORK_TYPE",
}

/** An entry from a code list */
export type CodedTerm = {
  __typename?: "CodedTerm";
  id?: Maybe<Scalars["ID"]["output"]>;
  label?: Maybe<Scalars["String"]["output"]>;
  scheme?: Maybe<CodeListScheme>;
};

/** Input for code lookup in code list table. Provide id and scheme */
export type CodedTermInput = {
  id?: InputMaybe<Scalars["ID"]["input"]>;
  scheme?: InputMaybe<CodeListScheme>;
};

/** Fields for a `collection` object */
export type Collection = {
  __typename?: "Collection";
  adminEmail?: Maybe<Scalars["String"]["output"]>;
  description?: Maybe<Scalars["String"]["output"]>;
  featured?: Maybe<Scalars["Boolean"]["output"]>;
  findingAidUrl?: Maybe<Scalars["String"]["output"]>;
  id?: Maybe<Scalars["ID"]["output"]>;
  keywords?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  published?: Maybe<Scalars["Boolean"]["output"]>;
  /** @deprecated Use  `representativeWork`. */
  representativeImage?: Maybe<Scalars["String"]["output"]>;
  representativeWork?: Maybe<Work>;
  title?: Maybe<Scalars["String"]["output"]>;
  totalWorks?: Maybe<Scalars["Int"]["output"]>;
  visibility?: Maybe<CodedTerm>;
  works?: Maybe<Array<Maybe<Work>>>;
};

/** Controlled metadata entry */
export type ControlledMetadataEntry = {
  __typename?: "ControlledMetadataEntry";
  role?: Maybe<CodedTerm>;
  term?: Maybe<ControlledTerm>;
};

/** Controlled Vocab input, id required, label is looked up on the backend. Provide role for compound vocabs */
export type ControlledMetadataEntryInput = {
  role?: InputMaybe<CodedTermInput>;
  term: Scalars["ID"]["input"];
};

/** Controlled value associated with a role */
export type ControlledTerm = {
  __typename?: "ControlledTerm";
  id?: Maybe<Scalars["ID"]["output"]>;
  label?: Maybe<Scalars["String"]["output"]>;
};

/** Search or fetch result */
export type ControlledValue = {
  __typename?: "ControlledValue";
  hint?: Maybe<Scalars["String"]["output"]>;
  id?: Maybe<Scalars["ID"]["output"]>;
  label?: Maybe<Scalars["String"]["output"]>;
};

/** Fields for a `metadata_update_job` object */
export type CsvMetadataUpdateJob = {
  __typename?: "CsvMetadataUpdateJob";
  errors?: Maybe<Array<Maybe<RowErrors>>>;
  filename?: Maybe<Scalars["String"]["output"]>;
  id?: Maybe<Scalars["ID"]["output"]>;
  insertedAt?: Maybe<Scalars["DateTime"]["output"]>;
  rows?: Maybe<Scalars["Int"]["output"]>;
  source?: Maybe<Scalars["String"]["output"]>;
  startedAt?: Maybe<Scalars["DateTime"]["output"]>;
  status?: Maybe<Scalars["String"]["output"]>;
  updatedAt?: Maybe<Scalars["DateTime"]["output"]>;
  user?: Maybe<Scalars["String"]["output"]>;
};

/** `digests` represents the possible digest hashes for a file set. */
export type Digests = {
  __typename?: "Digests";
  md5?: Maybe<Scalars["String"]["output"]>;
  sha1?: Maybe<Scalars["String"]["output"]>;
  sha256?: Maybe<Scalars["String"]["output"]>;
};

/** EDTF Date */
export type EdtfDateEntry = {
  __typename?: "EdtfDateEntry";
  edtf?: Maybe<Scalars["String"]["output"]>;
  humanized?: Maybe<Scalars["String"]["output"]>;
};

/** EDTF date input */
export type EdtfDateInput = {
  edtf?: InputMaybe<Scalars["String"]["input"]>;
};

export type Error = {
  __typename?: "Error";
  field: Scalars["String"]["output"];
  message: Scalars["String"]["output"];
};

export type Errors = {
  __typename?: "Errors";
  field: Scalars["String"]["output"];
  messages?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
};

export type Field = {
  __typename?: "Field";
  header: Scalars["String"]["output"];
  value: Scalars["String"]["output"];
};

export type FieldInfo = {
  __typename?: "FieldInfo";
  id?: Maybe<Scalars["String"]["output"]>;
  label?: Maybe<Scalars["String"]["output"]>;
  metadataClass?: Maybe<Scalars["String"]["output"]>;
  repeating?: Maybe<Scalars["Boolean"]["output"]>;
  required?: Maybe<Scalars["Boolean"]["output"]>;
  role?: Maybe<CodeListScheme>;
  scheme?: Maybe<CodeListScheme>;
};

/** A `file_set` object represents one file (repository object in S3) */
export type FileSet = {
  __typename?: "FileSet";
  accessionNumber: Scalars["String"]["output"];
  coreMetadata?: Maybe<FileSetCoreMetadata>;
  extractedMetadata?: Maybe<Scalars["String"]["output"]>;
  groupWith?: Maybe<Scalars["ID"]["output"]>;
  id: Scalars["ID"]["output"];
  insertedAt: Scalars["DateTime"]["output"];
  position?: Maybe<Scalars["String"]["output"]>;
  posterOffset?: Maybe<Scalars["Int"]["output"]>;
  rank?: Maybe<Scalars["Int"]["output"]>;
  representativeImageUrl?: Maybe<Scalars["String"]["output"]>;
  role: CodedTerm;
  streamingUrl?: Maybe<Scalars["String"]["output"]>;
  structuralMetadata?: Maybe<FileSetStructuralMetadata>;
  updatedAt: Scalars["DateTime"]["output"];
  work?: Maybe<Work>;
};

/** `file_set_core_metadata` represents all metadata associated with a file set object. It is stored in a single json field. */
export type FileSetCoreMetadata = {
  __typename?: "FileSetCoreMetadata";
  description?: Maybe<Scalars["String"]["output"]>;
  digests?: Maybe<Digests>;
  label?: Maybe<Scalars["String"]["output"]>;
  location?: Maybe<Scalars["String"]["output"]>;
  mimeType?: Maybe<Scalars["String"]["output"]>;
  originalFilename?: Maybe<Scalars["String"]["output"]>;
};

/** Same as `file_set_core_metadata`. This represents all metadata associated with a file_set accepted on creation. It is stored in a single json field. */
export type FileSetCoreMetadataInput = {
  description?: InputMaybe<Scalars["String"]["input"]>;
  label?: InputMaybe<Scalars["String"]["input"]>;
  location?: InputMaybe<Scalars["String"]["input"]>;
  originalFilename?: InputMaybe<Scalars["String"]["input"]>;
};

/** Same as `file_set_core_metadata`. This represents all updatable metadata associated with a file_set. It is stored in a single json field. */
export type FileSetCoreMetadataUpdate = {
  description?: InputMaybe<Scalars["String"]["input"]>;
  label?: InputMaybe<Scalars["String"]["input"]>;
};

/** Input fields for a `file_set` creation object */
export type FileSetInput = {
  accessionNumber: Scalars["String"]["input"];
  coreMetadata?: InputMaybe<FileSetCoreMetadataInput>;
  role: CodedTermInput;
};

/** `file_set_structural_metadata` represents the structural metadata within a file set object. */
export type FileSetStructuralMetadata = {
  __typename?: "FileSetStructuralMetadata";
  type?: Maybe<StructuralMetadataType>;
  value?: Maybe<Scalars["String"]["output"]>;
};

/** Input fields for `file_set_structural_metadata`. */
export type FileSetStructuralMetadataInput = {
  type?: InputMaybe<StructuralMetadataType>;
  value?: InputMaybe<Scalars["String"]["input"]>;
};

/** Same as `file_set_core_metadata`. This represents all updatable metadata associated with a file_set. It is stored in a single json field. */
export type FileSetUpdate = {
  coreMetadata?: InputMaybe<FileSetCoreMetadataUpdate>;
  id: Scalars["ID"]["input"];
  structuralMetadata?: InputMaybe<FileSetStructuralMetadataInput>;
};

/** Whether or not a file set's presence in preservation location is verified */
export type FileSetVerificationStatus = {
  __typename?: "FileSetVerificationStatus";
  fileSetId?: Maybe<Scalars["ID"]["output"]>;
  verified?: Maybe<Scalars["Boolean"]["output"]>;
};

/** Sheet object */
export type IngestSheet = {
  __typename?: "IngestSheet";
  /** An array of file level error messages */
  fileErrors?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  filename: Scalars["String"]["output"];
  id: Scalars["ID"]["output"];
  ingestSheetRows?: Maybe<Array<Maybe<IngestSheetRow>>>;
  insertedAt: Scalars["DateTime"]["output"];
  project?: Maybe<Project>;
  state?: Maybe<Array<Maybe<SheetState>>>;
  /** Overall Status of the Ingest Sheet */
  status?: Maybe<IngestSheetStatus>;
  title: Scalars["String"]["output"];
  updatedAt: Scalars["DateTime"]["output"];
  validationProgress?: Maybe<ValidationProgress>;
};

/** Fields for an ingest sheet's works and file sets count */
export type IngestSheetCounts = {
  __typename?: "IngestSheetCounts";
  fail?: Maybe<Scalars["Int"]["output"]>;
  pass?: Maybe<Scalars["Int"]["output"]>;
  totalFileSets?: Maybe<Scalars["Int"]["output"]>;
  totalWorks?: Maybe<Scalars["Int"]["output"]>;
};

export type IngestSheetError = {
  __typename?: "IngestSheetError";
  accessionNumber?: Maybe<Scalars["String"]["output"]>;
  action: Scalars["String"]["output"];
  description?: Maybe<Scalars["String"]["output"]>;
  errors?: Maybe<Scalars["String"]["output"]>;
  filename?: Maybe<Scalars["String"]["output"]>;
  outcome: ActionOutcome;
  role?: Maybe<Scalars["String"]["output"]>;
  rowNumber?: Maybe<Scalars["Int"]["output"]>;
  workAccessionNumber?: Maybe<Scalars["String"]["output"]>;
};

export type IngestSheetRow = {
  __typename?: "IngestSheetRow";
  errors?: Maybe<Array<Maybe<Error>>>;
  fields?: Maybe<Array<Maybe<Field>>>;
  ingestSheet?: Maybe<IngestSheet>;
  row: Scalars["Int"]["output"];
  state?: Maybe<State>;
};

/** Overall status of the Ingest Sheet */
export enum IngestSheetStatus {
  /** Approved, ingest in progress */
  Approved = "APPROVED",
  /** Ingest completed */
  Completed = "COMPLETED",
  /** Ingest completed (with errors) */
  CompletedError = "COMPLETED_ERROR",
  /** Ingest Sheet deleted */
  Deleted = "DELETED",
  /** Errors validating csv file */
  FileFail = "FILE_FAIL",
  /** Errors in content rows */
  RowFail = "ROW_FAIL",
  /** Uploaded, validation in progress */
  Uploaded = "UPLOADED",
  /** Passes validation */
  Valid = "VALID",
}

/** NoteEntry */
export type NoteEntry = {
  __typename?: "NoteEntry";
  note?: Maybe<Scalars["String"]["output"]>;
  type?: Maybe<CodedTerm>;
};

/** Note input */
export type NoteEntryInput = {
  note?: InputMaybe<Scalars["String"]["input"]>;
  type?: InputMaybe<CodedTermInput>;
};

export type NulAuthorityRecord = {
  __typename?: "NulAuthorityRecord";
  hint?: Maybe<Scalars["String"]["output"]>;
  id: Scalars["ID"]["output"];
  label: Scalars["String"]["output"];
};

export type NullableUrl = {
  __typename?: "NullableUrl";
  url?: Maybe<Scalars["String"]["output"]>;
};

/** Fields for a `preservation_check` object */
export type PreservationCheck = {
  __typename?: "PreservationCheck";
  filename?: Maybe<Scalars["String"]["output"]>;
  id?: Maybe<Scalars["ID"]["output"]>;
  insertedAt?: Maybe<Scalars["DateTime"]["output"]>;
  invalidRows?: Maybe<Scalars["Int"]["output"]>;
  location?: Maybe<Scalars["String"]["output"]>;
  status?: Maybe<Scalars["String"]["output"]>;
  updatedAt?: Maybe<Scalars["DateTime"]["output"]>;
};

/** an Ingest Project */
export type Project = {
  __typename?: "Project";
  folder: Scalars["String"]["output"];
  id: Scalars["ID"]["output"];
  ingestSheets?: Maybe<Array<Maybe<IngestSheet>>>;
  insertedAt: Scalars["DateTime"]["output"];
  title: Scalars["String"]["output"];
  updatedAt: Scalars["DateTime"]["output"];
};

/** RelatedURLEntry */
export type RelatedUrlEntry = {
  __typename?: "RelatedUrlEntry";
  label?: Maybe<CodedTerm>;
  url?: Maybe<Scalars["String"]["output"]>;
};

/** Related URL input */
export type RelatedUrlEntryInput = {
  label?: InputMaybe<CodedTermInput>;
  url?: InputMaybe<Scalars["String"]["input"]>;
};

export type RootMutationType = {
  __typename?: "RootMutationType";
  /** Add a work to a Collection */
  addWorkToCollection?: Maybe<Work>;
  /** Add Works to a Collection */
  addWorksToCollection?: Maybe<Collection>;
  /** Assume role */
  assumeRole?: Maybe<StatusMessage>;
  /** Start a batch delete operation */
  batchDelete?: Maybe<Batch>;
  /** Start a batch update operation */
  batchUpdate?: Maybe<Batch>;
  /** Create a new Collection */
  createCollection?: Maybe<Collection>;
  /** Create a new Ingest Sheet for a Project */
  createIngestSheet?: Maybe<IngestSheet>;
  /** Create a new NUL AuthorityRecord */
  createNulAuthorityRecord?: Maybe<NulAuthorityRecord>;
  /** Create a new Ingest Project */
  createProject?: Maybe<Project>;
  /** Create a temporary shared link (resolves to DC) for a work */
  createSharedLink?: Maybe<SharedLink>;
  /** Create a new Work */
  createWork?: Maybe<Work>;
  /** Start a CSV metadata update operation */
  csvMetadataUpdate?: Maybe<CsvMetadataUpdateJob>;
  /** Delete a Collection */
  deleteCollection?: Maybe<Collection>;
  /** Delete a FileSet */
  deleteFileSet?: Maybe<FileSet>;
  /** Delete an Ingest Sheet */
  deleteIngestSheet?: Maybe<IngestSheet>;
  /** Delete an AuthorityRecord */
  deleteNulAuthorityRecord?: Maybe<NulAuthorityRecord>;
  /** Delete a Project */
  deleteProject?: Maybe<Project>;
  /** Delete a Work */
  deleteWork?: Maybe<Work>;
  /** Ingests a new FileSet for a work */
  ingestFileSet?: Maybe<FileSet>;
  /** Remove Works from a Collection */
  removeWorksFromCollection?: Maybe<Collection>;
  /** Replace file set (create new version) */
  replaceFileSet?: Maybe<FileSet>;
  /** Set the representative Work for a Collection */
  setCollectionImage?: Maybe<Collection>;
  /** Set user role */
  setUserRole?: Maybe<StatusMessage>;
  /** Set the representative FileSet (Access or Auxiliary) for a Work */
  setWorkImage?: Maybe<Work>;
  /** Swap file sets from one work to another */
  transferFileSets?: Maybe<Work>;
  /** Change the order of a work's access files */
  updateAccessFileOrder?: Maybe<Work>;
  /** Update a Collection */
  updateCollection?: Maybe<Collection>;
  /** Update a FileSet's metadata */
  updateFileSet?: Maybe<FileSet>;
  /** Update metadata for a list of fileSets */
  updateFileSets?: Maybe<Array<Maybe<FileSet>>>;
  /** Update an NUL AuthorityRecord */
  updateNulAuthorityRecord?: Maybe<NulAuthorityRecord>;
  /** Update an Ingest Project */
  updateProject?: Maybe<Project>;
  /** Update a Work */
  updateWork?: Maybe<Work>;
  /** Kick off Validation of an Ingest Sheet */
  validateIngestSheet?: Maybe<StatusMessage>;
};

export type RootMutationTypeAddWorkToCollectionArgs = {
  collectionId: Scalars["ID"]["input"];
  workId: Scalars["ID"]["input"];
};

export type RootMutationTypeAddWorksToCollectionArgs = {
  collectionId: Scalars["ID"]["input"];
  workIds?: InputMaybe<Array<InputMaybe<Scalars["ID"]["input"]>>>;
};

export type RootMutationTypeAssumeRoleArgs = {
  userRole: UserRole;
};

export type RootMutationTypeBatchDeleteArgs = {
  nickname?: InputMaybe<Scalars["String"]["input"]>;
  query: Scalars["String"]["input"];
};

export type RootMutationTypeBatchUpdateArgs = {
  add?: InputMaybe<BatchAddInput>;
  delete?: InputMaybe<BatchDeleteInput>;
  nickname?: InputMaybe<Scalars["String"]["input"]>;
  query: Scalars["String"]["input"];
  replace?: InputMaybe<BatchReplaceInput>;
};

export type RootMutationTypeCreateCollectionArgs = {
  adminEmail?: InputMaybe<Scalars["String"]["input"]>;
  description?: InputMaybe<Scalars["String"]["input"]>;
  featured?: InputMaybe<Scalars["Boolean"]["input"]>;
  findingAidUrl?: InputMaybe<Scalars["String"]["input"]>;
  keywords?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  published?: InputMaybe<Scalars["Boolean"]["input"]>;
  title: Scalars["String"]["input"];
  visibility?: InputMaybe<CodedTermInput>;
};

export type RootMutationTypeCreateIngestSheetArgs = {
  filename: Scalars["String"]["input"];
  projectId: Scalars["ID"]["input"];
  title: Scalars["String"]["input"];
};

export type RootMutationTypeCreateNulAuthorityRecordArgs = {
  hint?: InputMaybe<Scalars["String"]["input"]>;
  label: Scalars["String"]["input"];
};

export type RootMutationTypeCreateProjectArgs = {
  title: Scalars["String"]["input"];
};

export type RootMutationTypeCreateSharedLinkArgs = {
  workId: Scalars["ID"]["input"];
};

export type RootMutationTypeCreateWorkArgs = {
  accessionNumber: Scalars["String"]["input"];
  administrativeMetadata: WorkAdministrativeMetadataInput;
  descriptiveMetadata: WorkDescriptiveMetadataInput;
  fileSets?: InputMaybe<Array<InputMaybe<FileSetInput>>>;
  published?: InputMaybe<Scalars["Boolean"]["input"]>;
  visibility?: InputMaybe<CodedTermInput>;
  workType?: InputMaybe<CodedTermInput>;
};

export type RootMutationTypeCsvMetadataUpdateArgs = {
  filename: Scalars["String"]["input"];
  source: Scalars["String"]["input"];
};

export type RootMutationTypeDeleteCollectionArgs = {
  collectionId: Scalars["ID"]["input"];
};

export type RootMutationTypeDeleteFileSetArgs = {
  fileSetId: Scalars["ID"]["input"];
};

export type RootMutationTypeDeleteIngestSheetArgs = {
  sheetId: Scalars["ID"]["input"];
};

export type RootMutationTypeDeleteNulAuthorityRecordArgs = {
  nulAuthorityRecordId: Scalars["ID"]["input"];
};

export type RootMutationTypeDeleteProjectArgs = {
  projectId: Scalars["ID"]["input"];
};

export type RootMutationTypeDeleteWorkArgs = {
  workId: Scalars["ID"]["input"];
};

export type RootMutationTypeIngestFileSetArgs = {
  accessionNumber: Scalars["String"]["input"];
  coreMetadata: FileSetCoreMetadataInput;
  role: CodedTermInput;
  structuralMetadata?: InputMaybe<FileSetStructuralMetadataInput>;
  workId: Scalars["ID"]["input"];
};

export type RootMutationTypeRemoveWorksFromCollectionArgs = {
  collectionId: Scalars["ID"]["input"];
  workIds?: InputMaybe<Array<InputMaybe<Scalars["ID"]["input"]>>>;
};

export type RootMutationTypeReplaceFileSetArgs = {
  coreMetadata: FileSetCoreMetadataInput;
  id: Scalars["ID"]["input"];
};

export type RootMutationTypeSetCollectionImageArgs = {
  collectionId: Scalars["ID"]["input"];
  workId?: InputMaybe<Scalars["ID"]["input"]>;
};

export type RootMutationTypeSetUserRoleArgs = {
  userId: Scalars["ID"]["input"];
  userRole?: InputMaybe<UserRole>;
};

export type RootMutationTypeSetWorkImageArgs = {
  fileSetId: Scalars["ID"]["input"];
  workId: Scalars["ID"]["input"];
};

export type RootMutationTypeTransferFileSetsArgs = {
  fromWorkId: Scalars["ID"]["input"];
  toWorkId: Scalars["ID"]["input"];
};

export type RootMutationTypeUpdateAccessFileOrderArgs = {
  fileSetIds?: InputMaybe<Array<InputMaybe<Scalars["ID"]["input"]>>>;
  workId: Scalars["ID"]["input"];
};

export type RootMutationTypeUpdateCollectionArgs = {
  adminEmail?: InputMaybe<Scalars["String"]["input"]>;
  collectionId: Scalars["ID"]["input"];
  description?: InputMaybe<Scalars["String"]["input"]>;
  featured?: InputMaybe<Scalars["Boolean"]["input"]>;
  findingAidUrl?: InputMaybe<Scalars["String"]["input"]>;
  keywords?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  published?: InputMaybe<Scalars["Boolean"]["input"]>;
  title?: InputMaybe<Scalars["String"]["input"]>;
  visibility?: InputMaybe<CodedTermInput>;
};

export type RootMutationTypeUpdateFileSetArgs = {
  coreMetadata?: InputMaybe<FileSetCoreMetadataUpdate>;
  groupWith?: InputMaybe<Scalars["ID"]["input"]>;
  id: Scalars["ID"]["input"];
  posterOffset?: InputMaybe<Scalars["Int"]["input"]>;
  structuralMetadata?: InputMaybe<FileSetStructuralMetadataInput>;
};

export type RootMutationTypeUpdateFileSetsArgs = {
  fileSets: Array<InputMaybe<FileSetUpdate>>;
};

export type RootMutationTypeUpdateNulAuthorityRecordArgs = {
  hint?: InputMaybe<Scalars["String"]["input"]>;
  id: Scalars["ID"]["input"];
  label: Scalars["String"]["input"];
};

export type RootMutationTypeUpdateProjectArgs = {
  id: Scalars["ID"]["input"];
  title?: InputMaybe<Scalars["String"]["input"]>;
};

export type RootMutationTypeUpdateWorkArgs = {
  id: Scalars["ID"]["input"];
  work: WorkUpdateInput;
};

export type RootMutationTypeValidateIngestSheetArgs = {
  sheetId: Scalars["ID"]["input"];
};

export type RootQueryType = {
  __typename?: "RootQueryType";
  /** Retrieve all action states for an object */
  actionStates?: Maybe<Array<Maybe<ActionState>>>;
  /** Get a list of authority search results by its authority */
  authoritiesSearch?: Maybe<Array<Maybe<ControlledValue>>>;
  /** Get a batch by id */
  batch?: Maybe<Batch>;
  /** Get all batches */
  batches?: Maybe<Array<Maybe<Batch>>>;
  /** Get values from a code list table (for use in dropdowns, etc) */
  codeList?: Maybe<Array<Maybe<CodedTerm>>>;
  /** Get a collection by id */
  collection?: Maybe<Collection>;
  /** Get a list of collections */
  collections?: Maybe<Array<Maybe<Collection>>>;
  /** Get a metadata update job by id */
  csvMetadataUpdateJob?: Maybe<CsvMetadataUpdateJob>;
  /** Get all metadata update jobs */
  csvMetadataUpdateJobs?: Maybe<Array<Maybe<CsvMetadataUpdateJob>>>;
  /** Get a signed superuser DC API token */
  dcApiToken?: Maybe<ApiToken>;
  /** Get DCAPI endpoint */
  dcapiEndpoint?: Maybe<Url>;
  describeField?: Maybe<FieldInfo>;
  /** Describes the metadata properties on works */
  describeFields?: Maybe<Array<Maybe<FieldInfo>>>;
  /** Get digital collections endpoint */
  digitalCollectionsUrl?: Maybe<Url>;
  /** Get the label for a coded_term by its id and scheme */
  fetchCodedTermLabel?: Maybe<CodedTerm>;
  /** Get the label for a controlled_term by its id */
  fetchControlledTermLabel?: Maybe<ControlledValue>;
  /** Get a list of file sets */
  fileSets?: Maybe<Array<Maybe<FileSet>>>;
  /** Get iiif server endpoint */
  iiifServerUrl?: Maybe<Url>;
  /** Get an ingest sheet by its id */
  ingestSheet?: Maybe<IngestSheet>;
  /** Get errors for completed ingest sheet */
  ingestSheetErrors?: Maybe<Array<Maybe<IngestSheetError>>>;
  /** Get rows for an Ingest Sheet */
  ingestSheetRows?: Maybe<Array<Maybe<IngestSheetRow>>>;
  /** Get the validation status for an ingest sheet */
  ingestSheetValidationProgress?: Maybe<ValidationProgress>;
  /** Get total number of works and file sets created for an Ingest Sheet */
  ingestSheetWorkCount?: Maybe<IngestSheetCounts>;
  /** Get works created for an Ingest Sheet */
  ingestSheetWorks?: Maybe<Array<Maybe<Work>>>;
  /** List ingest bucket objects */
  listIngestBucketObjects?: Maybe<S3Listing>;
  /** Get the livebook URL */
  livebookUrl?: Maybe<NullableUrl>;
  /** Get the currently signed-in user */
  me?: Maybe<User>;
  /** Get an NUL AuthorityRecord by ID */
  nulAuthorityRecord?: Maybe<NulAuthorityRecord>;
  /** Get a list of NUL AuthorityRecords */
  nulAuthorityRecords?: Maybe<Array<Maybe<NulAuthorityRecord>>>;
  /** Get all preservation checks */
  preservationChecks?: Maybe<Array<Maybe<PreservationCheck>>>;
  /** Get a presigned url to upload a file */
  presignedUrl?: Maybe<Url>;
  /** Get a project by its id */
  project?: Maybe<Project>;
  /** Get a list of projects */
  projects?: Maybe<Array<Maybe<Project>>>;
  /** Search for projects by title */
  projectsSearch?: Maybe<Array<Maybe<Project>>>;
  /** Get the list of Roles */
  roles?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  /** List all users with their roles */
  users?: Maybe<Array<Maybe<User>>>;
  /** Get verification status for a work's fileSets */
  verifyFileSets?: Maybe<Array<Maybe<FileSetVerificationStatus>>>;
  /** Get a work by id */
  work?: Maybe<Work>;
  /** Get work archiver endpoint */
  workArchiverEndpoint?: Maybe<Url>;
  /** Get a work by accession_number */
  workByAccession?: Maybe<Work>;
  /** Get a list of works */
  works?: Maybe<Array<Maybe<Work>>>;
};

export type RootQueryTypeActionStatesArgs = {
  objectId: Scalars["ID"]["input"];
};

export type RootQueryTypeAuthoritiesSearchArgs = {
  authority: Scalars["ID"]["input"];
  query: Scalars["String"]["input"];
};

export type RootQueryTypeBatchArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeCodeListArgs = {
  scheme: CodeListScheme;
};

export type RootQueryTypeCollectionArgs = {
  collectionId: Scalars["ID"]["input"];
};

export type RootQueryTypeCsvMetadataUpdateJobArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeDescribeFieldArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeFetchCodedTermLabelArgs = {
  id: Scalars["ID"]["input"];
  scheme: CodeListScheme;
};

export type RootQueryTypeFetchControlledTermLabelArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeIngestSheetArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeIngestSheetErrorsArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeIngestSheetRowsArgs = {
  limit?: InputMaybe<Scalars["Int"]["input"]>;
  sheetId: Scalars["ID"]["input"];
  start?: InputMaybe<Scalars["Int"]["input"]>;
  state?: InputMaybe<Array<InputMaybe<State>>>;
};

export type RootQueryTypeIngestSheetValidationProgressArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeIngestSheetWorkCountArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeIngestSheetWorksArgs = {
  id: Scalars["ID"]["input"];
  limit?: InputMaybe<Scalars["Int"]["input"]>;
};

export type RootQueryTypeListIngestBucketObjectsArgs = {
  prefix?: InputMaybe<Scalars["String"]["input"]>;
};

export type RootQueryTypeNulAuthorityRecordArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeNulAuthorityRecordsArgs = {
  limit?: InputMaybe<Scalars["Int"]["input"]>;
};

export type RootQueryTypePreservationChecksArgs = {
  limit?: InputMaybe<Scalars["Int"]["input"]>;
};

export type RootQueryTypePresignedUrlArgs = {
  filename?: InputMaybe<Scalars["String"]["input"]>;
  uploadType: S3UploadType;
};

export type RootQueryTypeProjectArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeProjectsArgs = {
  limit?: InputMaybe<Scalars["Int"]["input"]>;
  order?: InputMaybe<SortOrder>;
};

export type RootQueryTypeProjectsSearchArgs = {
  query: Scalars["String"]["input"];
};

export type RootQueryTypeVerifyFileSetsArgs = {
  workId: Scalars["ID"]["input"];
};

export type RootQueryTypeWorkArgs = {
  id: Scalars["ID"]["input"];
};

export type RootQueryTypeWorkByAccessionArgs = {
  accessionNumber: Scalars["String"]["input"];
};

export type RootQueryTypeWorksArgs = {
  filter?: InputMaybe<WorkFilter>;
  limit?: InputMaybe<Scalars["Int"]["input"]>;
  order?: InputMaybe<SortOrder>;
};

export type RootSubscriptionType = {
  __typename?: "RootSubscriptionType";
  /** Subscribe to action state updates for a specific work or file set */
  actionUpdate?: Maybe<ActionState>;
  /** Subscribe to action state updates for works and file sets */
  actionUpdates?: Maybe<ActionState>;
  /** Subscribe to work creation progress notifications for an ingest sheet */
  ingestProgress?: Maybe<WorkIngestProgress>;
  /** Subscribe to updates for an ingest sheet */
  ingestSheetUpdate?: Maybe<IngestSheet>;
  /** Subscribe to ingest sheet updates for a specific project */
  ingestSheetUpdatesForProject?: Maybe<IngestSheet>;
};

export type RootSubscriptionTypeActionUpdateArgs = {
  objectId: Scalars["ID"]["input"];
};

export type RootSubscriptionTypeIngestProgressArgs = {
  sheetId: Scalars["ID"]["input"];
};

export type RootSubscriptionTypeIngestSheetUpdateArgs = {
  sheetId: Scalars["ID"]["input"];
};

export type RootSubscriptionTypeIngestSheetUpdatesForProjectArgs = {
  projectId: Scalars["ID"]["input"];
};

/** Row-based errors for a `metadata_update_job` */
export type RowErrors = {
  __typename?: "RowErrors";
  errors?: Maybe<Array<Maybe<Errors>>>;
  row?: Maybe<Scalars["Int"]["output"]>;
};

export type S3Listing = {
  __typename?: "S3Listing";
  folders?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  objects?: Maybe<Array<Maybe<S3Object>>>;
};

export type S3Object = {
  __typename?: "S3Object";
  eTag?: Maybe<Scalars["String"]["output"]>;
  key?: Maybe<Scalars["String"]["output"]>;
  lastModified?: Maybe<Scalars["String"]["output"]>;
  mimeType?: Maybe<Scalars["String"]["output"]>;
  owner?: Maybe<S3Owner>;
  size?: Maybe<Scalars["String"]["output"]>;
  storageClass?: Maybe<Scalars["String"]["output"]>;
  uri?: Maybe<Scalars["String"]["output"]>;
};

export type S3Owner = {
  __typename?: "S3Owner";
  displayName?: Maybe<Scalars["String"]["output"]>;
  id?: Maybe<Scalars["String"]["output"]>;
};

export enum S3UploadType {
  /** Metadata Update Sheet (.csv) */
  CsvMetadata = "CSV_METADATA",
  /** File Set */
  FileSet = "FILE_SET",
  /** Ingest Sheet (.csv) */
  IngestSheet = "INGEST_SHEET",
  /** Preservation check download (.csv) */
  PreservationCheck = "PRESERVATION_CHECK",
}

export type SharedLink = {
  __typename?: "SharedLink";
  expires: Scalars["DateTime"]["output"];
  sharedLinkId: Scalars["ID"]["output"];
  workId: Scalars["ID"]["output"];
};

/** Object that tracks Sheet state */
export type SheetState = {
  __typename?: "SheetState";
  /** name: file, rows, or overall */
  name?: Maybe<Scalars["String"]["output"]>;
  state: State;
};

export enum SortOrder {
  Asc = "ASC",
  Desc = "DESC",
}

/** states: PENDING, PASS or FAIL */
export enum State {
  Fail = "FAIL",
  Pass = "PASS",
  Pending = "PENDING",
}

export type StateCount = {
  __typename?: "StateCount";
  count: Scalars["Int"]["output"];
  state: State;
};

export type StatusMessage = {
  __typename?: "StatusMessage";
  message: Scalars["String"]["output"];
};

/** accepted types for structural metadata */
export enum StructuralMetadataType {
  /** Web VTT */
  Webvtt = "WEBVTT",
}

export type Url = {
  __typename?: "Url";
  url: Scalars["String"]["output"];
};

export type User = {
  __typename?: "User";
  displayName?: Maybe<Scalars["String"]["output"]>;
  email?: Maybe<Scalars["String"]["output"]>;
  role?: Maybe<UserRole>;
  token?: Maybe<Scalars["String"]["output"]>;
  username: Scalars["String"]["output"];
};

/** Meadow user roles */
export enum UserRole {
  /** administrator */
  Administrator = "ADMINISTRATOR",
  /** editor */
  Editor = "EDITOR",
  /** manager */
  Manager = "MANAGER",
  /** superuser */
  Superuser = "SUPERUSER",
  /** user */
  User = "USER",
}

export type ValidationProgress = {
  __typename?: "ValidationProgress";
  percentComplete: Scalars["Float"]["output"];
  states?: Maybe<Array<Maybe<StateCount>>>;
  total: Scalars["Int"]["output"];
};

/** A work object */
export type Work = {
  __typename?: "Work";
  accessionNumber: Scalars["String"]["output"];
  administrativeMetadata?: Maybe<WorkAdministrativeMetadata>;
  behavior?: Maybe<CodedTerm>;
  collection?: Maybe<Collection>;
  descriptiveMetadata?: Maybe<WorkDescriptiveMetadata>;
  fileSets?: Maybe<Array<Maybe<FileSet>>>;
  id: Scalars["ID"]["output"];
  ingestSheet?: Maybe<IngestSheet>;
  insertedAt: Scalars["DateTime"]["output"];
  manifestUrl?: Maybe<Scalars["String"]["output"]>;
  project?: Maybe<Project>;
  published?: Maybe<Scalars["Boolean"]["output"]>;
  representativeImage?: Maybe<Scalars["String"]["output"]>;
  updatedAt: Scalars["DateTime"]["output"];
  visibility?: Maybe<CodedTerm>;
  workType?: Maybe<CodedTerm>;
};

/** `work_administrative_metadata` represents all administrative metadata associated with a work object. It is stored in a single json field. */
export type WorkAdministrativeMetadata = {
  __typename?: "WorkAdministrativeMetadata";
  libraryUnit?: Maybe<CodedTerm>;
  preservationLevel?: Maybe<CodedTerm>;
  projectCycle?: Maybe<Scalars["String"]["output"]>;
  projectDesc?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  projectManager?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  projectName?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  projectProposer?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  projectTaskNumber?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  status?: Maybe<CodedTerm>;
};

/** Input fields for works administrative metadata */
export type WorkAdministrativeMetadataInput = {
  libraryUnit?: InputMaybe<CodedTermInput>;
  preservationLevel?: InputMaybe<CodedTermInput>;
  projectCycle?: InputMaybe<Scalars["String"]["input"]>;
  projectDesc?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectManager?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectProposer?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  projectTaskNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  status?: InputMaybe<CodedTermInput>;
};

/** `work_descriptive_metadata` represents all descriptive metadata associated with a work object. */
export type WorkDescriptiveMetadata = {
  __typename?: "WorkDescriptiveMetadata";
  abstract?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  alternateTitle?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  ark?: Maybe<Scalars["String"]["output"]>;
  boxName?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  boxNumber?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  caption?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  catalogKey?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  citation?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  contributor?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  creator?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  culturalContext?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  dateCreated?: Maybe<Array<Maybe<EdtfDateEntry>>>;
  description?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  folderName?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  folderNumber?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  genre?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  identifier?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  keywords?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  language?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  legacyIdentifier?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  license?: Maybe<CodedTerm>;
  location?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  notes?: Maybe<Array<Maybe<NoteEntry>>>;
  physicalDescriptionMaterial?: Maybe<
    Array<Maybe<Scalars["String"]["output"]>>
  >;
  physicalDescriptionSize?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  provenance?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  publisher?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  relatedMaterial?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  relatedUrl?: Maybe<Array<Maybe<RelatedUrlEntry>>>;
  rightsHolder?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  rightsStatement?: Maybe<CodedTerm>;
  scopeAndContents?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  series?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  source?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  stylePeriod?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  subject?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  tableOfContents?: Maybe<Array<Maybe<Scalars["String"]["output"]>>>;
  technique?: Maybe<Array<Maybe<ControlledMetadataEntry>>>;
  termsOfUse?: Maybe<Scalars["String"]["output"]>;
  title?: Maybe<Scalars["String"]["output"]>;
};

/** Input fields for works descriptive metadata */
export type WorkDescriptiveMetadataInput = {
  abstract?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  alternateTitle?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  boxName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  boxNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  caption?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  catalogKey?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  contributor?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  creator?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  culturalContext?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  dateCreated?: InputMaybe<Array<InputMaybe<EdtfDateInput>>>;
  description?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  folderName?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  folderNumber?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  genre?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  identifier?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  keywords?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  language?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  legacyIdentifier?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  license?: InputMaybe<CodedTermInput>;
  location?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  notes?: InputMaybe<Array<InputMaybe<NoteEntryInput>>>;
  physicalDescriptionMaterial?: InputMaybe<
    Array<InputMaybe<Scalars["String"]["input"]>>
  >;
  physicalDescriptionSize?: InputMaybe<
    Array<InputMaybe<Scalars["String"]["input"]>>
  >;
  provenance?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  publisher?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  relatedMaterial?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  relatedUrl?: InputMaybe<Array<InputMaybe<RelatedUrlEntryInput>>>;
  rightsHolder?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  rightsStatement?: InputMaybe<CodedTermInput>;
  scopeAndContents?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  series?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  source?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  stylePeriod?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  subject?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  tableOfContents?: InputMaybe<Array<InputMaybe<Scalars["String"]["input"]>>>;
  technique?: InputMaybe<Array<InputMaybe<ControlledMetadataEntryInput>>>;
  termsOfUse?: InputMaybe<Scalars["String"]["input"]>;
  title?: InputMaybe<Scalars["String"]["input"]>;
};

/** Filters for the list of works */
export type WorkFilter = {
  /** Matching a title */
  matching?: InputMaybe<Scalars["String"]["input"]>;
};

/**
 * A summary progress report on the ingest of a single Ingest Sheet. NOTE: This
 * does not indicate success, only done-ness.
 */
export type WorkIngestProgress = {
  __typename?: "WorkIngestProgress";
  /** The number of actions that have reached OK or ERROR state */
  completedActions: Scalars["Int"]["output"];
  /** The number of FileSets that have reached OK or ERROR state */
  completedFileSets: Scalars["Int"]["output"];
  /** The percentage of actions that have reached OK or ERROR state */
  percentComplete: Scalars["Float"]["output"];
  /** The ID of the Ingest Sheet in progress */
  sheetId: Scalars["ID"]["output"];
  /** The total number of actions required to complete the ingest */
  totalActions: Scalars["Int"]["output"];
  /** The total number of FileSets attached to the Ingest Sheet */
  totalFileSets: Scalars["Int"]["output"];
};

/** Fields that can be updated on a work object */
export type WorkUpdateInput = {
  administrativeMetadata?: InputMaybe<WorkAdministrativeMetadataInput>;
  behavior?: InputMaybe<CodedTermInput>;
  collectionId?: InputMaybe<Scalars["ID"]["input"]>;
  descriptiveMetadata?: InputMaybe<WorkDescriptiveMetadataInput>;
  published?: InputMaybe<Scalars["Boolean"]["input"]>;
  visibility?: InputMaybe<CodedTermInput>;
};
