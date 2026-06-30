/* eslint-disable */
/** Internal type. DO NOT USE DIRECTLY. */
type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
/** Internal type. DO NOT USE DIRECTLY. */
export type Incremental<T> =
  | T
  | {
      [P in keyof T]?: P extends " $fragmentName" | "__typename" ? T[P] : never;
    };
import { TypedDocumentNode as DocumentNode } from "@graphql-typed-document-node/core";
/** Action outcomes */
export type ActionOutcome =
  /** Action failed; see notes field for details */
  | "ERROR"
  /** Action completed successfully */
  | "OK"
  /** Action skipped due to upstream error(s) */
  | "SKIPPED"
  /** Action has been initiated but not yet completed */
  | "STARTED"
  /** Action is pending but not yet started */
  | "WAITING";

/** Input fields available for batch add (append) operations on works administrative metadata */
export type BatchAddAdministrativeMetadataInput = {
  projectDesc?: Array<string | null | undefined> | null | undefined;
  projectManager?: Array<string | null | undefined> | null | undefined;
  projectName?: Array<string | null | undefined> | null | undefined;
  projectProposer?: Array<string | null | undefined> | null | undefined;
  projectTaskNumber?: Array<string | null | undefined> | null | undefined;
};

/** Input fields available for batch add (append) operations on works descriptive metadata */
export type BatchAddDescriptiveMetadataInput = {
  abstract?: Array<string | null | undefined> | null | undefined;
  alternateTitle?: Array<string | null | undefined> | null | undefined;
  boxName?: Array<string | null | undefined> | null | undefined;
  boxNumber?: Array<string | null | undefined> | null | undefined;
  caption?: Array<string | null | undefined> | null | undefined;
  catalogKey?: Array<string | null | undefined> | null | undefined;
  contributor?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  creator?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  culturalContext?: Array<string | null | undefined> | null | undefined;
  dateCreated?: Array<EdtfDateInput | null | undefined> | null | undefined;
  description?: Array<string | null | undefined> | null | undefined;
  folderName?: Array<string | null | undefined> | null | undefined;
  folderNumber?: Array<string | null | undefined> | null | undefined;
  genre?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  identifier?: Array<string | null | undefined> | null | undefined;
  keywords?: Array<string | null | undefined> | null | undefined;
  language?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  legacyIdentifier?: Array<string | null | undefined> | null | undefined;
  location?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  notes?: Array<NoteEntryInput | null | undefined> | null | undefined;
  physicalDescriptionMaterial?:
    | Array<string | null | undefined>
    | null
    | undefined;
  physicalDescriptionSize?: Array<string | null | undefined> | null | undefined;
  provenance?: Array<string | null | undefined> | null | undefined;
  publisher?: Array<string | null | undefined> | null | undefined;
  relatedMaterial?: Array<string | null | undefined> | null | undefined;
  relatedUrl?:
    | Array<RelatedUrlEntryInput | null | undefined>
    | null
    | undefined;
  rightsHolder?: Array<string | null | undefined> | null | undefined;
  scopeAndContents?: Array<string | null | undefined> | null | undefined;
  series?: Array<string | null | undefined> | null | undefined;
  source?: Array<string | null | undefined> | null | undefined;
  stylePeriod?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  subject?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  tableOfContents?: Array<string | null | undefined> | null | undefined;
  technique?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
};

/** Input fields for batch add operations */
export type BatchAddInput = {
  administrativeMetadata?:
    | BatchAddAdministrativeMetadataInput
    | null
    | undefined;
  descriptiveMetadata?: BatchAddDescriptiveMetadataInput | null | undefined;
};

/** Input fields for batch delete operations */
export type BatchDeleteInput = {
  contributor?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  creator?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  genre?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  language?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  location?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  stylePeriod?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  subject?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  technique?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
};

/** Input fields available for batch replace operations on works administrative metadata */
export type BatchReplaceAdministrativeMetadataInput = {
  libraryUnit?: CodedTermInput | null | undefined;
  preservationLevel?: CodedTermInput | null | undefined;
  projectCycle?: string | null | undefined;
  projectDesc?: Array<string | null | undefined> | null | undefined;
  projectManager?: Array<string | null | undefined> | null | undefined;
  projectName?: Array<string | null | undefined> | null | undefined;
  projectProposer?: Array<string | null | undefined> | null | undefined;
  projectTaskNumber?: Array<string | null | undefined> | null | undefined;
  status?: CodedTermInput | null | undefined;
};

/** Input fields available for batch replace operations on works descriptive metadata */
export type BatchReplaceDescriptiveMetadataInput = {
  abstract?: Array<string | null | undefined> | null | undefined;
  alternateTitle?: Array<string | null | undefined> | null | undefined;
  boxName?: Array<string | null | undefined> | null | undefined;
  boxNumber?: Array<string | null | undefined> | null | undefined;
  caption?: Array<string | null | undefined> | null | undefined;
  catalogKey?: Array<string | null | undefined> | null | undefined;
  culturalContext?: Array<string | null | undefined> | null | undefined;
  dateCreated?: Array<EdtfDateInput | null | undefined> | null | undefined;
  description?: Array<string | null | undefined> | null | undefined;
  folderName?: Array<string | null | undefined> | null | undefined;
  folderNumber?: Array<string | null | undefined> | null | undefined;
  identifier?: Array<string | null | undefined> | null | undefined;
  keywords?: Array<string | null | undefined> | null | undefined;
  legacyIdentifier?: Array<string | null | undefined> | null | undefined;
  license?: CodedTermInput | null | undefined;
  notes?: Array<NoteEntryInput | null | undefined> | null | undefined;
  physicalDescriptionMaterial?:
    | Array<string | null | undefined>
    | null
    | undefined;
  physicalDescriptionSize?: Array<string | null | undefined> | null | undefined;
  provenance?: Array<string | null | undefined> | null | undefined;
  publisher?: Array<string | null | undefined> | null | undefined;
  relatedMaterial?: Array<string | null | undefined> | null | undefined;
  relatedUrl?:
    | Array<RelatedUrlEntryInput | null | undefined>
    | null
    | undefined;
  rightsHolder?: Array<string | null | undefined> | null | undefined;
  rightsStatement?: CodedTermInput | null | undefined;
  scopeAndContents?: Array<string | null | undefined> | null | undefined;
  series?: Array<string | null | undefined> | null | undefined;
  source?: Array<string | null | undefined> | null | undefined;
  tableOfContents?: Array<string | null | undefined> | null | undefined;
  termsOfUse?: string | null | undefined;
  title?: string | null | undefined;
};

/** Input fields for batch replace operations */
export type BatchReplaceInput = {
  administrativeMetadata?:
    | BatchReplaceAdministrativeMetadataInput
    | null
    | undefined;
  collectionId?: string | number | null | undefined;
  descriptiveMetadata?: BatchReplaceDescriptiveMetadataInput | null | undefined;
  published?: boolean | null | undefined;
  visibility?: CodedTermInput | null | undefined;
};

/** Batch status values */
export type BatchStatus =
  /** Completed Successfully */
  | "COMPLETE"
  /** Error */
  | "ERROR"
  /** In Progress */
  | "IN_PROGRESS"
  /** queued */
  | "QUEUED";

/** Batch type values */
export type BatchType =
  /** Batch Delete */
  | "DELETE"
  /** Batch Update */
  | "UPDATE";

/** Schemes for code list table. (Ex: Subjects, MARC relators, prevervation levels, etc) */
export type CodeListScheme =
  /** Authority */
  | "AUTHORITY"
  /** IIIF Behavior */
  | "BEHAVIOR"
  /** File Set Role */
  | "FILE_SET_ROLE"
  /** Library Unit */
  | "LIBRARY_UNIT"
  /** License */
  | "LICENSE"
  /** MARC Relator */
  | "MARC_RELATOR"
  /** Note Type */
  | "NOTE_TYPE"
  /** Preservation Level */
  | "PRESERVATION_LEVEL"
  /** Related URL */
  | "RELATED_URL"
  /** Rights Statement */
  | "RIGHTS_STATEMENT"
  /** Status */
  | "STATUS"
  /** Subject Role */
  | "SUBJECT_ROLE"
  /** Visibility */
  | "VISIBILITY"
  /** Work Type */
  | "WORK_TYPE";

/** Input for code lookup in code list table. Provide id and scheme */
export type CodedTermInput = {
  id?: string | number | null | undefined;
  scheme?: CodeListScheme | null | undefined;
};

/** Controlled Vocab input, id required, label is looked up on the backend. Provide role for compound vocabs */
export type ControlledMetadataEntryInput = {
  role?: CodedTermInput | null | undefined;
  term: string | number;
};

/** EDTF date input */
export type EdtfDateInput = {
  edtf?: string | null | undefined;
};

export type EvalManualScore = "BAD" | "GOOD" | "UNSCORED";

export type EvalRunStatus =
  | "CANCELLED"
  | "COMPLETE"
  | "ERRORED"
  | "PENDING"
  | "RUNNING";

export type EvalTrialStatus =
  | "COMPLETE"
  | "ERRORED"
  | "PENDING"
  | "RUNNING"
  | "SKIPPED";

/** Same as `file_set_core_metadata`. This represents all metadata associated with a file_set accepted on creation. It is stored in a single json field. */
export type FileSetCoreMetadataInput = {
  altText?: string | null | undefined;
  description?: string | null | undefined;
  imageCaption?: string | null | undefined;
  label?: string | null | undefined;
  location?: string | null | undefined;
  originalFilename?: string | null | undefined;
};

/** Same as `file_set_core_metadata`. This represents all updatable metadata associated with a file_set. It is stored in a single json field. */
export type FileSetCoreMetadataUpdate = {
  altText?: string | null | undefined;
  description?: string | null | undefined;
  imageCaption?: string | null | undefined;
  label?: string | null | undefined;
};

/** Input fields for `file_set_structural_metadata`. */
export type FileSetStructuralMetadataInput = {
  type?: StructuralMetadataType | null | undefined;
  value?: string | null | undefined;
};

/** Same as `file_set_core_metadata`. This represents all updatable metadata associated with a file_set. It is stored in a single json field. */
export type FileSetUpdate = {
  coreMetadata?: FileSetCoreMetadataUpdate | null | undefined;
  id: string | number;
  structuralMetadata?: FileSetStructuralMetadataInput | null | undefined;
};

/** An explicit assertion that a field's live value is human-authored despite prior AI provenance */
export type HumanAuthoredAttestationInput = {
  fieldPath: string;
  /** When given, attest only these item identifiers within the field (multivalued fields); omit to attest the whole field */
  itemIds?: Array<string> | null | undefined;
  reason?: string | null | undefined;
};

/** Overall status of the Ingest Sheet */
export type IngestSheetStatus =
  /** Approved, ingest in progress */
  | "APPROVED"
  /** Valid AI ingest sheet awaiting supermanager approval */
  | "AWAITING_APPROVAL"
  /** Ingest completed */
  | "COMPLETED"
  /** Ingest completed (with errors) */
  | "COMPLETED_ERROR"
  /** Ingest Sheet deleted */
  | "DELETED"
  /** Errors validating csv file */
  | "FILE_FAIL"
  /** AI preview generation in progress */
  | "GENERATING_PREVIEW"
  /** Errors in content rows */
  | "ROW_FAIL"
  /** Uploaded, validation in progress */
  | "UPLOADED"
  /** Passes validation */
  | "VALID";

/** Note input */
export type NoteEntryInput = {
  note?: string | null | undefined;
  type?: CodedTermInput | null | undefined;
};

/** Plan status values */
export type PlanStatus =
  /** Approved, will be applied */
  | "APPROVED"
  /** Successfully applied */
  | "COMPLETED"
  /** Failed to apply */
  | "ERROR"
  /** Plan created */
  | "PENDING"
  /** Pending review */
  | "PROPOSED"
  /** Rejected, will not be applied */
  | "REJECTED";

/** Related URL input */
export type RelatedUrlEntryInput = {
  label?: CodedTermInput | null | undefined;
  url?: string | null | undefined;
};

export type S3UploadType =
  /** Metadata Update Sheet (.csv) */
  | "CSV_METADATA"
  /** File Set */
  | "FILE_SET"
  /** Ingest Sheet (.csv) */
  | "INGEST_SHEET"
  /** Preservation check download (.csv) */
  | "PRESERVATION_CHECK";

/** states: PENDING, PASS or FAIL */
export type State = "FAIL" | "PASS" | "PENDING";

/** accepted types for structural metadata */
export type StructuralMetadataType =
  /** Web VTT */
  "WEBVTT";

/** Meadow user roles */
export type UserRole =
  /** administrator */
  | "ADMINISTRATOR"
  /** editor */
  | "EDITOR"
  /** manager */
  | "MANAGER"
  /** supermanager */
  | "SUPERMANAGER"
  /** superuser */
  | "SUPERUSER"
  /** user */
  | "USER";

/** Input fields for works administrative metadata */
export type WorkAdministrativeMetadataInput = {
  libraryUnit?: CodedTermInput | null | undefined;
  preservationLevel?: CodedTermInput | null | undefined;
  projectCycle?: string | null | undefined;
  projectDesc?: Array<string | null | undefined> | null | undefined;
  projectManager?: Array<string | null | undefined> | null | undefined;
  projectName?: Array<string | null | undefined> | null | undefined;
  projectProposer?: Array<string | null | undefined> | null | undefined;
  projectTaskNumber?: Array<string | null | undefined> | null | undefined;
  status?: CodedTermInput | null | undefined;
};

/** Complete work definition for creating a new work during file set transfer */
export type WorkAttributesInput = {
  /** Unique identifier for the work */
  accessionNumber: string;
  /** Administrative metadata (project info, library unit, etc.) */
  administrativeMetadata?: WorkAdministrativeMetadataInput | null | undefined;
  /** Behavior setting for the work */
  behavior?: CodedTermInput | null | undefined;
  /** Optional collection to add the work to */
  collectionId?: string | number | null | undefined;
  /** Rich descriptive metadata (title, description, etc.) */
  descriptiveMetadata?: WorkDescriptiveMetadataInput | null | undefined;
  /** Optional ingest sheet reference */
  ingestSheetId?: string | number | null | undefined;
  /** Whether the work should be published (default: false) */
  published?: boolean | null | undefined;
  /** Visibility setting (default: RESTRICTED) */
  visibility?: CodedTermInput | null | undefined;
  /** Work type (e.g., 'IMAGE', 'AUDIO', 'VIDEO') */
  workType: string;
};

