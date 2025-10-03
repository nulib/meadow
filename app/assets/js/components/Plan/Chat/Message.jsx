import React from "react";

const PlanChatMessage = ({ content, isUser }) => {
  return (
    <article
      className="chat-message"
      data-message-user={isUser ? "human" : "ai"}
    >
      {content}
    </article>
  );
};

export default PlanChatMessage;
