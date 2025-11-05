import React from "react";

function IconBehaviorPaged(props) {
  return (
    <svg {...props} viewBox="0 0 24 24" fill="currentColor" width="1em" height="1em">
      <path d="M4 3 C3.45 3 3 3.45 3 4 L3 20 C3 20.55 3.45 21 4 21 L11 21 L11 3 Z" />
      <path d="M13 3 L13 21 L20 21 C20.55 21 21 20.55 21 20 L21 4 C21 3.45 20.55 3 20 3 Z" />
      <line x1="12" y1="3" x2="12" y2="21" stroke="currentColor" strokeWidth="1" />
    </svg>
  );
}

export default IconBehaviorPaged;