/** Input fields for works descriptive metadata */
export type WorkDescriptiveMetadataInput = {
  abstract?: Array<string | null | undefined> | null | undefined;
  alternateTitle?: Array<string | null | undefined> | null | undefined;
  boxName?: Array<string | null | undefined> | null | undefined;
  boxNumber?: Array<string | null | undefined> | null | undefined;
  caption?: Array<string | null | undefined> | null | undefined;
  catalogKey?: Array<string | null | undefined> | null | undefined;
  contributor?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  creator?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  culturalContext?: Array<string | null | undefined> | null | undefined;
  dateCreated?: Array<EdtfDateInput | null | undefined> | null | undefined;
  description?: Array<string | null | undefined> | null | undefined;
  folderName?: Array<string | null | undefined> | null | undefined;
  folderNumber?: Array<string | null | undefined> | null | undefined;
  genre?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  identifier?: Array<string | null | undefined> | null | undefined;
  keywords?: Array<string | null | undefined> | null | undefined;
  language?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  legacyIdentifier?: Array<string | null | undefined> | null | undefined;
  license?: CodedTermInput | null | undefined;
  location?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  navPlace?: unknown;
  notes?: Array<NoteEntryInput | null | undefined> | null | undefined;
  physicalDescriptionMaterial?:
    | Array<string | null | undefined>
    | null
    | undefined;
  physicalDescriptionSize?: Array<string | null | undefined> | null | undefined;
  provenance?: Array<string | null | undefined> | null | undefined;
  relatedMaterial?: Array<string | null | undefined> | null | undefined;
  relatedUrl?:
    | Array<RelatedUrlEntryInput | null | undefined>
    | null
    | undefined;
  rightsHolder?: Array<string | null | undefined> | null | undefined;
  rightsStatement?: CodedTermInput | null | undefined;
  scopeAndContents?: Array<string | null | undefined> | null | undefined;
  series?: Array<string | null | undefined> | null | undefined;
  source?: Array<string | null | undefined> | null | undefined;
  stylePeriod?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  subject?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  tableOfContents?: Array<string | null | undefined> | null | undefined;
  technique?:
    | Array<ControlledMetadataEntryInput | null | undefined>
    | null
    | undefined;
  termsOfUse?: string | null | undefined;
  title?: string | null | undefined;
};

/** Fields that can be updated on a work object */
export type WorkUpdateInput = {
  administrativeMetadata?: WorkAdministrativeMetadataInput | null | undefined;
  behavior?: CodedTermInput | null | undefined;
  collectionId?: string | number | null | undefined;
  descriptiveMetadata?: WorkDescriptiveMetadataInput | null | undefined;
  /** Fields to mark as human-authored after prior AI provenance, recorded in the same save */
  humanAuthoredAttestations?:
    | Array<HumanAuthoredAttestationInput | null | undefined>
    | null
    | undefined;
  published?: boolean | null | undefined;
  visibility?: CodedTermInput | null | undefined;
};

export type GetCurrentUserQueryVariables = Exact<{ [key: string]: never }>;

export type GetCurrentUserQuery = {
  me: {
    username: string;
    email: string | null;
    role: UserRole | null;
    displayName: string | null;
  } | null;
};

export type ListRolesQueryVariables = Exact<{ [key: string]: never }>;

export type ListRolesQuery = { roles: Array<string | null> | null };

export type ListUsersQueryVariables = Exact<{ [key: string]: never }>;

export type ListUsersQuery = {
  users: Array<{
    username: string;
    email: string | null;
    role: UserRole | null;
    displayName: string | null;
  } | null> | null;
};

export type SetUserRoleMutationVariables = Exact<{
  userId: string | number;
  userRole?: UserRole | null | undefined;
}>;

export type SetUserRoleMutation = { setUserRole: { message: string } | null };

export type BatchUpdateMutationVariables = Exact<{
  add?: BatchAddInput | null | undefined;
  delete?: BatchDeleteInput | null | undefined;
  query: string;
  replace?: BatchReplaceInput | null | undefined;
  nickname?: string | null | undefined;
}>;

export type BatchUpdateMutation = {
  batchUpdate: {
    id: string | null;
    nickname: string | null;
    status: BatchStatus | null;
    user: string | null;
    started: unknown;
    type: BatchType | null;
    query: string | null;
    add: string | null;
    replace: string | null;
    delete: string | null;
    error: string | null;
  } | null;
};

export type BatchDeleteMutationVariables = Exact<{
  query: string;
  nickname?: string | null | undefined;
}>;

export type BatchDeleteMutation = {
  batchDelete: {
    id: string | null;
    nickname: string | null;
    status: BatchStatus | null;
    user: string | null;
    started: unknown;
    type: BatchType | null;
    query: string | null;
    add: string | null;
    replace: string | null;
    delete: string | null;
    error: string | null;
  } | null;
};

export type CreateCollectionMutationVariables = Exact<{
  adminEmail?: string | null | undefined;
  collectionTitle: string;
  description?: string | null | undefined;
  featured?: boolean | null | undefined;
  findingAidUrl?: string | null | undefined;
  keywords?: Array<string | null | undefined> | string | null | undefined;
  published?: boolean | null | undefined;
  visibility?: CodedTermInput | null | undefined;
}>;

export type CreateCollectionMutation = {
  createCollection: {
    id: string | null;
    adminEmail: string | null;
    description: string | null;
    featured: boolean | null;
    findingAidUrl: string | null;
    keywords: Array<string | null> | null;
    published: boolean | null;
    title: string | null;
    visibility: { id: string | null; label: string | null } | null;
  } | null;
};

export type SetCollectionImageMutationVariables = Exact<{
  collectionId: string | number;
  workId?: string | number | null | undefined;
}>;

export type SetCollectionImageMutation = {
  setCollectionImage: {
    id: string | null;
    representativeWork: {
      id: string;
      representativeImage: string | null;
    } | null;
  } | null;
};

export type DeleteCollectionMutationVariables = Exact<{
  collectionId: string | number;
}>;

export type DeleteCollectionMutation = {
  deleteCollection: { id: string | null; title: string | null } | null;
};

export type GetCollectionQueryVariables = Exact<{
  id: string | number;
}>;

export type GetCollectionQuery = {
  collection: {
    adminEmail: string | null;
    description: string | null;
    featured: boolean | null;
    findingAidUrl: string | null;
    id: string | null;
    keywords: Array<string | null> | null;
    published: boolean | null;
    title: string | null;
    totalWorks: number | null;
    representativeWork: {
      id: string;
      representativeImage: string | null;
    } | null;
    stats: {
      audio: number | null;
      image: number | null;
      published: number | null;
      total: number | null;
      unpublished: number | null;
      video: number | null;
    } | null;
    visibility: { id: string | null; label: string | null } | null;
  } | null;
};

export type GetCollectionsQueryVariables = Exact<{ [key: string]: never }>;

export type GetCollectionsQuery = {
  collections: Array<{
    adminEmail: string | null;
    description: string | null;
    featured: boolean | null;
    findingAidUrl: string | null;
    id: string | null;
    keywords: Array<string | null> | null;
    published: boolean | null;
    title: string | null;
    totalWorks: number | null;
    representativeWork: {
      id: string;
      representativeImage: string | null;
    } | null;
    visibility: { id: string | null; label: string | null } | null;
  } | null> | null;
};

export type UpdateCollectionMutationVariables = Exact<{
  adminEmail?: string | null | undefined;
  collectionId: string | number;
  collectionTitle?: string | null | undefined;
  description?: string | null | undefined;
  featured?: boolean | null | undefined;
  findingAidUrl?: string | null | undefined;
  keywords?: Array<string | null | undefined> | string | null | undefined;
  published?: boolean | null | undefined;
  visibility?: CodedTermInput | null | undefined;
}>;

export type UpdateCollectionMutation = {
  updateCollection: {
    adminEmail: string | null;
    description: string | null;
    featured: boolean | null;
    findingAidUrl: string | null;
    id: string | null;
    keywords: Array<string | null> | null;
    published: boolean | null;
    title: string | null;
    visibility: { id: string | null; label: string | null } | null;
  } | null;
};

export type GetEvalQueryListQueryVariables = Exact<{ [key: string]: never }>;

export type GetEvalQueryListQuery = {
  evalQueryList: Array<{
    id: string;
    name: string;
    description: string | null;
    queryJson: unknown;
    author: string | null;
    insertedAt: unknown;
  } | null> | null;
};

export type GetDefaultEvalQueryQueryVariables = Exact<{ [key: string]: never }>;

export type GetDefaultEvalQueryQuery = {
  defaultEvalQuery: {
    id: string;
    name: string;
    description: string | null;
    queryJson: unknown;
  } | null;
};

export type GetEvalPromptVersionsQueryVariables = Exact<{
  [key: string]: never;
}>;

export type GetEvalPromptVersionsQuery = {
  evalPromptVersions: Array<{
    id: string;
    name: string;
    subjectPrompt: string | null;
    descriptionPrompt: string | null;
    systemPrompt: string;
    userPromptTemplate: string;
    parentVersionId: string | null;
    author: string | null;
    changeNotes: string | null;
    archived: boolean;
    insertedAt: unknown;
  } | null> | null;
};

export type GetEvalSetsQueryVariables = Exact<{ [key: string]: never }>;

export type GetEvalSetsQuery = {
  evalSets: Array<{
    id: string;
    name: string;
    description: string | null;
    workCount: number | null;
    author: string | null;
    insertedAt: unknown;
  } | null> | null;
};

export type GetEvalRunsQueryVariables = Exact<{
  limit?: number | null | undefined;
  offset?: number | null | undefined;
}>;

export type GetEvalRunsQuery = {
  evalRuns: Array<{
    id: string;
    name: string | null;
    status: EvalRunStatus | null;
    trialsPerWork: number;
    author: string | null;
    startedAt: unknown;
    completedAt: unknown;
    insertedAt: unknown;
    evalSet: { id: string; name: string; workCount: number | null } | null;
    promptVersion: { id: string; name: string } | null;
    summary: {
      total: number | null;
      complete: number | null;
      errored: number | null;
      pending: number | null;
      manualGood: number | null;
      manualBad: number | null;
      meanDescriptionJudgeScore: number | null;
      meanSubjectsJudgeScore: number | null;
    } | null;
  } | null> | null;
};

export type GetEvalRunQueryVariables = Exact<{
  id: string | number;
}>;

export type GetEvalRunQuery = {
  evalRun: {
    id: string;
    name: string | null;
    status: EvalRunStatus | null;
    trialsPerWork: number;
    author: string | null;
    startedAt: unknown;
    completedAt: unknown;
    insertedAt: unknown;
    error: string | null;
    evalSet: {
      id: string;
      name: string;
      workCount: number | null;
      evalSetMembers: Array<{
        id: string;
        workId: string;
        accessionNumber: string | null;
        groundTruth: unknown;
      } | null> | null;
    } | null;
    promptVersion: {
      id: string;
      name: string;
      subjectPrompt: string | null;
      descriptionPrompt: string | null;
      systemPrompt: string;
      userPromptTemplate: string;
    } | null;
    summary: {
      total: number | null;
      complete: number | null;
      errored: number | null;
      pending: number | null;
      running: number | null;
      manualGood: number | null;
      manualBad: number | null;
      meanDescriptionJudgeScore: number | null;
      meanSubjectsJudgeScore: number | null;
    } | null;
    evalTrials: Array<{
      id: string;
      workId: string;
      trialIndex: number;
      status: EvalTrialStatus | null;
      descriptionJudgeScore: number | null;
      subjectsJudgeScore: number | null;
      judgeRationale: string | null;
      manualScore: EvalManualScore | null;
      manualNotes: string | null;
      manualScoredBy: string | null;
      manualScoredAt: unknown;
      durationMs: number | null;
      error: string | null;
      agentOutput: unknown;
      updatedAt: unknown;
    } | null> | null;
  } | null;
};

export type CreateEvalQueryMutationVariables = Exact<{
  name: string;
  description?: string | null | undefined;
  queryJson: unknown;
}>;

export type CreateEvalQueryMutation = {
  createEvalQuery: {
    id: string;
    name: string;
    description: string | null;
    queryJson: unknown;
    author: string | null;
    insertedAt: unknown;
  } | null;
};

export type UpdateEvalQueryMutationVariables = Exact<{
  id: string | number;
  name?: string | null | undefined;
  description?: string | null | undefined;
  queryJson?: unknown;
}>;

export type UpdateEvalQueryMutation = {
  updateEvalQuery: {
    id: string;
    name: string;
    description: string | null;
    queryJson: unknown;
  } | null;
};

export type DeleteEvalQueryMutationVariables = Exact<{
  id: string | number;
}>;

export type DeleteEvalQueryMutation = {
  deleteEvalQuery: { id: string; name: string } | null;
};

export type CreateEvalPromptVersionMutationVariables = Exact<{
  name: string;
  subjectPrompt: string;
  descriptionPrompt: string;
  parentVersionId?: string | number | null | undefined;
  changeNotes?: string | null | undefined;
}>;

export type CreateEvalPromptVersionMutation = {
  createEvalPromptVersion: {
    id: string;
    name: string;
    archived: boolean;
    insertedAt: unknown;
  } | null;
};

export type ArchiveEvalPromptVersionMutationVariables = Exact<{
  id: string | number;
}>;

export type ArchiveEvalPromptVersionMutation = {
  archiveEvalPromptVersion: { id: string; archived: boolean } | null;
};

export type CreateEvalSetFromWorkIdsMutationVariables = Exact<{
  workIds: Array<string | number> | string | number;
  name: string;
  description?: string | null | undefined;
}>;

export type CreateEvalSetFromWorkIdsMutation = {
  createEvalSetFromWorkIds: {
    id: string;
    name: string;
    workCount: number | null;
    insertedAt: unknown;
  } | null;
};

export type CreateEvalSetMutationVariables = Exact<{
  queryId: string | number;
  name: string;
  description?: string | null | undefined;
}>;

export type CreateEvalSetMutation = {
  createEvalSet: {
    id: string;
    name: string;
    workCount: number | null;
    insertedAt: unknown;
  } | null;
};

export type CreateEvalRunMutationVariables = Exact<{
  evalSetId: string | number;
  promptVersionId: string | number;
  name?: string | null | undefined;
  trialsPerWork?: number | null | undefined;
  concurrency?: number | null | undefined;
}>;

export type CreateEvalRunMutation = {
  createEvalRun: {
    id: string;
    name: string | null;
    status: EvalRunStatus | null;
  } | null;
};

export type CancelEvalRunMutationVariables = Exact<{
  id: string | number;
}>;

export type CancelEvalRunMutation = {
  cancelEvalRun: { id: string; status: EvalRunStatus | null } | null;
};

