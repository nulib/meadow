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

  const { work } = data;

  return (
    <>
      <ScreenHeader
        title={id}
        description="A work in the system, defined by Accession Number and container file sets."
        breadCrumbs={[
          {
            label: `${work.accessionNumber}`,
            link: `/work/${id}`
          }
        ]}
      />
      <ScreenContent>
        <Work work={data.work} />
      </ScreenContent>
    </>
  );
};

export default ScreensWork;
