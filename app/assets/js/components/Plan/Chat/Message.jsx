import React from "react";
import useMarkdown from "@nulib/use-markdown";

const PlanChatMessage = ({ content, isUser, type = "message" }) => {
  const markdown = useMarkdown(content);

  return (
    <article
      className="chat-message"
      data-message-user={isUser ? "human" : "ai"}
      data-message-type={type}
    >
      {markdown.jsx}
    </article>
  );
};

export default PlanChatMessage;