export type ScoreEvalTrialMutationVariables = Exact<{
  id: string | number;
  score: EvalManualScore;
  notes?: string | null | undefined;
}>;

export type ScoreEvalTrialMutation = {
  scoreEvalTrial: {
    id: string;
    manualScore: EvalManualScore | null;
    manualNotes: string | null;
    manualScoredBy: string | null;
    manualScoredAt: unknown;
  } | null;
};

export type ClearEvalTrialScoreMutationVariables = Exact<{
  id: string | number;
}>;

export type ClearEvalTrialScoreMutation = {
  clearEvalTrialScore: {
    id: string;
    manualScore: EvalManualScore | null;
    manualNotes: string | null;
  } | null;
};

export type GetAiActivitiesQueryVariables = Exact<{
  activityType?: string | null | undefined;
  aiUseType?: string | null | undefined;
  status?: string | null | undefined;
  limit?: number | null | undefined;
}>;

export type GetAiActivitiesQuery = {
  aiActivities: Array<{
    id: string;
    activityType: string;
    aiUseType: string | null;
    status: string;
    model: string | null;
    modelProvider: string | null;
    workId: string | null;
    costUsd: number | null;
    startedAt: unknown;
    completedAt: unknown;
    insertedAt: unknown;
  } | null> | null;
};

export type GetAiActivityQueryVariables = Exact<{
  id: string | number;
}>;

export type GetAiActivityQuery = {
  aiActivity: {
    id: string;
    activityType: string;
    aiUseType: string | null;
    accessMode: string | null;
    reversibility: string | null;
    status: string;
    error: string | null;
    model: string | null;
    modelProvider: string | null;
    modelVersion: string | null;
    promptVersion: string | null;
    costUsd: number | null;
    workId: string | null;
    fileSetId: string | null;
    planId: string | null;
    startedAt: unknown;
    completedAt: unknown;
    sources: Array<{
      id: string;
      itemType: string | null;
      itemId: string | null;
      collectionTitle: string | null;
      holdingOrganization: string | null;
      accessLink: string | null;
      restricted: boolean | null;
    } | null> | null;
    targets: Array<{
      id: string;
      targetType: string;
      fieldPath: string;
      operation: string | null;
      origin: string;
      status: string;
      proposedValue: unknown;
      events: Array<{
        id: string;
        eventType: string;
        actor: string | null;
        occurredAt: unknown;
        outcome: string | null;
        notes: string | null;
        agentLinks: Array<{
          id: string;
          role: string;
          agent: {
            id: string;
            agentType: string;
            name: string;
            version: string | null;
          } | null;
        } | null> | null;
      } | null> | null;
    } | null> | null;
  } | null;
};

export type CsvMetadataUpdateMutationVariables = Exact<{
  filename: string;
  source: string;
}>;

export type CsvMetadataUpdateMutation = {
  csvMetadataUpdate: {
    id: string | null;
    filename: string | null;
    insertedAt: unknown;
    rows: number | null;
    source: string | null;
    startedAt: unknown;
    status: string | null;
    updatedAt: unknown;
    user: string | null;
    errors: Array<{
      row: number | null;
      errors: Array<{
        field: string;
        messages: Array<string | null> | null;
      } | null> | null;
    } | null> | null;
  } | null;
};

export type CreateNulAuthorityRecordMutationVariables = Exact<{
  hint?: string | null | undefined;
  label: string;
}>;

export type CreateNulAuthorityRecordMutation = {
  createNulAuthorityRecord: {
    hint: string | null;
    id: string;
    label: string;
  } | null;
};

export type DeleteNulAuthorityRecordMutationVariables = Exact<{
  id: string | number;
}>;

export type DeleteNulAuthorityRecordMutation = {
  deleteNulAuthorityRecord: { id: string; label: string } | null;
};

export type BatchQueryVariables = Exact<{
  id: string | number;
}>;

export type BatchQuery = {
  batch: {
    add: string | null;
    delete: string | null;
    error: string | null;
    id: string | null;
    nickname: string | null;
    query: string | null;
    replace: string | null;
    started: unknown;
    status: BatchStatus | null;
    type: BatchType | null;
    user: string | null;
    worksUpdated: number | null;
  } | null;
};

export type BatchesQueryVariables = Exact<{ [key: string]: never }>;

export type BatchesQuery = {
  batches: Array<{
    add: string | null;
    delete: string | null;
    error: string | null;
    id: string | null;
    nickname: string | null;
    query: string | null;
    replace: string | null;
    started: unknown;
    status: BatchStatus | null;
    type: BatchType | null;
    user: string | null;
    worksUpdated: number | null;
  } | null> | null;
};

export type PreservationChecksQueryVariables = Exact<{ [key: string]: never }>;

export type PreservationChecksQuery = {
  preservationChecks: Array<{
    id: string | null;
    filename: string | null;
    insertedAt: unknown;
    invalidRows: number | null;
    location: string | null;
    status: string | null;
    updatedAt: unknown;
  } | null> | null;
};

export type CsvMetadataUpdateJobQueryVariables = Exact<{
  id: string | number;
}>;

export type CsvMetadataUpdateJobQuery = {
  csvMetadataUpdateJob: {
    id: string | null;
    filename: string | null;
    insertedAt: unknown;
    rows: number | null;
    source: string | null;
    startedAt: unknown;
    status: string | null;
    updatedAt: unknown;
    user: string | null;
    errors: Array<{
      row: number | null;
      errors: Array<{
        field: string;
        messages: Array<string | null> | null;
      } | null> | null;
    } | null> | null;
  } | null;
};

export type CsvMetadataUpdateJobsQueryVariables = Exact<{
  [key: string]: never;
}>;

export type CsvMetadataUpdateJobsQuery = {
  csvMetadataUpdateJobs: Array<{
    id: string | null;
    filename: string | null;
    insertedAt: unknown;
    rows: number | null;
    source: string | null;
    startedAt: unknown;
    status: string | null;
    updatedAt: unknown;
    user: string | null;
    errors: Array<{
      row: number | null;
      errors: Array<{
        field: string;
        messages: Array<string | null> | null;
      } | null> | null;
    } | null> | null;
  } | null> | null;
};

export type NulAuthorityRecordsQueryVariables = Exact<{
  limit?: number | null | undefined;
}>;

export type NulAuthorityRecordsQuery = {
  nulAuthorityRecords: Array<{
    id: string;
    hint: string | null;
    label: string;
  } | null> | null;
};

export type UpdateNulAuthorityRecordMutationVariables = Exact<{
  hint?: string | null | undefined;
  id: string | number;
  label: string;
}>;

export type UpdateNulAuthorityRecordMutation = {
  updateNulAuthorityRecord: {
    hint: string | null;
    id: string;
    label: string;
  } | null;
};

export type ListObsoleteControlledTermsQueryVariables = Exact<{
  limit?: number | null | undefined;
}>;

export type ListObsoleteControlledTermsQuery = {
  obsoleteControlledTerms: Array<{
    id: string | null;
    label: string | null;
    replacedBy: string | null;
    replacementLabel: string | null;
  } | null> | null;
};

export type IiifServerUrlQueryVariables = Exact<{ [key: string]: never }>;

export type IiifServerUrlQuery = { iiifServerUrl: { url: string } | null };

export type IngestSheetPartsFragment = {
  fileErrors: Array<string | null> | null;
  filename: string;
  id: string;
  status: IngestSheetStatus | null;
  title: string;
  ingestSheetRows: Array<{
    row: number;
    state: State | null;
    errors: Array<{ field: string; message: string } | null> | null;
    fields: Array<{ header: string; value: string } | null> | null;
  } | null> | null;
  state: Array<{ name: string | null; state: State } | null> | null;
} & { " $fragmentName"?: "IngestSheetPartsFragment" };

export type CreateIngestSheetMutationVariables = Exact<{
  title: string;
  projectId: string | number;
  filename: string;
  aiIngest?: boolean | null | undefined;
}>;

export type CreateIngestSheetMutation = {
  createIngestSheet: {
    id: string;
    title: string;
    status: IngestSheetStatus | null;
    aiIngest: boolean | null;
    filename: string;
    project: { id: string; title: string } | null;
  } | null;
};

export type DeleteIngestSheetMutationVariables = Exact<{
  sheetId: string | number;
}>;

export type DeleteIngestSheetMutation = {
  deleteIngestSheet: {
    id: string;
    title: string;
    status: IngestSheetStatus | null;
  } | null;
};

export type GetPresignedUrlQueryVariables = Exact<{
  uploadType: S3UploadType;
  filename?: string | null | undefined;
}>;

export type GetPresignedUrlQuery = { presignedUrl: { url: string } | null };

export type OnIngestProgressSubscriptionVariables = Exact<{
  sheetId: string | number;
}>;

export type OnIngestProgressSubscription = {
  ingestProgress: {
    totalFileSets: number;
    completedFileSets: number;
    percentComplete: number;
  } | null;
};

export type IngestSheetCompletedErrorsQueryVariables = Exact<{
  id: string | number;
}>;

export type IngestSheetCompletedErrorsQuery = {
  ingestSheetErrors: Array<{
    accessionNumber: string | null;
    action: string;
    description: string | null;
    errors: string | null;
    filename: string | null;
    outcome: ActionOutcome;
    role: string | null;
    rowNumber: number | null;
    workAccessionNumber: string | null;
  } | null> | null;
};

export type IngestSheetQueryQueryVariables = Exact<{
  sheetId: string | number;
}>;

export type IngestSheetQueryQuery = {
  ingestSheet: {
    aiIngest: boolean | null;
    aiCostActual: number | null;
    aiCostEstimate: number | null;
    aiPreview: unknown;
    fileErrors: Array<string | null> | null;
    filename: string;
    id: string;
    status: IngestSheetStatus | null;
    title: string;
    state: Array<{ name: string | null; state: State } | null> | null;
  } | null;
};

export type IngestSheetRowValidationErrorsQueryVariables = Exact<{
  limit?: number | null | undefined;
  sheetId: string | number;
  state?: Array<State | null | undefined> | State | null | undefined;
}>;

export type IngestSheetRowValidationErrorsQuery = {
  ingestSheetRows: Array<{
    row: number;
    state: State | null;
    fields: Array<{ header: string; value: string } | null> | null;
    errors: Array<{ field: string; message: string } | null> | null;
  } | null> | null;
};

export type OnIngestSheetUpdateSubscriptionVariables = Exact<{
  sheetId: string | number;
}>;

export type OnIngestSheetUpdateSubscription = {
  ingestSheetUpdate: {
    aiIngest: boolean | null;
    aiCostActual: number | null;
    aiCostEstimate: number | null;
    aiPreview: unknown;
    fileErrors: Array<string | null> | null;
    filename: string;
    id: string;
    status: IngestSheetStatus | null;
    title: string;
    state: Array<{ name: string | null; state: State } | null> | null;
  } | null;
};

export type IngestSheetValidationProgressQueryVariables = Exact<{
  sheetId: string | number;
}>;

export type IngestSheetValidationProgressQuery = {
  ingestSheetValidationProgress: { percentComplete: number } | null;
};

export type IngestSheetWorkCountQueryVariables = Exact<{
  id: string | number;
}>;

export type IngestSheetWorkCountQuery = {
  ingestSheetWorkCount: {
    totalWorks: number | null;
    totalFileSets: number | null;
    appendedFileSets: number | null;
    pass: number | null;
    fail: number | null;
  } | null;
};

export type IngestSheetWorksQueryVariables = Exact<{
  id: string | number;
  limit?: number | null | undefined;
}>;

export type IngestSheetWorksQuery = {
  ingestSheetWorks: Array<{
    id: string;
    accessionNumber: string;
    insertedAt: unknown;
    manifestUrl: string | null;
    published: boolean | null;
    representativeImage: string | null;
    updatedAt: unknown;
    descriptiveMetadata: {
      title: string | null;
      description: Array<string | null> | null;
    } | null;
    fileSets: Array<{
      id: string;
      accessionNumber: string;
      role: { id: string | null; label: string | null };
      coreMetadata: {
        description: string | null;
        originalFilename: string | null;
        label: string | null;
        location: string | null;
      } | null;
    } | null> | null;
    workType: { id: string | null; label: string | null } | null;
    visibility: { id: string | null; label: string | null } | null;
  } | null> | null;
};

export type GetIngestSheetsQueryVariables = Exact<{
  projectId: string | number;
}>;

export type GetIngestSheetsQuery = {
  project: {
    id: string;
    ingestSheets: Array<{
      id: string;
      title: string;
      status: IngestSheetStatus | null;
      updatedAt: unknown;
    } | null> | null;
  } | null;
};

export type ValidateIngestSheetMutationVariables = Exact<{
  id: string | number;
}>;

export type ValidateIngestSheetMutation = {
  validateIngestSheet: { message: string } | null;
};

export type ChatResponseSubscriptionVariables = Exact<{
  conversationId: string | number;
}>;

export type ChatResponseSubscription = {
  chatResponse: {
    conversationId: string | null;
    message: string | null;
    type: string | null;
    planId: string | null;
  } | null;
};

export type SendChatMessageMutationVariables = Exact<{
  conversationId: string | number;
  type: string;
  prompt: string;
  query: string;
}>;

export type SendChatMessageMutation = {
  sendChatMessage: {
    conversationId: string | null;
    type: string | null;
    prompt: string | null;
    query: string | null;
  } | null;
};

export type PlanChangesUpdatedSubscriptionVariables = Exact<{
  planId: string | number;
}>;

export type PlanChangesUpdatedSubscription = {
  planChangesUpdated: {
    planId: string;
    action: string;
    planChange: {
      id: string | null;
      status: PlanStatus | null;
      add: unknown;
      replace: unknown;
      delete: unknown;
    } | null;
  } | null;
};

export type PlanUpdatedSubscriptionVariables = Exact<{
  planId: string | number;
}>;

export type PlanUpdatedSubscription = {
  planUpdated: { id: string | null; status: PlanStatus | null } | null;
};

export type PlanQueryVariables = Exact<{
  id: string | number;
}>;

export type PlanQuery = {
  plan: {
    id: string | null;
    prompt: string | null;
    query: string | null;
    status: PlanStatus | null;
  } | null;
};

export type PlanChangesQueryVariables = Exact<{
  planId: string | number;
}>;

export type PlanChangesQuery = {
  planChanges: Array<{
    id: string | null;
    status: PlanStatus | null;
    add: unknown;
    delete: unknown;
    replace: unknown;
  } | null> | null;
};

export type PlanChangeProvenanceQueryVariables = Exact<{
  planChangeId: string | number;
}>;

