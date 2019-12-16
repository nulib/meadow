import React from "react";
import { useQuery } from "@apollo/react-hooks";
import { GET_WORKS } from "../../components/Work/work.query";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import ScreenContent from "../../components/UI/ScreenContent";
import WorkRow from "../../components/Work/Row";

const ScreensWorkList = () => {
  const { data, loading, error } = useQuery(GET_WORKS);

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const sampleWorks = data.works.slice(0, 10);

  return (
    <ScreenContent>
      <p className="my-4">
        <span className="font-bold">[xx] results returned...</span>
      </p>
      {sampleWorks.map(work => (
        <WorkRow key={work.id} work={work} />
      ))}
    </ScreenContent>
  );
};

export default ScreensWorkList;
