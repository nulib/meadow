import { useState } from "react";
import { useLazyQuery } from "@apollo/client";
import { CODE_LIST_QUERY } from "../components/Work/controlledVocabulary.gql";
import { LOCAL_STORAGE_CODELIST_KEY } from "../services/global-vars";

export default function () {
  const [codeLists, setCodeLists] = useState(
    JSON.parse(localStorage.getItem(LOCAL_STORAGE_CODELIST_KEY))
  );

  const [
    getMarcData,
    { data: marcData, loading: marcLoading, errors: marcErrors },
  ] = useLazyQuery(CODE_LIST_QUERY, {
    onCompleted: (data) => {
      if (!marcErrors && data) {
        console.log("Success data", data);
      }
    },
    onError: (data) => {
      console.log("getMarcData() error :>> ", data);
    },
  });

  function refreshCodeLists() {
    getMarcData({
      variables: { scheme: "MARC_RELATOR" },
    });
  }

  return [codeLists, refreshCodeLists];
}
