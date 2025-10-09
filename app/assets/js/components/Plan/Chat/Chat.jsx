import React, { useEffect, useRef, useState } from "react";
import PlanChatForm from "@js/components/Plan/Chat/Form";
import PlanChatTranscript from "@js/components/Plan/Chat/Transcript";
import { useSendChatMessage } from "@js/hooks/useSendChatMessage";
import { useChatResponse } from "@js/hooks/useChatResponse";
import { v4 as uuidv4 } from "uuid";

const conversationId = uuidv4();

const PlanChat = ({ initialMessage, query }) => {
  const scrollerRef = useRef(null);
  const [messages, setMessages] = useState([initialMessage]);
  const [isAtBottom, setIsAtBottom] = useState(true);

  const { data: chatResponseMessage, error: subscriptionError } =
    useChatResponse(conversationId);

  const { sendChatMessage, error: sendError } = useSendChatMessage();

  const scrollToBottom = (smooth = true) => {
    const el = scrollerRef?.current;
    if (!el) return;

    if (typeof el.scrollTo === "function") {
      el.scrollTo({
        top: el.scrollHeight,
        behavior: smooth ? "smooth" : "auto",
      });
    } else {
      el.scrollTop = el.scrollHeight ?? 0;
    }
  };

  const nearBottom = () => {
    const el = scrollerRef.current;
    if (!el) return true;
    return el.scrollHeight - el.scrollTop - el.clientHeight <= 80;
  };

  const handleSubmitMessage = async (text) => {
    const newMessage = { content: text, isUser: true, type: "message" };
    setMessages((prev) => [...prev, newMessage]);

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

    scrollToBottom(true);
  };

  useEffect(() => {
    if (!chatResponseMessage) return;
    setMessages((prev) => [
      ...prev,
      { content: chatResponseMessage.message, isUser: false, type: "message" },
    ]);
    if (isAtBottom) scrollToBottom(true);
  }, [chatResponseMessage]);

  /**
   * Surface errors from hooks as chat messages
   */
  const lastErrorRef = useRef(null);
  useEffect(() => {
    const err = sendError || subscriptionError;
    if (!err) return;
    const msg = err?.message || String(err);
    if (msg && msg !== lastErrorRef.current) {
      setMessages((prev) => [
        ...prev,
        { content: msg, isUser: false, type: "error" },
      ]);
      lastErrorRef.current = msg;
    }
  }, [sendError, subscriptionError]);

  /**
   * Logic to track if user is near bottom of scroll
   * and update isAtBottom state accordingly
   */
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

  /**
   * Scroll handling when messages change
   */
  useEffect(() => {
    if (nearBottom()) {
      setIsAtBottom(true);
      scrollToBottom(false);
    } else {
      setIsAtBottom(false);
    }
  }, [messages]);

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
