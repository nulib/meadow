import React from "react";
import { FaLevelUpAlt } from "react-icons/fa";

export default function IconEnter(props) {
  return (
    <FaLevelUpAlt
      {...props}
      style={{
        transform: "rotate(90deg) scaleY(-1)",
      }}
    />
  );
}
