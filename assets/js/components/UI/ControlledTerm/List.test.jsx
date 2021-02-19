import React from "react";
import { render, screen } from "@testing-library/react";
import UIControlledTermList from "./List";

const items = [
  {
    term: {
      id: "http://vocab.getty.edu/ulan/500030701",
      label: "Kahlo, Frida",
    },
  },
  {
    term: {
      id: "http://vocab.getty.edu/ulan/500445403",
      label: "Aberdare, Henry Bruce, 2nd Baron",
    },
  },
  {
    term: {
      id: "http://vocab.getty.edu/ulan/500029268",
      label: "Pei, I. M.",
    },
  },
];

describe("UIControlledVocabList", () => {
  describe("Non-role items", () => {
    beforeEach(() => {
      render(<UIControlledTermList items={items} title="Creator" />);
    });

    it("renders UIControlledTermList", () => {
      expect(screen.getByTestId("controlled-term-list"));
      expect(screen.getAllByTestId("controlled-term-list-row")).toHaveLength(3);
    });

    it("renders the facet value label", () => {
      expect(
        screen.getAllByTestId("controlled-term-list-row")[0]
      ).toHaveTextContent(items[0].term.label);
    });

    it("renders an external link to the controlled term id url", () => {
      const firstElLink = screen.getAllByTestId("external-link")[0];
      expect(firstElLink).toHaveAttribute("target");
      expect(firstElLink).toHaveTextContent(items[0].term.id);
    });
  });
});
