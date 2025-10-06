// PlanChatTranscript.jsx
import React from "react";
import PlanChatMessage from "@js/components/Plan/Chat/Message";

const PlanChatTranscript = ({ messages }) => {
  return (
    <div className="chat-transcript">
      {messages.map((entry, index) => (
        <PlanChatMessage
          key={index}
          content={entry.content}
          isUser={entry.isUser}
        />
      ))}
    </div>
  );
};

export default PlanChatTranscript;
