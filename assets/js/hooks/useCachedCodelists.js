import { useState, useEffect } from "react";
import { useLazyQuery } from "@apollo/client";
import { CODE_LIST_QUERY } from "../components/Work/controlledVocabulary.gql";
import { LOCAL_STORAGE_CODELIST_KEY } from "../services/global-vars";

export default function () {
  const [codeLists, setCodeLists] = useState(
    JSON.parse(localStorage.getItem(LOCAL_STORAGE_CODELIST_KEY))
  );

  function refreshCodeLists() {
    setCodeLists(null);
    localStorage.removeItem(LOCAL_STORAGE_CODELIST_KEY);
    console.log(
      "Refreshing Code Lists local storage with fresh values from API---------\n"
    );

    getMarcData({
      variables: { scheme: "MARC_RELATOR" },
    });
    getAuthorityData({
      variables: { scheme: "AUTHORITY" },
    });
    getSubjectRoleData({
      variables: { scheme: "SUBJECT_ROLE" },
    });
  }

  /**
   * Update code lists in local storage and local state
   * @param {String} key
   * @param {Array} data
   */
  function updateCodeLists(key, data) {
    // Update localStorage
    let currentLocalStorage =
      JSON.parse(localStorage.getItem(LOCAL_STORAGE_CODELIST_KEY)) || {};

    const newObj = {
      ...currentLocalStorage,
      [key]: data,
    };
    localStorage.setItem(LOCAL_STORAGE_CODELIST_KEY, JSON.stringify(newObj));

    //Update local state
    setCodeLists({
      ...codeLists,
      [key]: data,
    });
  }

  const [
    getAuthorityData,
    { data: authorityData, loading: authorityLoading, errors: authorityErrors },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      if (!authorityErrors && data) {
        updateCodeLists("AUTHORITY", data.codeList);
      }
    },
    onError: (data) => {
      console.log("getAuthorityData()", data);
    },
  });

  const [
    getMarcData,
    { data: marcData, loading: marcLoading, errors: marcErrors },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      if (!marcErrors && data) {
        updateCodeLists("MARC_RELATOR", data.codeList);
      }
    },
    onError: (data) => {
      console.log("getMarcData() error :>> ", data);
    },
  });

  const [
    getSubjectRoleData,
    {
      data: subjectRoleData,
      loading: subjectRoleLoading,
      errors: subjectRoleErrors,
    },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    variables: { scheme: "SUBJECT_ROLE" },
    onCompleted: (data) => {
      if (!subjectRoleErrors && data) {
        updateCodeLists("SUBJECT_ROLE", data.codeList);
      }
    },
    onError: (data) => {
      console.log("getSubjectRoleData() error :>> ", data);
    },
  });

  return [codeLists, refreshCodeLists];
}