export type PlanChangeProvenanceQuery = {
  aiActivities: Array<{
    id: string;
    targets: Array<{
      fieldPath: string;
      origin: string;
      status: string;
      operation: string | null;
      proposedValue: unknown;
      itemProvenance: Array<{
        id: string | null;
        origin: string | null;
      } | null> | null;
      events: Array<{ eventType: string; valueAfter: unknown } | null> | null;
    } | null> | null;
  } | null> | null;
};

export type UpdatePlanStatusMutationVariables = Exact<{
  id: string | number;
  status: PlanStatus;
}>;

export type UpdatePlanStatusMutation = {
  updatePlanStatus: { id: string | null; status: PlanStatus | null } | null;
};

export type UpdatePlanChangeStatusMutationVariables = Exact<{
  id: string | number;
  status: PlanStatus;
}>;

export type UpdatePlanChangeStatusMutation = {
  updatePlanChangeStatus: {
    id: string | null;
    status: PlanStatus | null;
  } | null;
};

export type UpdatePlanChangeMutationVariables = Exact<{
  id: string | number;
  add?: unknown;
  replace?: unknown;
  delete?: unknown;
}>;

export type UpdatePlanChangeMutation = {
  updatePlanChange: {
    id: string | null;
    add: unknown;
    replace: unknown;
    delete: unknown;
    status: PlanStatus | null;
  } | null;
};

export type DeletePlanChangeMutationVariables = Exact<{
  planChangeId: string | number;
}>;

export type DeletePlanChangeMutation = {
  deletePlanChange: { id: string | null } | null;
};

export type UpdateProposedPlanChangeStatusesMutationVariables = Exact<{
  planId: string | number;
  status: PlanStatus;
}>;

export type UpdateProposedPlanChangeStatusesMutation = {
  updateProposedPlanChangeStatuses: Array<{
    planId: string | null;
    status: PlanStatus | null;
  } | null> | null;
};

export type ApplyPlanMutationVariables = Exact<{
  id: string | number;
}>;

export type ApplyPlanMutation = {
  applyPlan: {
    id: string | null;
    status: PlanStatus | null;
    completedAt: unknown;
    error: string | null;
  } | null;
};

export type CreateProjectMutationVariables = Exact<{
  projectTitle: string;
}>;

export type CreateProjectMutation = {
  createProject: { id: string; title: string; folder: string } | null;
};

export type UpdateProjectMutationVariables = Exact<{
  projectId: string | number;
  projectTitle: string;
}>;

export type UpdateProjectMutation = {
  updateProject: { id: string; title: string; folder: string } | null;
};

export type DeleteProjectMutationVariables = Exact<{
  projectId: string | number;
}>;

export type DeleteProjectMutation = {
  deleteProject: { id: string; title: string } | null;
};

export type GetProjectQueryVariables = Exact<{
  projectId: string | number;
}>;

export type GetProjectQuery = {
  project: {
    id: string;
    folder: string;
    title: string;
    updatedAt: unknown;
    ingestSheets: Array<{
      id: string;
      title: string;
      status: IngestSheetStatus | null;
      updatedAt: unknown;
    } | null> | null;
  } | null;
};

export type GetProjectsQueryVariables = Exact<{ [key: string]: never }>;

export type GetProjectsQuery = {
  projects: Array<{
    id: string;
    title: string;
    folder: string;
    updatedAt: unknown;
    ingestSheets: Array<{ id: string } | null> | null;
  } | null> | null;
};

export type ProjectsSearchQueryVariables = Exact<{
  query: string;
}>;

export type ProjectsSearchQuery = {
  projectsSearch: Array<{
    id: string;
    title: string;
    folder: string;
    updatedAt: unknown;
    ingestSheets: Array<{ id: string } | null> | null;
  } | null> | null;
};

export type IngestSheetUpdatesForProjectSubscriptionVariables = Exact<{
  projectId: string | number;
}>;

export type IngestSheetUpdatesForProjectSubscription = {
  ingestSheetUpdatesForProject: {
    id: string;
    title: string;
    status: IngestSheetStatus | null;
    updatedAt: unknown;
  } | null;
};

export type AssumeRoleMutationVariables = Exact<{
  userRole: UserRole;
}>;

export type AssumeRoleMutation = { assumeRole: { message: string } | null };

export type DigitalCollectionsUrlQueryVariables = Exact<{
  [key: string]: never;
}>;

export type DigitalCollectionsUrlQuery = {
  digitalCollectionsUrl: { url: string } | null;
};

export type DcapiEndpointQueryVariables = Exact<{ [key: string]: never }>;

export type DcapiEndpointQuery = { dcapiEndpoint: { url: string } | null };

export type LivebookUrlQueryVariables = Exact<{ [key: string]: never }>;

export type LivebookUrlQuery = { livebookUrl: { url: string | null } | null };

export type UpsertGeoreferenceAnnotationMutationVariables = Exact<{
  fileSetId: string | number;
  type: string;
  content: string;
  language?: Array<string | null | undefined> | string | null | undefined;
}>;

export type UpsertGeoreferenceAnnotationMutation = {
  upsertFileSetAnnotation: {
    id: string;
    fileSetId: string;
    type: string;
    language: Array<string | null> | null;
    status: string;
    content: string | null;
    insertedAt: unknown;
    updatedAt: unknown;
  } | null;
};

export type DeleteFileSetAnnotationMutationVariables = Exact<{
  annotationId: string | number;
}>;

export type DeleteFileSetAnnotationMutation = {
  deleteFileSetAnnotation: { id: string; fileSetId: string } | null;
};

export type GetWorkAiActivitiesQueryVariables = Exact<{
  workId?: string | number | null | undefined;
}>;

export type GetWorkAiActivitiesQuery = {
  aiActivities: Array<{
    id: string;
    activityType: string;
    aiUseType: string | null;
    status: string;
    model: string | null;
    modelProvider: string | null;
    startedAt: unknown;
    completedAt: unknown;
    costUsd: number | null;
    fileSetId: string | null;
    targets: Array<{
      id: string;
      targetType: string;
      fieldPath: string;
      operation: string | null;
      origin: string;
      status: string;
      proposedValue: unknown;
      events: Array<{
        id: string;
        eventType: string;
        actor: string | null;
        occurredAt: unknown;
        outcome: string | null;
        notes: string | null;
        itemIdentifier: string | null;
        valueBefore: unknown;
        valueAfter: unknown;
      } | null> | null;
    } | null> | null;
  } | null> | null;
};

export type FileSetAnnotationSubscriptionVariables = Exact<{
  fileSetId: string | number;
}>;

export type FileSetAnnotationSubscription = {
  fileSetAnnotation: {
    content: string | null;
    fileSetId: string;
    id: string;
    insertedAt: unknown;
    language: Array<string | null> | null;
    model: string | null;
    s3Location: string | null;
    status: string;
    error: string | null;
    type: string;
    updatedAt: unknown;
    aiProvenance: {
      origin: string;
      status: string | null;
      model: string | null;
      reviewer: string | null;
      reviewedAt: unknown;
      generatedAt: unknown;
    } | null;
  } | null;
};

export type WorkFileSetAnnotationSubscriptionVariables = Exact<{
  workId: string | number;
}>;

export type WorkFileSetAnnotationSubscription = {
  workFileSetAnnotation: { status: string; fileSetId: string } | null;
};

export type TranscribeFileSetMutationVariables = Exact<{
  fileSetId: string | number;
  language?: Array<string | null | undefined> | string | null | undefined;
  model?: string | null | undefined;
  context?: string | null | undefined;
}>;

export type TranscribeFileSetMutation = {
  transcribeFileSet: { id: string; status: string } | null;
};

export type UpdateFileSetAnnotationMutationVariables = Exact<{
  annotationId: string | number;
  content: string;
}>;

export type UpdateFileSetAnnotationMutation = {
  updateFileSetAnnotation: {
    content: string | null;
    fileSetId: string;
    id: string;
    insertedAt: unknown;
    language: Array<string | null> | null;
    model: string | null;
    s3Location: string | null;
    status: string;
    type: string;
    updatedAt: unknown;
    aiProvenance: {
      origin: string;
      status: string | null;
      model: string | null;
      reviewer: string | null;
      reviewedAt: unknown;
      generatedAt: unknown;
    } | null;
  } | null;
};

export type UpsertFileSetAnnotationMutationVariables = Exact<{
  fileSetId: string | number;
  type: string;
  content: string;
  language?: Array<string | null | undefined> | string | null | undefined;
}>;

export type UpsertFileSetAnnotationMutation = {
  upsertFileSetAnnotation: {
    content: string | null;
    fileSetId: string;
    id: string;
    insertedAt: unknown;
    language: Array<string | null> | null;
    model: string | null;
    s3Location: string | null;
    status: string;
    type: string;
    updatedAt: unknown;
    aiProvenance: {
      origin: string;
      status: string | null;
      model: string | null;
      reviewer: string | null;
      reviewedAt: unknown;
      generatedAt: unknown;
    } | null;
  } | null;
};

export type AttestHumanAuthoredAnnotationMutationVariables = Exact<{
  annotationId: string | number;
  reason?: string | null | undefined;
}>;

export type AttestHumanAuthoredAnnotationMutation = {
  attestHumanAuthoredAnnotation: {
    id: string;
    fileSetId: string;
    aiProvenance: { origin: string; status: string | null } | null;
  } | null;
};

export type AuthoritiesSearchQueryVariables = Exact<{
  authority: string | number;
  query: string;
  limit?: number | null | undefined;
}>;

export type AuthoritiesSearchQuery = {
  authoritiesSearch: Array<{
    hint: string | null;
    id: string | null;
    label: string | null;
  } | null> | null;
};

export type CodeListQueryQueryVariables = Exact<{
  scheme: CodeListScheme;
}>;

export type CodeListQueryQuery = {
  codeList: Array<{
    id: string | null;
    label: string | null;
    scheme: CodeListScheme | null;
  } | null> | null;
};

export type GeonamesPlaceQueryVariables = Exact<{
  id: string | number;
}>;

export type GeonamesPlaceQuery = { geonamesPlace: unknown };

export type FetchCodedTermLabelQueryQueryVariables = Exact<{
  id: string | number;
  scheme: CodeListScheme;
}>;

export type FetchCodedTermLabelQueryQuery = {
  fetchCodedTermLabel: { label: string | null } | null;
};

export type FetchControlledTermLabelQueryVariables = Exact<{
  id: string | number;
}>;

export type FetchControlledTermLabelQuery = {
  fetchControlledTermLabel: { label: string | null } | null;
};

export type ActionStatesQueryVariables = Exact<{
  objectId: string | number;
}>;

export type ActionStatesQuery = {
  actionStates: Array<{
    action: string | null;
    insertedAt: unknown;
    notes: string | null;
    objectId: string;
    outcome: ActionOutcome | null;
    updatedAt: unknown;
  } | null> | null;
};

export type AddWorkToCollectionMutationVariables = Exact<{
  workId: string | number;
  collectionId: string | number;
}>;

export type AddWorkToCollectionMutation = {
  addWorkToCollection: { id: string } | null;
};

export type CreateSharedLinkMutationVariables = Exact<{
  workId: string | number;
}>;

export type CreateSharedLinkMutation = {
  createSharedLink: {
    expires: unknown;
    sharedLinkId: string;
    workId: string;
  } | null;
};

export type CreateWorkMutationVariables = Exact<{
  accessionNumber: string;
  title?: string | null | undefined;
  workType?: CodedTermInput | null | undefined;
}>;

export type CreateWorkMutation = {
  createWork: {
    accessionNumber: string;
    id: string;
    descriptiveMetadata: { title: string | null } | null;
    workType: { id: string | null; label: string | null } | null;
  } | null;
};

export type DeleteFileSetMutationVariables = Exact<{
  fileSetId: string | number;
}>;

export type DeleteFileSetMutation = { deleteFileSet: { id: string } | null };

export type DeleteWorkMutationVariables = Exact<{
  workId: string | number;
}>;

export type DeleteWorkMutation = {
  deleteWork: {
    id: string;
    descriptiveMetadata: { title: string | null } | null;
    ingestSheet: { id: string; title: string } | null;
    project: { id: string; title: string } | null;
  } | null;
};

export type WorkQueryQueryVariables = Exact<{
  id: string | number;
}>;

