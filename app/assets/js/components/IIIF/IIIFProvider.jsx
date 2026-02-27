import React from "react";
import { useQuery } from "@apollo/client/react";
import Error from "../UI/Error";
import UILoadingPage from "../UI/LoadingPage";
import { IIIF_SERVER_URL } from "./iiif.gql";

export const IIIFContext = React.createContext();

export const IIIFProvider = ({ children }) => {
  const { loading, error, data } = useQuery(IIIF_SERVER_URL);

  if (error) return <Error error={error} />;
  if (loading) return null;

  return (
    <IIIFContext.Provider value={data ? data.iiifServerUrl.url : null}>
      {children}
    </IIIFContext.Provider>
  );
};
