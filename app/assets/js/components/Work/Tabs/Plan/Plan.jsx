import React from "react";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import Plan from "@js/components/Plan/Plan";

const WorkTabsPlan = () => {
  return (
    <div data-testid="preservation-tab">
      <UITabsStickyHeader title="Automatically Edit and Enhance">
        <>other options? recipe dropdown?</>
      </UITabsStickyHeader>
      <div>
        <Plan />
      </div>
    </div>
  );
};

export default WorkTabsPlan;