export type WorkQueryQuery = {
  work: {
    id: string;
    accessionNumber: string;
    ark: string | null;
    insertedAt: unknown;
    manifestUrl: string | null;
    published: boolean | null;
    representativeImage: string | null;
    updatedAt: unknown;
    aiProvenanceSummary: Array<{
      fieldPath: string;
      targetType: string;
      targetId: string;
      operation: string | null;
      origin: string;
      proposedValue: unknown;
      currentValue: unknown;
      humanOversightLevel: string | null;
      status: string | null;
      activityId: string;
      activityType: string | null;
      aiUseType: string | null;
      model: string | null;
      modelProvider: string | null;
      generatedAt: unknown;
      reviewer: string | null;
      reviewedAt: unknown;
      appliedAt: unknown;
      latestEventType: string | null;
      sourceCount: number | null;
      citationCompleteness: string | null;
      itemProvenance: Array<{
        id: string | null;
        origin: string | null;
      } | null> | null;
    } | null> | null;
    behavior: { id: string | null; label: string | null } | null;
    administrativeMetadata: {
      projectCycle: string | null;
      projectDesc: Array<string | null> | null;
      projectManager: Array<string | null> | null;
      projectName: Array<string | null> | null;
      projectProposer: Array<string | null> | null;
      projectTaskNumber: Array<string | null> | null;
      libraryUnit: { id: string | null; label: string | null } | null;
      preservationLevel: { id: string | null; label: string | null } | null;
      status: { id: string | null; label: string | null } | null;
    } | null;
    collection: { id: string | null; title: string | null } | null;
    descriptiveMetadata: {
      abstract: Array<string | null> | null;
      alternateTitle: Array<string | null> | null;
      boxName: Array<string | null> | null;
      boxNumber: Array<string | null> | null;
      caption: Array<string | null> | null;
      catalogKey: Array<string | null> | null;
      culturalContext: Array<string | null> | null;
      description: Array<string | null> | null;
      folderName: Array<string | null> | null;
      folderNumber: Array<string | null> | null;
      identifier: Array<string | null> | null;
      keywords: Array<string | null> | null;
      legacyIdentifier: Array<string | null> | null;
      physicalDescriptionMaterial: Array<string | null> | null;
      physicalDescriptionSize: Array<string | null> | null;
      provenance: Array<string | null> | null;
      publisher: Array<string | null> | null;
      relatedMaterial: Array<string | null> | null;
      rightsHolder: Array<string | null> | null;
      scopeAndContents: Array<string | null> | null;
      series: Array<string | null> | null;
      source: Array<string | null> | null;
      tableOfContents: Array<string | null> | null;
      termsOfUse: string | null;
      title: string | null;
      contributor: Array<{
        term: { id: string | null; label: string | null } | null;
        role: {
          id: string | null;
          label: string | null;
          scheme: CodeListScheme | null;
        } | null;
      } | null> | null;
      creator: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      dateCreated: Array<{
        edtf: string | null;
        humanized: string | null;
      } | null> | null;
      genre: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      language: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      license: { id: string | null; label: string | null } | null;
      location: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      notes: Array<{
        note: string | null;
        type: {
          id: string | null;
          label: string | null;
          scheme: CodeListScheme | null;
        } | null;
      } | null> | null;
      relatedUrl: Array<{
        url: string | null;
        label: {
          id: string | null;
          label: string | null;
          scheme: CodeListScheme | null;
        } | null;
      } | null> | null;
      rightsStatement: { id: string | null; label: string | null } | null;
      stylePeriod: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      subject: Array<{
        term: { id: string | null; label: string | null } | null;
        role: {
          id: string | null;
          label: string | null;
          scheme: CodeListScheme | null;
        } | null;
      } | null> | null;
      technique: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
    } | null;
    fileSets: Array<{
      id: string;
      accessionNumber: string;
      extractedMetadata: string | null;
      groupWith: string | null;
      insertedAt: unknown;
      representativeImageUrl: string | null;
      streamingUrl: string | null;
      updatedAt: unknown;
      annotations: Array<{
        id: string;
        type: string;
        status: string;
        language: Array<string | null> | null;
        content: string | null;
        aiProvenance: {
          origin: string;
          status: string | null;
          model: string | null;
          reviewer: string | null;
          reviewedAt: unknown;
          generatedAt: unknown;
        } | null;
      } | null> | null;
      coreMetadata: {
        altText: string | null;
        description: string | null;
        imageCaption: string | null;
        label: string | null;
        location: string | null;
        mimeType: string | null;
        originalFilename: string | null;
        digests: {
          md5: string | null;
          sha1: string | null;
          sha256: string | null;
        } | null;
      } | null;
      role: { id: string | null; label: string | null };
      structuralMetadata: {
        type: StructuralMetadataType | null;
        value: string | null;
      } | null;
    } | null> | null;
    ingestSheet: { id: string; title: string } | null;
    project: { id: string; title: string } | null;
    visibility: { id: string | null; label: string | null } | null;
    workType: { id: string | null; label: string | null } | null;
  } | null;
};

export type WorksQueryQueryVariables = Exact<{ [key: string]: never }>;

export type WorksQueryQuery = {
  works: Array<{
    id: string;
    accessionNumber: string;
    insertedAt: unknown;
    manifestUrl: string | null;
    published: boolean | null;
    representativeImage: string | null;
    updatedAt: unknown;
    descriptiveMetadata: {
      title: string | null;
      description: Array<string | null> | null;
    } | null;
    fileSets: Array<{
      id: string;
      accessionNumber: string;
      representativeImageUrl: string | null;
      insertedAt: unknown;
      updatedAt: unknown;
      role: { id: string | null; label: string | null };
      annotations: Array<{
        id: string;
        type: string;
        status: string;
        language: Array<string | null> | null;
        content: string | null;
        aiProvenance: {
          origin: string;
          status: string | null;
          model: string | null;
          reviewer: string | null;
          reviewedAt: unknown;
          generatedAt: unknown;
        } | null;
      } | null> | null;
      coreMetadata: {
        altText: string | null;
        description: string | null;
        imageCaption: string | null;
        originalFilename: string | null;
        location: string | null;
        label: string | null;
        digests: {
          md5: string | null;
          sha1: string | null;
          sha256: string | null;
        } | null;
      } | null;
    } | null> | null;
    project: { id: string; title: string } | null;
    ingestSheet: { id: string; title: string } | null;
    workType: { id: string | null; label: string | null } | null;
    visibility: { id: string | null; label: string | null } | null;
  } | null> | null;
};

export type GetWorkTypesQueryVariables = Exact<{ [key: string]: never }>;

export type GetWorkTypesQuery = {
  codeList: Array<{
    id: string | null;
    label: string | null;
    scheme: CodeListScheme | null;
  } | null> | null;
};

export type ReplaceFileSetMutationVariables = Exact<{
  id: string | number;
  coreMetadata: FileSetCoreMetadataInput;
}>;

export type ReplaceFileSetMutation = {
  replaceFileSet: {
    id: string;
    coreMetadata: {
      description: string | null;
      label: string | null;
      location: string | null;
      originalFilename: string | null;
    } | null;
  } | null;
};

export type ListIngestBucketObjectsQueryVariables = Exact<{
  prefix?: string | null | undefined;
}>;

export type ListIngestBucketObjectsQuery = {
  listIngestBucketObjects: {
    folders: Array<string | null> | null;
    objects: Array<{
      uri: string | null;
      key: string | null;
      storageClass: string | null;
      size: string | null;
      lastModified: string | null;
      mimeType: string | null;
    } | null> | null;
  } | null;
};

export type SetWorkImageMutationVariables = Exact<{
  fileSetId: string | number;
  workId: string | number;
}>;

export type SetWorkImageMutation = {
  setWorkImage: { id: string; representativeImage: string | null } | null;
};

export type AttestHumanAuthoredMetadataMutationVariables = Exact<{
  workId: string | number;
  fieldPaths: Array<string> | string;
  itemIds?: Array<string> | string | null | undefined;
  reason?: string | null | undefined;
}>;

export type AttestHumanAuthoredMetadataMutation = {
  attestHumanAuthoredMetadata: { id: string } | null;
};

export type UpdateWorkMutationVariables = Exact<{
  id: string | number;
  work: WorkUpdateInput;
}>;

export type UpdateWorkMutation = {
  updateWork: {
    id: string;
    insertedAt: unknown;
    published: boolean | null;
    administrativeMetadata: {
      libraryUnit: { id: string | null; label: string | null } | null;
      preservationLevel: { id: string | null; label: string | null } | null;
      status: { id: string | null; label: string | null } | null;
    } | null;
    collection: { title: string | null; id: string | null } | null;
    descriptiveMetadata: {
      culturalContext: Array<string | null> | null;
      description: Array<string | null> | null;
      title: string | null;
      termsOfUse: string | null;
      contributor: Array<{
        term: { id: string | null; label: string | null } | null;
        role: {
          id: string | null;
          label: string | null;
          scheme: CodeListScheme | null;
        } | null;
      } | null> | null;
      creator: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      dateCreated: Array<{
        edtf: string | null;
        humanized: string | null;
      } | null> | null;
      genre: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      language: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      license: { id: string | null; label: string | null } | null;
      location: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      rightsStatement: { id: string | null; label: string | null } | null;
      stylePeriod: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
      subject: Array<{
        term: { id: string | null; label: string | null } | null;
        role: {
          id: string | null;
          label: string | null;
          scheme: CodeListScheme | null;
        } | null;
      } | null> | null;
      technique: Array<{
        term: { id: string | null; label: string | null } | null;
      } | null> | null;
    } | null;
    workType: { id: string | null; label: string | null } | null;
    visibility: { id: string | null; label: string | null } | null;
    behavior: { id: string | null; label: string | null } | null;
  } | null;
};

export type IngestFileSetMutationVariables = Exact<{
  accession_number: string;
  role: CodedTermInput;
  coreMetadata: FileSetCoreMetadataInput;
  workId: string | number;
}>;

export type IngestFileSetMutation = {
  ingestFileSet: {
    id: string;
    accessionNumber: string;
    role: { id: string | null; label: string | null };
    work: { id: string } | null;
    coreMetadata: {
      location: string | null;
      label: string | null;
      description: string | null;
      originalFilename: string | null;
      digests: {
        md5: string | null;
        sha1: string | null;
        sha256: string | null;
      } | null;
    } | null;
  } | null;
};

export type UpdateAccessFileOrderMutationVariables = Exact<{
  workId: string | number;
  fileSetIds?:
    | Array<string | number | null | undefined>
    | string
    | number
    | null
    | undefined;
}>;

export type UpdateAccessFileOrderMutation = {
  updateAccessFileOrder: { id: string } | null;
};

export type TransferFileSetsMutationVariables = Exact<{
  fromWorkId: string | number;
  toWorkId: string | number;
}>;

export type TransferFileSetsMutation = {
  transferFileSets: { id: string } | null;
};

export type TransferFileSetsSubsetMutationVariables = Exact<{
  filesetIds: Array<string | number> | string | number;
  createWork: boolean;
  accessionNumber?: string | null | undefined;
  workAttributes?: WorkAttributesInput | null | undefined;
  deleteEmptyWorks?: boolean | null | undefined;
}>;

export type TransferFileSetsSubsetMutation = {
  transferFileSetsSubset: {
    transferredFilesetIds: Array<string | null>;
    createdWorkId: string | null;
  } | null;
};

export type WorkArchiverEndpointQueryVariables = Exact<{
  [key: string]: never;
}>;

export type WorkArchiverEndpointQuery = {
  workArchiverEndpoint: { url: string } | null;
};

export type UpdateFileSetMutationVariables = Exact<{
  id: string | number;
  coreMetadata?: FileSetCoreMetadataUpdate | null | undefined;
  posterOffset?: number | null | undefined;
  structuralMetadata?: FileSetStructuralMetadataInput | null | undefined;
}>;

export type UpdateFileSetMutation = { updateFileSet: { id: string } | null };

export type UpdateFileSetsMutationVariables = Exact<{
  fileSets: Array<FileSetUpdate | null | undefined> | FileSetUpdate;
}>;

export type UpdateFileSetsMutation = {
  updateFileSets: Array<{
    id: string;
    coreMetadata: { description: string | null; label: string | null } | null;
  } | null> | null;
};

export type GroupWithFileSetMutationVariables = Exact<{
  id: string | number;
  groupWith?: string | number | null | undefined;
}>;

export type GroupWithFileSetMutation = {
  updateFileSet: { id: string; groupWith: string | null } | null;
};

export type VerifyFileSetsQueryVariables = Exact<{
  workId: string | number;
}>;

export type VerifyFileSetsQuery = {
  verifyFileSets: Array<{
    fileSetId: string | null;
    verified: boolean | null;
  } | null> | null;
};

export type DcApiTokenQueryVariables = Exact<{ [key: string]: never }>;

export type DcApiTokenQuery = {
  dcApiToken: { expires: unknown; token: string } | null;
};

export const IngestSheetPartsFragmentDoc = {
  kind: "Document",
  definitions: [
    {
      kind: "FragmentDefinition",
      name: { kind: "Name", value: "IngestSheetParts" },
      typeCondition: {
        kind: "NamedType",
        name: { kind: "Name", value: "IngestSheet" },
      },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          { kind: "Field", name: { kind: "Name", value: "fileErrors" } },
          { kind: "Field", name: { kind: "Name", value: "filename" } },
          { kind: "Field", name: { kind: "Name", value: "id" } },
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetRows" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "errors" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "field" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "message" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "fields" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "header" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "value" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "row" } },
                { kind: "Field", name: { kind: "Name", value: "state" } },
              ],
            },
          },
          {
            kind: "Field",
            name: { kind: "Name", value: "state" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "state" } },
              ],
            },
          },
          { kind: "Field", name: { kind: "Name", value: "status" } },
          { kind: "Field", name: { kind: "Name", value: "title" } },
        ],
      },
    },
  ],
} as unknown as DocumentNode<IngestSheetPartsFragment, unknown>;
export const GetCurrentUserDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetCurrentUser" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "me" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "username" } },
                { kind: "Field", name: { kind: "Name", value: "email" } },
                { kind: "Field", name: { kind: "Name", value: "role" } },
                { kind: "Field", name: { kind: "Name", value: "displayName" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetCurrentUserQuery, GetCurrentUserQueryVariables>;
export const ListRolesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "ListRoles" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [{ kind: "Field", name: { kind: "Name", value: "roles" } }],
      },
    },
  ],
} as unknown as DocumentNode<ListRolesQuery, ListRolesQueryVariables>;
export const ListUsersDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "ListUsers" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "users" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "username" } },
                { kind: "Field", name: { kind: "Name", value: "email" } },
                { kind: "Field", name: { kind: "Name", value: "role" } },
                { kind: "Field", name: { kind: "Name", value: "displayName" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<ListUsersQuery, ListUsersQueryVariables>;
export const SetUserRoleDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "SetUserRole" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "userId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "userRole" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "UserRole" },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "setUserRole" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "userId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "userId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "userRole" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "userRole" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "message" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<SetUserRoleMutation, SetUserRoleMutationVariables>;
export const BatchUpdateDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "BatchUpdate" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "add" } },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "BatchAddInput" },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "delete" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "BatchDeleteInput" },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "query" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "replace" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "BatchReplaceInput" },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "nickname" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "batchUpdate" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "add" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "add" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "delete" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "delete" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "query" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "query" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "replace" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "replace" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "nickname" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "nickname" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "nickname" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
                { kind: "Field", name: { kind: "Name", value: "started" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "query" } },
                { kind: "Field", name: { kind: "Name", value: "add" } },
                { kind: "Field", name: { kind: "Name", value: "replace" } },
                { kind: "Field", name: { kind: "Name", value: "delete" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<BatchUpdateMutation, BatchUpdateMutationVariables>;
export const BatchDeleteDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "BatchDelete" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "query" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "nickname" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "batchDelete" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "query" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "query" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "nickname" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "nickname" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "nickname" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
                { kind: "Field", name: { kind: "Name", value: "started" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "query" } },
                { kind: "Field", name: { kind: "Name", value: "add" } },
                { kind: "Field", name: { kind: "Name", value: "replace" } },
                { kind: "Field", name: { kind: "Name", value: "delete" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<BatchDeleteMutation, BatchDeleteMutationVariables>;
export const CreateCollectionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateCollection" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "adminEmail" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "collectionTitle" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "description" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "featured" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Boolean" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "findingAidUrl" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "keywords" },
          },
          type: {
            kind: "ListType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "published" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Boolean" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "visibility" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "CodedTermInput" },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createCollection" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "adminEmail" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "adminEmail" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "description" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "description" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "featured" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "featured" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "findingAidUrl" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "findingAidUrl" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "keywords" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "keywords" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "published" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "published" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "title" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "collectionTitle" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "visibility" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "visibility" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "adminEmail" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "featured" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "findingAidUrl" },
                },
                { kind: "Field", name: { kind: "Name", value: "keywords" } },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateCollectionMutation,
  CreateCollectionMutationVariables
>;
export const SetCollectionImageDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "SetCollectionImage" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "collectionId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "setCollectionImage" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "collectionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "collectionId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeWork" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "representativeImage" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  SetCollectionImageMutation,
  SetCollectionImageMutationVariables
>;
export const DeleteCollectionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "DeleteCollection" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "collectionId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteCollection" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "collectionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "collectionId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteCollectionMutation,
  DeleteCollectionMutationVariables
>;
export const GetCollectionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetCollection" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "collection" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "collectionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "adminEmail" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "featured" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "findingAidUrl" },
                },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "keywords" } },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeWork" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "representativeImage" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "stats" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "audio" } },
                      { kind: "Field", name: { kind: "Name", value: "image" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "published" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "total" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "unpublished" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "video" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "totalWorks" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetCollectionQuery, GetCollectionQueryVariables>;
export const GetCollectionsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetCollections" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "collections" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "adminEmail" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "featured" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "findingAidUrl" },
                },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "keywords" } },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeWork" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "representativeImage" },
                      },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "totalWorks" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetCollectionsQuery, GetCollectionsQueryVariables>;
