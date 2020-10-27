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

  // GET MARC_RELATOR DATA
  const {
    data: marcData,
    error: marcError,
    loading: marcLoading,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "MARC_RELATOR" } });

  if (marcError) {
    throw new Error("Error getting marc data");
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

  return (
    <CodeListContext.Provider
      value={{
        authorityData,
        marcData,
        subjectRoleData,
        isLoading: authorityLoading || marcLoading || subjectRoleLoading,
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
