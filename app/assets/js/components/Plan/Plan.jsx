import React from "react";
import PlanChat from "@js/components/Plan/Chat/Chat";
import { usePlanChanges } from "@js/hooks/usePlanChanges";
import PlanPanelChanges from "./Panel/Changes";

const Plan = ({ works }) => {
  const query = works.map((work) => `id:(${work.id})`).join(" OR ");
  const [planId, setPlanId] = React.useState(null);

  const hasPlan = Boolean(planId);

  const { data: planChanges, error: planChangesError } = usePlanChanges(planId);

  const initialMessages = [
    `You are editing ${works.length === 1 ? `the _${works[0].workType.label}_ work **${works[0].descriptiveMetadata.title ? works[0].descriptiveMetadata.title : "No title"}**` : `${works.length} works`}.`,
    `What would you like to modify?`,
  ].map((content) => ({
    content,
    type: "message",
    isUser: false,
  }));

  const targetTitle =
    works.length === 1
      ? works[0].descriptiveMetadata.title
      : `${works.length} works`;

  // iterate works and get thumbnails
  const targetThumbnails = works.map((work) => {
    const thumbnail = new URL(work.representativeImage);
    thumbnail.pathname += "/square/100,/0/default.jpg";
    return thumbnail ? (
      <img
        key={work.id}
        src={thumbnail.toString()}
        alt={work.descriptiveMetadata.title || "work thumbnail"}
        className="thumbnail-image"
      />
    ) : null;
  });

  console.log({ planChanges });

  return (
    <div className="plan box" data-has-plan={hasPlan}>
      <div className="plan-workspace">
        {planId ? (
          <PlanPanelChanges
            id={planId}
            changes={planChanges}
            target={{
              title: targetTitle,
              thumbnails: targetThumbnails,
            }}
          />
        ) : (
          <div className="plan-placeholder">
            {targetThumbnails}
            <p className="is-6">{targetTitle}</p>
            <p className="subtitle is-6 mt-3">
              Describe the changes you want to make to this work, and an AI
              assistant will help you make those changes.
            </p>
          </div>
        )}
      </div>
      <div className="chat-wrapper">
        <button> collapse the chat </button>
        <PlanChat
          query={query}
          initialMessages={initialMessages}
          planIdCallback={(planId) => setPlanId(planId)}
        />
      </div>
    </div>
  );
};

export default Plan;
