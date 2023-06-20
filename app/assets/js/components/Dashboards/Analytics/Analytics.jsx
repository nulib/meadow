import React from "react";
import { isMobile, isTablet, isBrowser } from "react-device-detect";

export default function DashboardsAnalytics() {
  return (
    <div>
      <iframe
        src="https://lookerstudio.google.com/embed/reporting/81e5dde0-561c-4f5e-9f4c-31acb8f28bb6/page/FW7"
        style={{
          border: "0",
          height: "auto",
          minHeight: isBrowser ? "4600px" : isTablet ? "2400px" : "1000px",
          width: "100%",
        }}
      ></iframe>
    </div>
  );
}
