import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";

import { CodeListProvider } from "@js/context/code-list-context";
import React from "react";
import WorkAdministrativeTabsGeneral from "./General";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const props = {
  administrativeMetadata: {
    libraryUnit: {
      id: "FACULTY_COLLECTIONS",
      label: "Faculty Collections",
    },
    preservationLevel: {
      id: "1",
      label: "Level 1",
    },
    projectCycle: "Cycle here",
    projectDesc: ["Description"],
    projectManager: ["Manager here"],
    projectName: ["Job name here"],
    projectProposer: ["Proposer here"],
    projectTaskNumber: ["Task number here"],
    status: {
      id: "IN PROGRESS",
      label: "In Progress",
    },
  },
  isEditing: false,
  published: true,
  visibility: {
    id: "RESTRICTED",
    label: "Private",
  },
};

describe("Work Administrative General metadata component", () => {
  /**
   * This setUpTests() pattern allows us to pass in different initial states
   * of the component to test how form elements render out
   */
  function setUpTests(props) {
    const Wrapped = withReactHookForm(WorkAdministrativeTabsGeneral, {
      ...props,
    });
    return renderWithRouterApollo(
      <CodeListProvider>
        <Wrapped />
      </CodeListProvider>,
      {
        mocks: [...allCodeListMocks],
      }
    );
  }

  it("renders all General metadata items", async () => {
    setUpTests(props);

    const libraryUnitEl = await screen.findByTestId("library-unit-wrapper");
    const preservationLevelEl = await screen.findByTestId(
      "preservation-level-wrapper"
    );
    const statusEl = await screen.findByTestId("status-wrapper");
    const visibilityEl = await screen.findByTestId("visibility-wrapper");

    expect(libraryUnitEl).toHaveTextContent("Faculty Collections");
    expect(preservationLevelEl).toHaveTextContent("Level 1");
    expect(statusEl).toHaveTextContent("In Progress");
    expect(visibilityEl).toHaveTextContent("Private");
  });
});