export const UpdateCollectionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateCollection" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "adminEmail" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "collectionId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "collectionTitle" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "description" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "featured" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Boolean" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "findingAidUrl" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "keywords" },
          },
          type: {
            kind: "ListType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "published" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Boolean" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "visibility" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "CodedTermInput" },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateCollection" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "adminEmail" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "adminEmail" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "collectionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "collectionId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "description" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "description" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "featured" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "featured" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "findingAidUrl" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "findingAidUrl" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "keywords" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "keywords" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "published" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "published" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "title" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "collectionTitle" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "visibility" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "visibility" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "adminEmail" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "featured" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "findingAidUrl" },
                },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "keywords" } },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateCollectionMutation,
  UpdateCollectionMutationVariables
>;
export const GetEvalQueryListDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetEvalQueryList" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "evalQueryList" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "queryJson" } },
                { kind: "Field", name: { kind: "Name", value: "author" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetEvalQueryListQuery,
  GetEvalQueryListQueryVariables
>;
export const GetDefaultEvalQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetDefaultEvalQuery" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "defaultEvalQuery" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "queryJson" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetDefaultEvalQueryQuery,
  GetDefaultEvalQueryQueryVariables
>;
export const GetEvalPromptVersionsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetEvalPromptVersions" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "evalPromptVersions" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "subjectPrompt" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptionPrompt" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "systemPrompt" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "userPromptTemplate" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "parentVersionId" },
                },
                { kind: "Field", name: { kind: "Name", value: "author" } },
                { kind: "Field", name: { kind: "Name", value: "changeNotes" } },
                { kind: "Field", name: { kind: "Name", value: "archived" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetEvalPromptVersionsQuery,
  GetEvalPromptVersionsQueryVariables
>;
export const GetEvalSetsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetEvalSets" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "evalSets" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "workCount" } },
                { kind: "Field", name: { kind: "Name", value: "author" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetEvalSetsQuery, GetEvalSetsQueryVariables>;
export const GetEvalRunsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetEvalRuns" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "offset" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "evalRuns" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "offset" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "offset" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "trialsPerWork" },
                },
                { kind: "Field", name: { kind: "Name", value: "author" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "completedAt" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "evalSet" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "name" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "workCount" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "promptVersion" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "name" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "summary" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "total" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "complete" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "errored" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "pending" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualGood" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualBad" },
                      },
                      {
                        kind: "Field",
                        name: {
                          kind: "Name",
                          value: "meanDescriptionJudgeScore",
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "meanSubjectsJudgeScore" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetEvalRunsQuery, GetEvalRunsQueryVariables>;
export const GetEvalRunDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetEvalRun" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "evalRun" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "trialsPerWork" },
                },
                { kind: "Field", name: { kind: "Name", value: "author" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "completedAt" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "evalSet" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "name" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "workCount" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "evalSetMembers" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "workId" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "accessionNumber" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "groundTruth" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "promptVersion" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "name" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "subjectPrompt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "descriptionPrompt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "systemPrompt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "userPromptTemplate" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "summary" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "total" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "complete" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "errored" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "pending" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "running" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualGood" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualBad" },
                      },
                      {
                        kind: "Field",
                        name: {
                          kind: "Name",
                          value: "meanDescriptionJudgeScore",
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "meanSubjectsJudgeScore" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "evalTrials" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "workId" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "trialIndex" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "descriptionJudgeScore" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "subjectsJudgeScore" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "judgeRationale" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualScore" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualNotes" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualScoredBy" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "manualScoredAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "durationMs" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "error" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "agentOutput" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "updatedAt" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetEvalRunQuery, GetEvalRunQueryVariables>;
export const CreateEvalQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateEvalQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "name" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "description" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "queryJson" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "Json" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createEvalQuery" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "name" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "name" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "description" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "description" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "queryJson" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "queryJson" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "queryJson" } },
                { kind: "Field", name: { kind: "Name", value: "author" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateEvalQueryMutation,
  CreateEvalQueryMutationVariables
>;
export const UpdateEvalQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateEvalQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "name" } },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "description" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "queryJson" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Json" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateEvalQuery" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "name" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "name" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "description" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "description" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "queryJson" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "queryJson" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "queryJson" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateEvalQueryMutation,
  UpdateEvalQueryMutationVariables
>;
export const DeleteEvalQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "DeleteEvalQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteEvalQuery" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteEvalQueryMutation,
  DeleteEvalQueryMutationVariables
>;
export const CreateEvalPromptVersionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateEvalPromptVersion" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "name" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "subjectPrompt" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "descriptionPrompt" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "parentVersionId" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "changeNotes" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createEvalPromptVersion" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "name" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "name" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "subjectPrompt" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "subjectPrompt" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "descriptionPrompt" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "descriptionPrompt" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "parentVersionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "parentVersionId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "changeNotes" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "changeNotes" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "archived" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateEvalPromptVersionMutation,
  CreateEvalPromptVersionMutationVariables
>;
export const ArchiveEvalPromptVersionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "ArchiveEvalPromptVersion" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "archiveEvalPromptVersion" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "archived" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ArchiveEvalPromptVersionMutation,
  ArchiveEvalPromptVersionMutationVariables
>;
export const CreateEvalSetFromWorkIdsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateEvalSetFromWorkIds" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workIds" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "ListType",
              type: {
                kind: "NonNullType",
                type: {
                  kind: "NamedType",
                  name: { kind: "Name", value: "ID" },
                },
              },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "name" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "description" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createEvalSetFromWorkIds" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workIds" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workIds" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "name" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "name" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "description" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "description" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "workCount" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateEvalSetFromWorkIdsMutation,
  CreateEvalSetFromWorkIdsMutationVariables
>;
export const CreateEvalSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateEvalSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "queryId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "name" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "description" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createEvalSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "queryId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "queryId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "name" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "name" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "description" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "description" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "workCount" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateEvalSetMutation,
  CreateEvalSetMutationVariables
>;
export const CreateEvalRunDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateEvalRun" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "evalSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "promptVersionId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "name" } },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "trialsPerWork" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "concurrency" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createEvalRun" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "evalSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "evalSetId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "promptVersionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "promptVersionId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "name" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "name" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "trialsPerWork" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "trialsPerWork" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "concurrency" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "concurrency" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "name" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateEvalRunMutation,
  CreateEvalRunMutationVariables
>;
export const CancelEvalRunDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CancelEvalRun" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "cancelEvalRun" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CancelEvalRunMutation,
  CancelEvalRunMutationVariables
>;
export const ScoreEvalTrialDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "ScoreEvalTrial" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "score" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "EvalManualScore" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "notes" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "scoreEvalTrial" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "score" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "score" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "notes" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "notes" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "manualScore" } },
                { kind: "Field", name: { kind: "Name", value: "manualNotes" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "manualScoredBy" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "manualScoredAt" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ScoreEvalTrialMutation,
  ScoreEvalTrialMutationVariables
>;
export const ClearEvalTrialScoreDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "ClearEvalTrialScore" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "clearEvalTrialScore" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "manualScore" } },
                { kind: "Field", name: { kind: "Name", value: "manualNotes" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ClearEvalTrialScoreMutation,
  ClearEvalTrialScoreMutationVariables
>;
export const GetAiActivitiesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetAIActivities" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "activityType" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "aiUseType" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "status" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "aiActivities" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "activityType" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "activityType" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "aiUseType" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "aiUseType" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "status" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "status" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "activityType" },
                },
                { kind: "Field", name: { kind: "Name", value: "aiUseType" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "model" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "modelProvider" },
                },
                { kind: "Field", name: { kind: "Name", value: "workId" } },
                { kind: "Field", name: { kind: "Name", value: "costUsd" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "completedAt" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetAiActivitiesQuery,
  GetAiActivitiesQueryVariables
>;
export const GetAiActivityDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetAIActivity" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "aiActivity" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "activityType" },
                },
                { kind: "Field", name: { kind: "Name", value: "aiUseType" } },
                { kind: "Field", name: { kind: "Name", value: "accessMode" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "reversibility" },
                },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
                { kind: "Field", name: { kind: "Name", value: "model" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "modelProvider" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "modelVersion" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "promptVersion" },
                },
                { kind: "Field", name: { kind: "Name", value: "costUsd" } },
                { kind: "Field", name: { kind: "Name", value: "workId" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                { kind: "Field", name: { kind: "Name", value: "planId" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "completedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "sources" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "itemType" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "itemId" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "collectionTitle" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "holdingOrganization" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "accessLink" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "restricted" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "targets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "targetType" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "fieldPath" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "operation" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "proposedValue" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "events" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "eventType" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "actor" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "occurredAt" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "outcome" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "notes" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "agentLinks" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "role" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "agent" },
                                    selectionSet: {
                                      kind: "SelectionSet",
                                      selections: [
                                        {
                                          kind: "Field",
                                          name: { kind: "Name", value: "id" },
                                        },
                                        {
                                          kind: "Field",
                                          name: {
                                            kind: "Name",
                                            value: "agentType",
                                          },
                                        },
                                        {
                                          kind: "Field",
                                          name: { kind: "Name", value: "name" },
                                        },
                                        {
                                          kind: "Field",
                                          name: {
                                            kind: "Name",
                                            value: "version",
                                          },
                                        },
                                      ],
                                    },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetAiActivityQuery, GetAiActivityQueryVariables>;
export const CsvMetadataUpdateDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CsvMetadataUpdate" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "filename" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "source" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "csvMetadataUpdate" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "filename" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "filename" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "source" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "source" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "errors" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "errors" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "field" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "messages" },
                            },
                          ],
                        },
                      },
                      { kind: "Field", name: { kind: "Name", value: "row" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "rows" } },
                { kind: "Field", name: { kind: "Name", value: "source" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CsvMetadataUpdateMutation,
  CsvMetadataUpdateMutationVariables
>;
export const CreateNulAuthorityRecordDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "createNulAuthorityRecord" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "hint" } },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "label" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createNulAuthorityRecord" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "hint" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "hint" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "label" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "label" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "hint" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateNulAuthorityRecordMutation,
  CreateNulAuthorityRecordMutationVariables
>;
export const DeleteNulAuthorityRecordDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "DeleteNulAuthorityRecord" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteNulAuthorityRecord" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "nulAuthorityRecordId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteNulAuthorityRecordMutation,
  DeleteNulAuthorityRecordMutationVariables
>;
export const BatchDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "batch" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "batch" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "add" } },
                { kind: "Field", name: { kind: "Name", value: "delete" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "nickname" } },
                { kind: "Field", name: { kind: "Name", value: "query" } },
                { kind: "Field", name: { kind: "Name", value: "replace" } },
                { kind: "Field", name: { kind: "Name", value: "started" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "worksUpdated" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<BatchQuery, BatchQueryVariables>;
export const BatchesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "batches" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "batches" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "add" } },
                { kind: "Field", name: { kind: "Name", value: "delete" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "nickname" } },
                { kind: "Field", name: { kind: "Name", value: "query" } },
                { kind: "Field", name: { kind: "Name", value: "replace" } },
                { kind: "Field", name: { kind: "Name", value: "started" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "worksUpdated" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<BatchesQuery, BatchesQueryVariables>;
export const PreservationChecksDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "preservationChecks" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "preservationChecks" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "invalidRows" } },
                { kind: "Field", name: { kind: "Name", value: "location" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  PreservationChecksQuery,
  PreservationChecksQueryVariables
>;
export const CsvMetadataUpdateJobDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "CsvMetadataUpdateJob" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "csvMetadataUpdateJob" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "errors" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "errors" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "field" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "messages" },
                            },
                          ],
                        },
                      },
                      { kind: "Field", name: { kind: "Name", value: "row" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "rows" } },
                { kind: "Field", name: { kind: "Name", value: "source" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CsvMetadataUpdateJobQuery,
  CsvMetadataUpdateJobQueryVariables
>;
export const CsvMetadataUpdateJobsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "CsvMetadataUpdateJobs" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "csvMetadataUpdateJobs" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "errors" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "errors" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "field" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "messages" },
                            },
                          ],
                        },
                      },
                      { kind: "Field", name: { kind: "Name", value: "row" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "rows" } },
                { kind: "Field", name: { kind: "Name", value: "source" } },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                { kind: "Field", name: { kind: "Name", value: "user" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CsvMetadataUpdateJobsQuery,
  CsvMetadataUpdateJobsQueryVariables
>;
export const NulAuthorityRecordsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "NulAuthorityRecords" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "nulAuthorityRecords" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "hint" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  NulAuthorityRecordsQuery,
  NulAuthorityRecordsQueryVariables
>;
export const UpdateNulAuthorityRecordDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateNulAuthorityRecord" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "hint" } },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "label" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateNulAuthorityRecord" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "hint" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "hint" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "label" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "label" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "hint" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateNulAuthorityRecordMutation,
  UpdateNulAuthorityRecordMutationVariables
>;
export const ListObsoleteControlledTermsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "ListObsoleteControlledTerms" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "obsoleteControlledTerms" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
                { kind: "Field", name: { kind: "Name", value: "replacedBy" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "replacementLabel" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ListObsoleteControlledTermsQuery,
  ListObsoleteControlledTermsQueryVariables
>;
export const IiifServerUrlDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IiifServerUrl" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "iiifServerUrl" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "url" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<IiifServerUrlQuery, IiifServerUrlQueryVariables>;
export const CreateIngestSheetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateIngestSheet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "title" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "filename" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "aiIngest" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Boolean" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createIngestSheet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "title" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "title" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "projectId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "filename" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "filename" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "aiIngest" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "aiIngest" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "aiIngest" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "project" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateIngestSheetMutation,
  CreateIngestSheetMutationVariables
>;
export const DeleteIngestSheetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "DeleteIngestSheet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "sheetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteIngestSheet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "sheetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "sheetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteIngestSheetMutation,
  DeleteIngestSheetMutationVariables
>;
export const GetPresignedUrlDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetPresignedUrl" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "uploadType" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "S3UploadType" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "filename" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "presignedUrl" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "uploadType" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "uploadType" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "filename" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "filename" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "url" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetPresignedUrlQuery,
  GetPresignedUrlQueryVariables
>;
export const OnIngestProgressDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "OnIngestProgress" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "sheetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestProgress" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "sheetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "sheetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "totalFileSets" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "completedFileSets" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "percentComplete" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  OnIngestProgressSubscription,
  OnIngestProgressSubscriptionVariables
>;
export const IngestSheetCompletedErrorsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IngestSheetCompletedErrors" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetErrors" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "accessionNumber" },
                },
                { kind: "Field", name: { kind: "Name", value: "action" } },
                { kind: "Field", name: { kind: "Name", value: "description" } },
                { kind: "Field", name: { kind: "Name", value: "errors" } },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "outcome" } },
                { kind: "Field", name: { kind: "Name", value: "role" } },
                { kind: "Field", name: { kind: "Name", value: "rowNumber" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "workAccessionNumber" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetCompletedErrorsQuery,
  IngestSheetCompletedErrorsQueryVariables
>;
export const IngestSheetQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IngestSheetQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "sheetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "sheetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "aiIngest" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiCostActual" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiCostEstimate" },
                },
                { kind: "Field", name: { kind: "Name", value: "aiPreview" } },
                { kind: "Field", name: { kind: "Name", value: "fileErrors" } },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "state" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "name" } },
                      { kind: "Field", name: { kind: "Name", value: "state" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetQueryQuery,
  IngestSheetQueryQueryVariables
>;
export const IngestSheetRowValidationErrorsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IngestSheetRowValidationErrors" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "sheetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "state" },
          },
          type: {
            kind: "ListType",
            type: { kind: "NamedType", name: { kind: "Name", value: "State" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetRows" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "sheetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "sheetId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "state" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "state" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "row" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "fields" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "header" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "value" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "errors" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "field" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "message" },
                      },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "state" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetRowValidationErrorsQuery,
  IngestSheetRowValidationErrorsQueryVariables
>;
export const OnIngestSheetUpdateDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "OnIngestSheetUpdate" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "sheetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetUpdate" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "sheetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "sheetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "aiIngest" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiCostActual" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiCostEstimate" },
                },
                { kind: "Field", name: { kind: "Name", value: "aiPreview" } },
                { kind: "Field", name: { kind: "Name", value: "fileErrors" } },
                { kind: "Field", name: { kind: "Name", value: "filename" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "state" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "name" } },
                      { kind: "Field", name: { kind: "Name", value: "state" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  OnIngestSheetUpdateSubscription,
  OnIngestSheetUpdateSubscriptionVariables
>;
export const IngestSheetValidationProgressDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IngestSheetValidationProgress" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "sheetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetValidationProgress" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "sheetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "percentComplete" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetValidationProgressQuery,
  IngestSheetValidationProgressQueryVariables
>;
export const IngestSheetWorkCountDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IngestSheetWorkCount" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetWorkCount" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "totalWorks" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "totalFileSets" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "appendedFileSets" },
                },
                { kind: "Field", name: { kind: "Name", value: "pass" } },
                { kind: "Field", name: { kind: "Name", value: "fail" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetWorkCountQuery,
  IngestSheetWorkCountQueryVariables
>;
export const IngestSheetWorksDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "IngestSheetWorks" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetWorks" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "accessionNumber" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptiveMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "fileSets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "role" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "accessionNumber" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "coreMetadata" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "description" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "originalFilename" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "location" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "manifestUrl" } },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeImage" },
                },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "workType" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetWorksQuery,
  IngestSheetWorksQueryVariables
