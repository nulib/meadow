import React from "react";
import { CODE_LIST_QUERY } from "@js/components/Work/controlledVocabulary.gql";
import { useQuery } from "@apollo/client";

const CodeListContext = React.createContext();

function CodeListProvider({ children }) {
  // GET AUTHORITY
  const {
    data: authorityData,
    error: authorityError,
    loading: authorityLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "AUTHORITY" } });

  if (authorityError) {
    throw new Error("Error getting authority data");
  }

  // GET LIBRARY UNIT
  const {
    data: libraryUnitData,
    error: libraryUnitError,
    loading: libraryUnitLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "LIBRARY_UNIT" } });

  if (libraryUnitError) {
    throw new Error("Error getting library unit data");
  }

  // GET LICENSE DATA
  const {
    data: licenseData,
    error: licenseError,
    loading: licenseLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "LICENSE" } });

  if (licenseError) {
    throw new Error("Error getting license data");
  }

  // GET MARC_RELATOR DATA
  const {
    data: marcData,
    error: marcError,
    loading: marcLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "MARC_RELATOR" } });

  if (marcError) {
    throw new Error("Error getting marc data");
  }

  // GET NOTES
  const {
    data: notesData,
    error: notesError,
    loading: notesLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "NOTE_TYPE" } });

  if (notesError) {
    throw new Error("Error getting notes data");
  }

  // GET PRESERVATION_LEVEL DATA
  const {
    data: preservationLevelData,
    error: preservationLevelError,
    loading: preservationLevelLoading,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "PRESERVATION_LEVEL" },
  });

  if (preservationLevelError) {
    throw new Error("Error getting preservation level data");
  }

  // GET RELATED_URL
  const {
    data: relatedUrlData,
    error: relatedUrlError,
    loading: relatedUrlLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "RELATED_URL" } });

  if (relatedUrlError) {
    throw new Error("Error getting related url data");
  }

  // GET RIGHTS STATEMENT
  const {
    data: rightsStatementData,
    error: rightsStatementError,
    loading: rightsStatementLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "RIGHTS_STATEMENT" } });

  if (rightsStatementError) {
    throw new Error("Error getting rights statement data");
  }

  // GET STATUS DATA
  const {
    data: statusData,
    error: statusError,
    loading: statusLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "STATUS" } });

  if (statusError) {
    throw new Error("Error getting status data");
  }

  // GET SUBJECT_ROLE DATA
  const {
    data: subjectRoleData,
    error: subjectRoleError,
    loading: subjectRoleLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "SUBJECT_ROLE" } });

  if (subjectRoleError) {
    throw new Error("Error getting subject role data");
  }

  // GET VISIBILITY DATA
  const {
    data: visibilityData,
    error: visibilityError,
    loading: visibilityLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "VISIBILITY" } });

  if (visibilityError) {
    throw new Error("Error getting visibility data");
  }

  // GET FILE SET ROLES
  const {
    data: fileSetRoleData,
    error: fileSetRoleError,
    loading: fileSetRoleLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "FILE_SET_ROLE" } });

  if (fileSetRoleError) {
    throw new Error("Error getting file set role data");
  }

  return (
    <CodeListContext.Provider
      value={{
        authorityData,
        fileSetRoleData,
        libraryUnitData,
        licenseData,
        marcData,
        notesData,
        preservationLevelData,
        relatedUrlData,
        rightsStatementData,
        statusData,
        subjectRoleData,
        visibilityData,
        isLoading: Boolean(
          fileSetRoleLoading ||
            authorityLoading ||
            libraryUnitLoading ||
            licenseLoading ||
            marcLoading ||
            notesLoading ||
            preservationLevelLoading ||
            relatedUrlLoading ||
            rightsStatementLoading ||
            statusLoading ||
            subjectRoleLoading ||
            visibilityLoading
        ),
      }}
    >
      {children}
    </CodeListContext.Provider>
  );
}

function useCodeLists() {
  const context = React.useContext(CodeListContext);
  if (context === undefined) {
    throw new Error("useCodeLists must be used within CodeListProvider");
  }
  return context;
}

export { CodeListProvider, useCodeLists };
