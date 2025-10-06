import React, { useEffect, useRef, useState } from "react";
import PlanChatForm from "@js/components/Plan/Chat/Form";
import PlanChatTranscript from "@js/components/Plan/Chat/Transcript";
import { mockChatMessages } from "@js/components/Plan/Chat/mockChatMessages";

const NEAR_PX = 80; // how close to bottom to consider "at bottom"

const PlanChat = () => {
  const scrollerRef = useRef(null);
  const [messages, setMessages] = useState(mockChatMessages);
  const [isAtBottom, setIsAtBottom] = useState(true);

  const scrollToBottom = (smooth = true) => {
    const el = scrollerRef?.current;
    if (!el) return;

    if (typeof el.scrollTo === "function") {
      el.scrollTo({
        top: el.scrollHeight,
        behavior: smooth ? "smooth" : "auto",
      });
    } else {
      // jsdom/older env fallback
      el.scrollTop = el.scrollHeight ?? 0;
    }
  };

  // Handle new message submission
  const handleSubmitMessage = (text) => {
    const newMessage = { content: text, isUser: true, type: "message" };
    setMessages((prev) => [...prev, newMessage]);
    scrollToBottom(true);
  };

  const nearBottom = () => {
    const el = scrollerRef.current;
    if (!el) return true;
    return el.scrollHeight - el.scrollTop - el.clientHeight <= NEAR_PX;
  };

  // Toggle button while user scrolls
  useEffect(() => {
    const el = scrollerRef.current;
    if (!el) return;

    let rafId;
    const onScroll = () => {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => setIsAtBottom(nearBottom()));
    };

    el.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      el.removeEventListener("scroll", onScroll);
      cancelAnimationFrame(rafId);
    };
  }, []);

  // Auto-scroll on new messages if already near bottom
  useEffect(() => {
    if (nearBottom()) {
      setIsAtBottom(true);
      scrollToBottom(false);
    } else {
      setIsAtBottom(false);
    }
  }, [mockChatMessages]); // replace with real messages state later

  // Keep pinned when content height changes
  useEffect(() => {
    const el = scrollerRef.current;
    if (!el || !("ResizeObserver" in window)) return;
    const ro = new ResizeObserver(() => {
      if (nearBottom()) {
        setIsAtBottom(true);
        scrollToBottom(true);
      }
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  return (
    <div className="chat">
      <div ref={scrollerRef} className="chat-body">
        <PlanChatTranscript messages={messages} />
      </div>

      <PlanChatForm
        showScrollButton={!isAtBottom}
        onScrollToBottom={() => scrollToBottom(true)}
        onSubmitMessage={handleSubmitMessage}
      />
    </div>
  );
};

export default PlanChat;
