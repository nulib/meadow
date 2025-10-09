import React from "react";

const PlanChatMessage = ({ content, isUser, type = "message" }) => {
  return (
    <article
      className="chat-message"
      data-message-user={isUser ? "human" : "ai"}
      data-message-type={type}
    >
      {content}
    </article>
  );
};

export default PlanChatMessage;