>;
export const GetIngestSheetsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetIngestSheets" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "project" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "updatedAt" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetIngestSheetsQuery,
  GetIngestSheetsQueryVariables
>;
export const ValidateIngestSheetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "ValidateIngestSheet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "validateIngestSheet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "sheetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "message" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ValidateIngestSheetMutation,
  ValidateIngestSheetMutationVariables
>;
export const ChatResponseDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "ChatResponse" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "conversationId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "chatResponse" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "conversationId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "conversationId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "conversationId" },
                },
                { kind: "Field", name: { kind: "Name", value: "message" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "planId" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ChatResponseSubscription,
  ChatResponseSubscriptionVariables
>;
export const SendChatMessageDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "SendChatMessage" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "conversationId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "type" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "prompt" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "query" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "sendChatMessage" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "conversationId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "conversationId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "type" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "type" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "prompt" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "prompt" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "query" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "query" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "conversationId" },
                },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "prompt" } },
                { kind: "Field", name: { kind: "Name", value: "query" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  SendChatMessageMutation,
  SendChatMessageMutationVariables
>;
export const PlanChangesUpdatedDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "PlanChangesUpdated" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "planId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "planChangesUpdated" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "planId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "planId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "planId" } },
                { kind: "Field", name: { kind: "Name", value: "action" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "planChange" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "add" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "replace" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "delete" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  PlanChangesUpdatedSubscription,
  PlanChangesUpdatedSubscriptionVariables
>;
export const PlanUpdatedDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "PlanUpdated" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "planId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "planUpdated" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "planId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "planId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  PlanUpdatedSubscription,
  PlanUpdatedSubscriptionVariables
>;
export const PlanDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "plan" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "plan" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "prompt" } },
                { kind: "Field", name: { kind: "Name", value: "query" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<PlanQuery, PlanQueryVariables>;
export const PlanChangesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "planChanges" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "planId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "planChanges" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "planId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "planId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "add" } },
                { kind: "Field", name: { kind: "Name", value: "delete" } },
                { kind: "Field", name: { kind: "Name", value: "replace" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<PlanChangesQuery, PlanChangesQueryVariables>;
export const PlanChangeProvenanceDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "planChangeProvenance" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "planChangeId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "aiActivities" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "planChangeId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "planChangeId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "targets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "fieldPath" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "operation" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "proposedValue" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "itemProvenance" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "origin" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "events" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "eventType" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "valueAfter" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  PlanChangeProvenanceQuery,
  PlanChangeProvenanceQueryVariables
>;
export const UpdatePlanStatusDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "updatePlanStatus" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "status" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "PlanStatus" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updatePlanStatus" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "status" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "status" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdatePlanStatusMutation,
  UpdatePlanStatusMutationVariables
>;
export const UpdatePlanChangeStatusDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "updatePlanChangeStatus" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "status" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "PlanStatus" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updatePlanChangeStatus" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "status" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "status" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdatePlanChangeStatusMutation,
  UpdatePlanChangeStatusMutationVariables
>;
export const UpdatePlanChangeDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "updatePlanChange" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "add" } },
          type: { kind: "NamedType", name: { kind: "Name", value: "Json" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "replace" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Json" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "delete" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Json" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updatePlanChange" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "add" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "add" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "replace" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "replace" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "delete" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "delete" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "add" } },
                { kind: "Field", name: { kind: "Name", value: "replace" } },
                { kind: "Field", name: { kind: "Name", value: "delete" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdatePlanChangeMutation,
  UpdatePlanChangeMutationVariables
>;
export const DeletePlanChangeDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "deletePlanChange" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "planChangeId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deletePlanChange" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "planChangeId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "planChangeId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeletePlanChangeMutation,
  DeletePlanChangeMutationVariables
>;
export const UpdateProposedPlanChangeStatusesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "updateProposedPlanChangeStatuses" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "planId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "status" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "PlanStatus" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateProposedPlanChangeStatuses" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "planId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "planId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "status" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "status" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "planId" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateProposedPlanChangeStatusesMutation,
  UpdateProposedPlanChangeStatusesMutationVariables
>;
export const ApplyPlanDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "applyPlan" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "applyPlan" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "completedAt" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<ApplyPlanMutation, ApplyPlanMutationVariables>;
export const CreateProjectDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateProject" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectTitle" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createProject" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "title" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectTitle" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "folder" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateProjectMutation,
  CreateProjectMutationVariables
>;
export const UpdateProjectDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateProject" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectTitle" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateProject" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "title" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectTitle" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "folder" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateProjectMutation,
  UpdateProjectMutationVariables
>;
export const DeleteProjectDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "DeleteProject" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteProject" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "projectId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteProjectMutation,
  DeleteProjectMutationVariables
>;
export const GetProjectDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetProject" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "project" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "folder" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "updatedAt" },
                      },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetProjectQuery, GetProjectQueryVariables>;
export const GetProjectsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetProjects" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "projects" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "folder" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetProjectsQuery, GetProjectsQueryVariables>;
export const ProjectsSearchDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "ProjectsSearch" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "query" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "projectsSearch" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "query" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "query" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "folder" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<ProjectsSearchQuery, ProjectsSearchQueryVariables>;
export const IngestSheetUpdatesForProjectDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "IngestSheetUpdatesForProject" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "projectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestSheetUpdatesForProject" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "projectId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "projectId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "title" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestSheetUpdatesForProjectSubscription,
  IngestSheetUpdatesForProjectSubscriptionVariables
>;
export const AssumeRoleDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "AssumeRole" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "userRole" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "UserRole" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "assumeRole" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "userRole" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "userRole" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "message" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<AssumeRoleMutation, AssumeRoleMutationVariables>;
export const DigitalCollectionsUrlDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "DigitalCollectionsUrl" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "digitalCollectionsUrl" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "url" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DigitalCollectionsUrlQuery,
  DigitalCollectionsUrlQueryVariables
>;
export const DcapiEndpointDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "DcapiEndpoint" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "dcapiEndpoint" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "url" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<DcapiEndpointQuery, DcapiEndpointQueryVariables>;
export const LivebookUrlDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "LivebookUrl" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "livebookUrl" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "url" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<LivebookUrlQuery, LivebookUrlQueryVariables>;
export const UpsertGeoreferenceAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "upsertGeoreferenceAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "type" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "content" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "language" },
          },
          type: {
            kind: "ListType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "upsertFileSetAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "type" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "type" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "content" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "content" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "language" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "language" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "language" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "content" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpsertGeoreferenceAnnotationMutation,
  UpsertGeoreferenceAnnotationMutationVariables
>;
export const DeleteFileSetAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "deleteFileSetAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "annotationId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteFileSetAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "annotationId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "annotationId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteFileSetAnnotationMutation,
  DeleteFileSetAnnotationMutationVariables
>;
export const GetWorkAiActivitiesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetWorkAIActivities" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "aiActivities" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "activityType" },
                },
                { kind: "Field", name: { kind: "Name", value: "aiUseType" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "model" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "modelProvider" },
                },
                { kind: "Field", name: { kind: "Name", value: "startedAt" } },
                { kind: "Field", name: { kind: "Name", value: "completedAt" } },
                { kind: "Field", name: { kind: "Name", value: "costUsd" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "targets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "targetType" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "fieldPath" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "operation" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "proposedValue" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "events" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "eventType" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "actor" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "occurredAt" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "outcome" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "notes" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "itemIdentifier" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "valueBefore" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "valueAfter" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GetWorkAiActivitiesQuery,
  GetWorkAiActivitiesQueryVariables
>;
export const FileSetAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "fileSetAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "fileSetAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "content" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "language" } },
                { kind: "Field", name: { kind: "Name", value: "model" } },
                { kind: "Field", name: { kind: "Name", value: "s3Location" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "error" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiProvenance" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "model" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewer" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "generatedAt" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  FileSetAnnotationSubscription,
  FileSetAnnotationSubscriptionVariables
>;
export const WorkFileSetAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "subscription",
      name: { kind: "Name", value: "workFileSetAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "workFileSetAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  WorkFileSetAnnotationSubscription,
  WorkFileSetAnnotationSubscriptionVariables
>;
export const TranscribeFileSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "transcribeFileSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "language" },
          },
          type: {
            kind: "ListType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "model" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "context" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "transcribeFileSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "language" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "language" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "model" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "model" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "context" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "context" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  TranscribeFileSetMutation,
  TranscribeFileSetMutationVariables
>;
export const UpdateFileSetAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "updateFileSetAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "annotationId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "content" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateFileSetAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "annotationId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "annotationId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "content" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "content" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "content" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "language" } },
                { kind: "Field", name: { kind: "Name", value: "model" } },
                { kind: "Field", name: { kind: "Name", value: "s3Location" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiProvenance" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "model" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewer" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "generatedAt" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateFileSetAnnotationMutation,
  UpdateFileSetAnnotationMutationVariables
>;
export const UpsertFileSetAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "upsertFileSetAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "type" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "content" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "language" },
          },
          type: {
            kind: "ListType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "upsertFileSetAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "type" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "type" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "content" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "content" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "language" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "language" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "content" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "language" } },
                { kind: "Field", name: { kind: "Name", value: "model" } },
                { kind: "Field", name: { kind: "Name", value: "s3Location" } },
                { kind: "Field", name: { kind: "Name", value: "status" } },
                { kind: "Field", name: { kind: "Name", value: "type" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiProvenance" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "model" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewer" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "generatedAt" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpsertFileSetAnnotationMutation,
  UpsertFileSetAnnotationMutationVariables
>;
export const AttestHumanAuthoredAnnotationDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "AttestHumanAuthoredAnnotation" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "annotationId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "reason" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "attestHumanAuthoredAnnotation" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "annotationId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "annotationId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "reason" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "reason" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiProvenance" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  AttestHumanAuthoredAnnotationMutation,
  AttestHumanAuthoredAnnotationMutationVariables
>;
export const AuthoritiesSearchDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "AuthoritiesSearch" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "authority" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "query" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "limit" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "authoritiesSearch" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "authority" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "authority" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "query" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "query" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "limit" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "limit" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "hint" } },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  AuthoritiesSearchQuery,
  AuthoritiesSearchQueryVariables
>;
export const CodeListQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "CodeListQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "scheme" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "CodeListScheme" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "codeList" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "scheme" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "scheme" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
                { kind: "Field", name: { kind: "Name", value: "scheme" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<CodeListQueryQuery, CodeListQueryQueryVariables>;
export const GeonamesPlaceDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GeonamesPlace" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "geonamesPlace" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GeonamesPlaceQuery, GeonamesPlaceQueryVariables>;
export const FetchCodedTermLabelQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "FetchCodedTermLabelQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "scheme" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "CodeListScheme" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "fetchCodedTermLabel" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "scheme" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "scheme" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  FetchCodedTermLabelQueryQuery,
  FetchCodedTermLabelQueryQueryVariables
>;
export const FetchControlledTermLabelDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "FetchControlledTermLabel" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "fetchControlledTermLabel" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "label" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  FetchControlledTermLabelQuery,
  FetchControlledTermLabelQueryVariables
>;
export const ActionStatesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "ActionStates" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "objectId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "actionStates" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "objectId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "objectId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "action" } },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "notes" } },
                { kind: "Field", name: { kind: "Name", value: "objectId" } },
                { kind: "Field", name: { kind: "Name", value: "outcome" } },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<ActionStatesQuery, ActionStatesQueryVariables>;
export const AddWorkToCollectionDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "addWorkToCollection" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "collectionId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "addWorkToCollection" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "collectionId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "collectionId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  AddWorkToCollectionMutation,
  AddWorkToCollectionMutationVariables
>;
export const CreateSharedLinkDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "CreateSharedLink" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createSharedLink" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "expires" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "sharedLinkId" },
                },
                { kind: "Field", name: { kind: "Name", value: "workId" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  CreateSharedLinkMutation,
  CreateSharedLinkMutationVariables
>;
export const CreateWorkDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "createWork" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "accessionNumber" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "title" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workType" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "CodedTermInput" },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "createWork" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "accessionNumber" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "accessionNumber" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "administrativeMetadata" },
                value: { kind: "ObjectValue", fields: [] },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "descriptiveMetadata" },
                value: {
                  kind: "ObjectValue",
                  fields: [
                    {
                      kind: "ObjectField",
                      name: { kind: "Name", value: "title" },
                      value: {
                        kind: "Variable",
                        name: { kind: "Name", value: "title" },
                      },
                    },
                  ],
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "workType" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workType" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "accessionNumber" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptiveMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "workType" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<CreateWorkMutation, CreateWorkMutationVariables>;
export const DeleteFileSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "DeleteFileSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteFileSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  DeleteFileSetMutation,
  DeleteFileSetMutationVariables
>;
export const DeleteWorkDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "deleteWork" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "deleteWork" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptiveMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheet" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "project" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<DeleteWorkMutation, DeleteWorkMutationVariables>;
export const WorkQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "WorkQuery" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "work" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "accessionNumber" },
                },
                { kind: "Field", name: { kind: "Name", value: "ark" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "aiProvenanceSummary" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "fieldPath" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "targetType" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "targetId" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "operation" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "origin" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "proposedValue" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "currentValue" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "itemProvenance" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "origin" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "humanOversightLevel" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "activityId" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "activityType" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "aiUseType" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "model" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "modelProvider" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "generatedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewer" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "reviewedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "appliedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "latestEventType" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "sourceCount" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "citationCompleteness" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "behavior" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "administrativeMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "libraryUnit" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "preservationLevel" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "projectCycle" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "projectDesc" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "projectManager" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "projectName" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "projectProposer" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "projectTaskNumber" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "collection" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptiveMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "abstract" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "alternateTitle" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "boxName" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "boxNumber" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "caption" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "catalogKey" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "contributor" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "role" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "scheme" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "creator" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "culturalContext" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "dateCreated" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "edtf" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "humanized" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "folderName" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "folderNumber" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "genre" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "identifier" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "keywords" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "language" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "legacyIdentifier" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "license" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "location" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "notes" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "note" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "type" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "scheme" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: {
                          kind: "Name",
                          value: "physicalDescriptionMaterial",
                        },
                      },
                      {
                        kind: "Field",
                        name: {
                          kind: "Name",
                          value: "physicalDescriptionSize",
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "provenance" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "publisher" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "relatedUrl" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "url" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "scheme" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "relatedMaterial" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "rightsHolder" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "rightsStatement" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "scopeAndContents" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "series" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "source" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "stylePeriod" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "subject" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "role" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "scheme" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "tableOfContents" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "technique" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "termsOfUse" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "fileSets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "accessionNumber" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "annotations" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "type" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "status" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "language" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "content" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "aiProvenance" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "origin" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "status" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "model" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "reviewer" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "reviewedAt" },
                                  },
                                  {
                                    kind: "Field",
                                    name: {
                                      kind: "Name",
                                      value: "generatedAt",
                                    },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "coreMetadata" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "altText" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "description" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "imageCaption" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "location" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "mimeType" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "originalFilename" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "digests" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "md5" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "sha1" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "sha256" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "extractedMetadata" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "groupWith" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "insertedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "role" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "representativeImageUrl" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "streamingUrl" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "structuralMetadata" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "type" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "value" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "updatedAt" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheet" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "manifestUrl" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "project" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeImage" },
                },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "workType" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<WorkQueryQuery, WorkQueryQueryVariables>;
export const WorksQueryDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "WorksQuery" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "works" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "accessionNumber" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptiveMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "fileSets" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "role" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "annotations" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "type" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "status" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "language" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "content" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "aiProvenance" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "origin" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "status" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "model" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "reviewer" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "reviewedAt" },
                                  },
                                  {
                                    kind: "Field",
                                    name: {
                                      kind: "Name",
                                      value: "generatedAt",
                                    },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "accessionNumber" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "coreMetadata" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "altText" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "description" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "imageCaption" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "originalFilename" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "location" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "digests" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "md5" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "sha1" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "sha256" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "representativeImageUrl" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "insertedAt" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "updatedAt" },
                      },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "manifestUrl" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "project" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "ingestSheet" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeImage" },
                },
                { kind: "Field", name: { kind: "Name", value: "updatedAt" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "workType" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<WorksQueryQuery, WorksQueryQueryVariables>;
export const GetWorkTypesDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "GetWorkTypes" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "codeList" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "scheme" },
                value: { kind: "EnumValue", value: "WORK_TYPE" },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "label" } },
                { kind: "Field", name: { kind: "Name", value: "scheme" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<GetWorkTypesQuery, GetWorkTypesQueryVariables>;
export const ReplaceFileSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "ReplaceFileSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "coreMetadata" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "FileSetCoreMetadataInput" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "replaceFileSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "coreMetadata" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "coreMetadata" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "coreMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "location" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "originalFilename" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ReplaceFileSetMutation,
  ReplaceFileSetMutationVariables
>;
export const ListIngestBucketObjectsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "ListIngestBucketObjects" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "prefix" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "listIngestBucketObjects" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "prefix" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "prefix" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "folders" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "objects" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "uri" } },
                      { kind: "Field", name: { kind: "Name", value: "key" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "storageClass" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "size" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "lastModified" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "mimeType" },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  ListIngestBucketObjectsQuery,
  ListIngestBucketObjectsQueryVariables
>;
export const SetWorkImageDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "SetWorkImage" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "setWorkImage" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "representativeImage" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  SetWorkImageMutation,
  SetWorkImageMutationVariables
>;
export const AttestHumanAuthoredMetadataDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "AttestHumanAuthoredMetadata" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fieldPaths" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "ListType",
              type: {
                kind: "NonNullType",
                type: {
                  kind: "NamedType",
                  name: { kind: "Name", value: "String" },
                },
              },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "itemIds" },
          },
          type: {
            kind: "ListType",
            type: {
              kind: "NonNullType",
              type: {
                kind: "NamedType",
                name: { kind: "Name", value: "String" },
              },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "reason" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "attestHumanAuthoredMetadata" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "fieldPaths" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fieldPaths" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "itemIds" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "itemIds" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "reason" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "reason" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  AttestHumanAuthoredMetadataMutation,
  AttestHumanAuthoredMetadataMutationVariables
>;
export const UpdateWorkDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateWork" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "work" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "WorkUpdateInput" },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateWork" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "work" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "work" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "administrativeMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "libraryUnit" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "preservationLevel" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "status" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "collection" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "descriptiveMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "contributor" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "role" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "scheme" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "creator" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "culturalContext" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "dateCreated" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "edtf" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "humanized" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "genre" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "language" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "license" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "location" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "rightsStatement" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "id" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "label" },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "stylePeriod" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "subject" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "role" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "scheme" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "technique" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "term" },
                              selectionSet: {
                                kind: "SelectionSet",
                                selections: [
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "id" },
                                  },
                                  {
                                    kind: "Field",
                                    name: { kind: "Name", value: "label" },
                                  },
                                ],
                              },
                            },
                          ],
                        },
                      },
                      { kind: "Field", name: { kind: "Name", value: "title" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "termsOfUse" },
                      },
                    ],
                  },
                },
                { kind: "Field", name: { kind: "Name", value: "insertedAt" } },
                { kind: "Field", name: { kind: "Name", value: "published" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "workType" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "visibility" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "behavior" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<UpdateWorkMutation, UpdateWorkMutationVariables>;
export const IngestFileSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "IngestFileSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "accession_number" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "String" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "role" } },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "CodedTermInput" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "coreMetadata" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "FileSetCoreMetadataInput" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "ingestFileSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "accessionNumber" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "accession_number" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "role" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "role" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "coreMetadata" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "coreMetadata" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "accessionNumber" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "role" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "work" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      { kind: "Field", name: { kind: "Name", value: "id" } },
                    ],
                  },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "coreMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "location" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "originalFilename" },
                      },
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "digests" },
                        selectionSet: {
                          kind: "SelectionSet",
                          selections: [
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "md5" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "sha1" },
                            },
                            {
                              kind: "Field",
                              name: { kind: "Name", value: "sha256" },
                            },
                          ],
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  IngestFileSetMutation,
  IngestFileSetMutationVariables
