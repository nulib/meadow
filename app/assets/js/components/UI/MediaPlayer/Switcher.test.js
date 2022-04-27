import React from "react";
import { render, screen } from "@testing-library/react";
import UIMediaPlayerSwitcher from "@js/components/UI/MediaPlayer/Switcher";
import { WorkProvider } from "@js/context/work-context";

const fileSets = [
  {
    id: "1149a688-dba9-4555-9bc0-bd30bd9c5269",
    coreMetadata: {
      label: "Ima label 1",
    },
    representativeImageUrl: "",
  },
  {
    id: "2149a688-dba9-4555-9bc0-bd30bd9c5269",
    coreMetadata: {
      label: "Ima label 2",
    },
    representativeImageUrl: "",
  },
  {
    id: "3149a688-dba9-4555-9bc0-bd30bd9c5269",
    coreMetadata: {
      label: "Ima label 3",
    },
    representativeImageUrl: "",
  },
];

describe("UIMediaPlayerSwitcher component", () => {
  beforeEach(() => {
    render(
      <WorkProvider>
        <UIMediaPlayerSwitcher fileSets={fileSets} />
      </WorkProvider>
    );
  });

  it("renders", () => {
    expect(screen.getByTestId("media-player-switcher"));
  });

  it("renders the correct select options for filesets", () => {
    const options = screen.getAllByTestId("switcher-option");
    expect(options).toHaveLength(3);
    expect(options[1]).toHaveTextContent("Ima label 2");
    expect(options[1]).toHaveValue("2149a688-dba9-4555-9bc0-bd30bd9c5269");
  });
});
