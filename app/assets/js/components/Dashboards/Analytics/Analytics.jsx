import React from "react";
import { isMobile, isTablet, isBrowser } from "react-device-detect";

export default function DashboardsAnalytics() {
  return (
    <div>
      <iframe
        src="https://datastudio.google.com/embed/reporting/45a94985-73a2-4219-b8d8-e51c605eb61a/page/FW7"
        frameBorder="0"
        style={{
          border: "0",
          height: "auto",
          minHeight: isBrowser ? "4600px" : isTablet ? "2400px" : "1000px",
          width: "100%",
        }}
        allowFullScreen
      ></iframe>
    </div>
  );
}
