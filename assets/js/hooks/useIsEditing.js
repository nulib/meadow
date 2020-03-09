import { useState, useCallback } from "react";

export default function useIsEditing(initialValue) {
  const [isEditing, setIsEditing] = useState(initialValue);
  return [
    isEditing,
    useCallback((value) => {
      return setIsEditing(value);
    }),
  ];
}
