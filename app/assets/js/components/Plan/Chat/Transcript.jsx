import React from "react";
import PlanChatMessage from "@js/components/Plan/Chat/Message";

const PlanChatTranscript = ({ messages }) => {
  return (
    <div className="chat-transcript">
      {messages.map((msg, index) => (
        <PlanChatMessage
          key={index}
          content={msg.content}
          isUser={msg.isUser}
        />
      ))}
    </div>
  );
};

export default PlanChatTranscript;
