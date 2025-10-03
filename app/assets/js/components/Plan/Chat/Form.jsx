import React from "react";
import { IconReply } from "@js/components/Icon";
import PlanChatAutoTextArea from "@js/components/Plan/Chat/AutoTextArea";

const PlanChatForm = () => {
  return (
    <div className="field is-relative">
      <PlanChatAutoTextArea
        placeholder="Ask a question..."
        style={{ resize: "none", padding: "1rem 10rem 0.4rem 1rem" }}
      />
      <button
        className="button is-primary is-flex is-uppercase"
        style={{
          gap: "0.5rem",
          alignItems: "center",
          position: "absolute",
          bottom: "1rem",
          right: "1rem",
        }}
      >
        Reply <IconReply />
      </button>
    </div>
  );
};

export default PlanChatForm;
