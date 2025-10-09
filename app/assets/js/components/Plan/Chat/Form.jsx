import React, { useState } from "react";
import { IconArrowDown, IconReply } from "@js/components/Icon";
import PlanChatAutoTextArea from "@js/components/Plan/Chat/AutoTextArea";

const PlanChatForm = ({
  showScrollButton,
  onScrollToBottom,
  onSubmitMessage,
}) => {
  const [message, setMessage] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    const trimmed = message.trim();
    if (!trimmed) return;
    onSubmitMessage?.(trimmed); // send up to parent
    setMessage(""); // clear input
  };

  return (
    <form className="field is-relative" onSubmit={handleSubmit}>
      {showScrollButton && (
        <button
          type="button"
          className="chat-transcript-scroll-to-bottom"
          onClick={onScrollToBottom}
          aria-label="Scroll to bottom"
        >
          <IconArrowDown />
          <span>Scroll to bottom</span>
        </button>
      )}

      <PlanChatAutoTextArea
        value={message}
        onChange={(e) => setMessage(e.target.value)}
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
        type="submit"
      >
        Reply <IconReply />
      </button>
    </form>
  );
};

export default React.memo(PlanChatForm);
