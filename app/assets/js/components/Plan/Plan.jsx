import React from "react";
import { usePlanChanges } from "@js/hooks/usePlanChanges";
import { usePlan } from "@js/hooks/usePlan";
import { useSendChatMessage } from "@js/hooks/useSendChatMessage";
import { useChatResponse } from "@js/hooks/useChatResponse";
import PlanPanelChanges from "@js/components/Plan/Panel/Changes";
import PlanChatForm from "@js/components/Plan/Chat/Form";
import SquircleThumbnail from "@js/components/UI/SquircleThumbnail";
import { toastWrapper } from "@js/services/helpers";
import { v4 as uuidv4 } from "uuid";

const conversationId = uuidv4();

const Plan = ({ works }) => {
  const query = works.map((work) => `id:(${work.id})`).join(" OR ");
  const [planId, setPlanId] = React.useState(null);
  const [loadingMessage, setLoadingMessage] =
    React.useState("Initializing plan");
  const [summary, setSummary] = React.useState(null);
  const [originalPrompt, setOriginalPrompt] = React.useState(null);

  const { data: planChanges, error: planChangesError } = usePlanChanges(planId);
  const { data: plan, error: planError } = usePlan(planId);

  const { data: chatResponseMessage, error: subscriptionError } =
    useChatResponse(conversationId);

  const { sendChatMessage, error: sendError } = useSendChatMessage();

  const status = plan?.status || null;

  const targetTitle =
    works.length === 1
      ? works[0].descriptiveMetadata.title
      : `${works.length} works`;

  // iterate works and get thumbnails
  const targetThumbnails = works.map((work) => {
    const thumbnail = new URL(work.representativeImage);
    thumbnail.pathname += "/square/100,/0/default.jpg";
    return thumbnail ? (
      <SquircleThumbnail
        key={work.id}
        src={thumbnail.toString()}
        alt={work.descriptiveMetadata.title || "work thumbnail"}
        size={75}
        exponent={6}
      />
    ) : null;
  });

  const handleSubmitMessage = async (text) => {
    setOriginalPrompt(text);
    try {
      await sendChatMessage({
        conversationId,
        type: "chat",
        prompt: text,
        query,
      });
    } catch (e) {
      console.error(e);
    }
  };

  React.useEffect(() => {
    if (!chatResponseMessage) return;

    if (chatResponseMessage.type === "plan_id")
      setPlanId(chatResponseMessage.planId);

    if (chatResponseMessage.type === "status_update")
      setLoadingMessage(chatResponseMessage.message);

    // Capture all non-status messages as the summary (last one wins)
    if (chatResponseMessage.type !== "status_update" && chatResponseMessage.type !== "plan_id")
      setSummary(chatResponseMessage.message);
  }, [chatResponseMessage]);

  // Reset to initial screen when plan is completed
  const handlePlanCompleted = (rejectedPrompt = null, status = null) => {
    setPlanId(null);
    setLoadingMessage("Initializing plan");
    setSummary(null);

    if (!rejectedPrompt){
      setOriginalPrompt(null);
    }

    // Show toast notifications after returning to initial screen
    if (status === "COMPLETED") {
      toastWrapper("is-success", "Your changes have been applied. Refresh your browser to see the changes.");
    } else if (status === "REJECTED") {
      toastWrapper("is-warning", "Your changes have been cancelled. Please adjust your prompt and try again.");
    } else if (status === "ERROR") {
      toastWrapper("is-danger", "An error occurred. Please try again.");
    }
  };

  // Show initial form screen when no plan
  const showInitialForm = !planId;

  return (
    <div className="plan box" data-has-plan={Boolean(planId)}>
      <div className="plan-workspace">
        {showInitialForm ? (
          <div className="plan-placeholder">
            {targetThumbnails}
            <p className="is-6" style={{ marginBottom: "4rem" }}>{targetTitle}</p>
            <p className="subtitle is-6">
              Describe the changes you want to make to this work, and an AI
              assistant will help you make those changes.
            </p>
            <PlanChatForm
              showScrollButton={false}
              onSubmitMessage={handleSubmitMessage}
              originalPrompt={originalPrompt}
            />
          </div>
        ) : (
          <PlanPanelChanges
            changes={planChanges}
            id={planId}
            plan={plan}
            loadingMessage={loadingMessage}
            summary={summary}
            originalPrompt={originalPrompt}
            target={{
              title: targetTitle,
              thumbnails: targetThumbnails,
            }}
            onCompleted={handlePlanCompleted}
          />
        )}
      </div>
    </div>
  );
};

export default Plan;
