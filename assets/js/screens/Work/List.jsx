import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORKS } from "../../components/Work/work.query";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import WorkList from "../../components/Work/List";

const ScreensWorkList = () => {
  const { data, loading, error } = useQuery(GET_WORKS);

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const createCrumbs = () => {
    return [
      {
        label: "Works",
        link: "/work/list"
      }
    ];
  };

  return (
    <>
      <ScreenHeader
        title="Works"
        description="All works in the system."
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <WorkList works={data.works} />
      </ScreenContent>
    </>
  );
};

export default ScreensWorkList;
