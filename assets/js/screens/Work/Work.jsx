import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORK } from "../../components/Work/work.query";
import { useParams } from "react-router-dom";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Work from "../../components/Work/Work";

const ScreensWork = () => {
  const { id } = useParams();
  const { data, loading, error } = useQuery(GET_WORK, {
    variables: { id }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  console.log("Data", data);
  const { work } = data;

  return (
    <>
      <ScreenHeader>
        <h1>
          {work.metadata.title ? work.metadata.title : work.accessionNumber}
        </h1>
      </ScreenHeader>
      <ScreenContent>
        <Work work={data.work} />
      </ScreenContent>
    </>
  );
};

export default ScreensWork;
