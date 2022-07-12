import { screen } from "@testing-library/react";
import WorkAdministrativeTabsGeneral from "./General";
import React from "react";
import { CodeListProvider } from "@js/context/code-list-context";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
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
  readingRoom: true,
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

  describe("reading room form input", () => {
    it("displays default value and checks on and off", async () => {
      const user = userEvent.setup();
      // Set form to "edit" mode
      setUpTests({ ...props, isEditing: true });

      const readingRoomEl = await screen.findByTestId("checkbox-reading-room");
      expect(readingRoomEl).toBeChecked();

      await user.click(screen.getByTestId("label-reading-room"));
      expect(screen.getByTestId("checkbox-reading-room")).not.toBeChecked();
    });
  });
});
