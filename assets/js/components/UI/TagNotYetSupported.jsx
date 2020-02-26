import React from "react";
import { defaultTypeResolver } from "graphql";

const UITagNotYetSupported = ({ label = "Not yet supported" }) => (
  <span className="tag">{label}</span>
);

export default UITagNotYetSupported;
