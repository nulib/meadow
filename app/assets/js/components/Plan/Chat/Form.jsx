import React, { useEffect, useRef, useState } from "react";
import { IconArrowDown, IconList, IconReply } from "@js/components/Icon";
import PlanChatAutoTextArea from "@js/components/Plan/Chat/AutoTextArea";
import { recipes } from "@js/components/Plan/recipes";

const PlanChatForm = ({
  showScrollButton,
  onScrollToBottom,
  onSubmitMessage,
}) => {
  const [message, setMessage] = useState("");
  const [showRecipes, setShowRecipes] = useState(false);
  const recipesRef = useRef(null);

  const handleSubmit = (e) => {
    e.preventDefault();
    const trimmed = message.trim();
    if (!trimmed) return;
    onSubmitMessage?.(trimmed); // send up to parent
    setMessage(""); // clear input
    setShowRecipes(false);
  };

  const handleSelectRecipe = (recipe) => {
    setMessage(recipe);
    setShowRecipes(false);
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    if (!showRecipes) return;

    const handleClickOutside = (event) => {
      if (recipesRef.current && !recipesRef.current.contains(event.target)) {
        setShowRecipes(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [showRecipes]);

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

      <div
        ref={recipesRef}
        style={{ display: "flex", gap: "0.5rem", alignItems: "flex-start" }}
      >
        {showRecipes && (
          <div className="chat-recipes-dropdown">
            {recipes.map((recipe, index) => (
              <button
                key={index}
                type="button"
                className="chat-recipe-item"
                onClick={() => handleSelectRecipe(recipe)}
              >
                {recipe}
              </button>
            ))}
          </div>
        )}

        <button
          type="button"
          className="button chat-recipes-button"
          onClick={() => setShowRecipes(!showRecipes)}
          title={showRecipes ? "Hide recipes" : "Show recipe prompts"}
        >
          <IconList />
        </button>

        <div style={{ flex: 1, position: "relative" }}>
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
        </div>
      </div>
    </form>
  );
};

export default React.memo(PlanChatForm);
