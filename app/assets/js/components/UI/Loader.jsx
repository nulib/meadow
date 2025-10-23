import React from "react";

const UILoader = () => {
  const style = {
    display: "flex",
    margin: "16px 0",
  };

  const dotStyle = {
    width: "16px",
    height: "16px",
    margin: "8px 8px",
    borderRadius: "50%",
    backgroundColor: "#4e2a84",
    opacity: 1,
    animation: "bouncingLoader 0.6s infinite alternate",
    transform: "translateY(0)",
  };

  const secondDotStyle = {
    ...dotStyle,
    animationDelay: "0.2s",
  };

  const thirdDotStyle = {
    ...dotStyle,
    animationDelay: "0.4s",
  };

  // define bouncingLoader keyframes
  const styleSheet = document.styleSheets[0];
  const keyframes = `
    @keyframes bouncingLoader {
      to {
        background-color: #5091cd;    
        transform: translateY(-13px);
      }
    }`;
  styleSheet.insertRule(keyframes, styleSheet.cssRules.length);

  return (
    <div aria-label="loading" data-loading={true} role="status" style={style}>
      <div style={dotStyle}></div>
      <div style={secondDotStyle}></div>
      <div style={thirdDotStyle}></div>
    </div>
  );
};

export default UILoader;