>;
export const UpdateAccessFileOrderDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateAccessFileOrder" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSetIds" },
          },
          type: {
            kind: "ListType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateAccessFileOrder" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSetIds" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSetIds" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateAccessFileOrderMutation,
  UpdateAccessFileOrderMutationVariables
>;
export const TransferFileSetsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "TransferFileSets" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fromWorkId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "toWorkId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "transferFileSets" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fromWorkId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fromWorkId" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "toWorkId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "toWorkId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  TransferFileSetsMutation,
  TransferFileSetsMutationVariables
>;
export const TransferFileSetsSubsetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "TransferFileSetsSubset" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "filesetIds" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "ListType",
              type: {
                kind: "NonNullType",
                type: {
                  kind: "NamedType",
                  name: { kind: "Name", value: "ID" },
                },
              },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "createWork" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "NamedType",
              name: { kind: "Name", value: "Boolean" },
            },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "accessionNumber" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "String" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workAttributes" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "WorkAttributesInput" },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "deleteEmptyWorks" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Boolean" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "transferFileSetsSubset" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "filesetIds" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "filesetIds" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "createWork" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "createWork" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "accessionNumber" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "accessionNumber" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "workAttributes" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workAttributes" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "deleteEmptyWorks" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "deleteEmptyWorks" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                {
                  kind: "Field",
                  name: { kind: "Name", value: "transferredFilesetIds" },
                },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "createdWorkId" },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  TransferFileSetsSubsetMutation,
  TransferFileSetsSubsetMutationVariables
>;
export const WorkArchiverEndpointDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "WorkArchiverEndpoint" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "workArchiverEndpoint" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "url" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  WorkArchiverEndpointQuery,
  WorkArchiverEndpointQueryVariables
>;
export const UpdateFileSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateFileSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "coreMetadata" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "FileSetCoreMetadataUpdate" },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "posterOffset" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "Int" } },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "structuralMetadata" },
          },
          type: {
            kind: "NamedType",
            name: { kind: "Name", value: "FileSetStructuralMetadataInput" },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateFileSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "coreMetadata" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "coreMetadata" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "posterOffset" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "posterOffset" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "structuralMetadata" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "structuralMetadata" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateFileSetMutation,
  UpdateFileSetMutationVariables
>;
export const UpdateFileSetsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "UpdateFileSets" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "fileSets" },
          },
          type: {
            kind: "NonNullType",
            type: {
              kind: "ListType",
              type: {
                kind: "NamedType",
                name: { kind: "Name", value: "FileSetUpdate" },
              },
            },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateFileSets" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "fileSets" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "fileSets" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                {
                  kind: "Field",
                  name: { kind: "Name", value: "coreMetadata" },
                  selectionSet: {
                    kind: "SelectionSet",
                    selections: [
                      {
                        kind: "Field",
                        name: { kind: "Name", value: "description" },
                      },
                      { kind: "Field", name: { kind: "Name", value: "label" } },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  UpdateFileSetsMutation,
  UpdateFileSetsMutationVariables
>;
export const GroupWithFileSetDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "mutation",
      name: { kind: "Name", value: "GroupWithFileSet" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: { kind: "Variable", name: { kind: "Name", value: "id" } },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "groupWith" },
          },
          type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "updateFileSet" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "id" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "id" },
                },
              },
              {
                kind: "Argument",
                name: { kind: "Name", value: "groupWith" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "groupWith" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "id" } },
                { kind: "Field", name: { kind: "Name", value: "groupWith" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<
  GroupWithFileSetMutation,
  GroupWithFileSetMutationVariables
>;
export const VerifyFileSetsDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "VerifyFileSets" },
      variableDefinitions: [
        {
          kind: "VariableDefinition",
          variable: {
            kind: "Variable",
            name: { kind: "Name", value: "workId" },
          },
          type: {
            kind: "NonNullType",
            type: { kind: "NamedType", name: { kind: "Name", value: "ID" } },
          },
        },
      ],
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "verifyFileSets" },
            arguments: [
              {
                kind: "Argument",
                name: { kind: "Name", value: "workId" },
                value: {
                  kind: "Variable",
                  name: { kind: "Name", value: "workId" },
                },
              },
            ],
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "fileSetId" } },
                { kind: "Field", name: { kind: "Name", value: "verified" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<VerifyFileSetsQuery, VerifyFileSetsQueryVariables>;
export const DcApiTokenDocument = {
  kind: "Document",
  definitions: [
    {
      kind: "OperationDefinition",
      operation: "query",
      name: { kind: "Name", value: "DcApiToken" },
      selectionSet: {
        kind: "SelectionSet",
        selections: [
          {
            kind: "Field",
            name: { kind: "Name", value: "dcApiToken" },
            selectionSet: {
              kind: "SelectionSet",
              selections: [
                { kind: "Field", name: { kind: "Name", value: "expires" } },
                { kind: "Field", name: { kind: "Name", value: "token" } },
              ],
            },
          },
        ],
      },
    },
  ],
} as unknown as DocumentNode<DcApiTokenQuery, DcApiTokenQueryVariables>;
