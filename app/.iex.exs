Code.put_compiler_option(:ignore_module_conflict, true)

alias Meadow.Repo

alias Meadow.{
  Accounts,
  Constants,
  Data,
  IIIF,
  Ingest,
  Pipeline,
  Utils
}

alias Meadow.Accounts.Users
alias Meadow.Accounts.Schemas.User

alias Meadow.Data.{
  ActionStates,
  CodedTerms,
  Collections,
  ControlledTerms,
  FileSets,
  Indexer,
  IndexTimes,
  Works
}

alias Meadow.Data.Schemas.{
  ActionState,
  CodedTerm,
  Collection,
  ControlledMetadataEntry,
  ControlledTermCache,
  Field,
  FileSet,
  FileSetCoreMetadata,
  IndexTime,
  Value,
  Work,
  WorkAdministrativeMetadata,
  WorkDescriptiveMetadata
}

alias Meadow.Ingest.{Progress, Projects, Rows, Sheets, SheetsToWorks}

alias Meadow.Ingest.Schemas.{
  Project,
  Row,
  Sheet,
  Status
}

import Ecto.Query
