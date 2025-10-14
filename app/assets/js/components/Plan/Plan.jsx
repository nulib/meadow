import React from "react";
import PlanChat from "@js/components/Plan/Chat/Chat";

const Plan = ({ works }) => {
  const query = works.map((work) => `id:(${work.id})`).join(" OR ");
  const initialMessageContent =
    works.length === 1
      ? `You are editing the ${works[0].workType.label} work ${works[0].descriptiveMetadata.title ? works[0].descriptiveMetadata.title : "No title"}, collection ${works[0]?.collection?.title}, with the accession number ${works[0].accessionNumber}. What would you like to modify?`
      : `You are editing ${works.length} works. What would you like to modify?`;

  return (
    <div className="box" style={{ margin: "1rem 0" }}>
      <PlanChat
        query={query}
        initialMessage={{
          content: initialMessageContent,
          type: "message",
          isUser: false,
        }}
      />
    </div>
  );
};

export default Plan;
