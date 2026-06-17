// PlanPanelChangesDiff.test.jsx
import React from "react";
import { render, screen, within } from "@testing-library/react";

// ---- Mocks that the factories will reference (must be prefixed with "mock") ----
const mockToArray = jest.fn((v) => (Array.isArray(v) ? v : v ? [v] : []));
const mockToRows = jest.fn();
const mockIsCodedTerm = jest.fn(
  (path) =>
    path === "descriptive_metadata.rights_statement" ||
    path === "descriptive_metadata.license",
);
const mockGetCurrentValue = jest.fn(() => undefined);
const mockComputeRowDiff = jest.fn(() => ({
  kind: "scalar",
  current: "",
  resulting: "",
  changed: false,
}));

jest.mock("@apollo/client/react", () => ({
  useMutation: () => [jest.fn()],
}));

jest.mock("@nulib/design-system", () => ({
  Tag: ({ children }) => <span data-testid="tag">{children}</span>,
  Button: ({ children, onClick, type, ...rest }) => (
    <button onClick={onClick} type={type || "button"} {...rest}>
      {children}
    </button>
  ),
}));

jest.mock("@js/components/UI/ControlledTerm/List", () => ({
  __esModule: true,
  default: ({ title, items }) => (
    <div data-testid="ctl" data-title={title} data-count={items?.length ?? 0} />
  ),
}));

jest.mock("@js/components/UI/Modal/Delete", () => ({
  __esModule: true,
  default: () => <div data-testid="modal-delete" />,
}));

jest.mock("@js/components/Icon", () => ({
  IconEdit: () => <span data-testid="icon-edit" />,
  IconDelete: () => <span data-testid="icon-delete" />,
}));

jest.mock("../plan.gql", () => ({ UPDATE_PLAN_CHANGE: "UPDATE_PLAN_CHANGE" }));

jest.mock("@js/components/Plan/Panel/EditDiffRowForm", () => ({
  __esModule: true,
  default: () => <div data-testid="edit-diff-row-form" />,
}));

jest.mock("@js/components/Plan/Panel/diff-helpers", () => ({
  toArray: (...args) => mockToArray(...args),
  toRows: (...args) => mockToRows(...args),
  isCodedTerm: (...args) => mockIsCodedTerm(...args),
  getCurrentValue: (...args) => mockGetCurrentValue(...args),
  computeRowDiff: (...args) => mockComputeRowDiff(...args),
}));

const { default: PlanPanelChangesDiff } = await import("./Diff");

beforeEach(() => {
  jest.clearAllMocks();
});

// Status "PROPOSED" keeps existing tests in the editable single-column table
const baseProposed = {
  status: "PROPOSED",
  add: {},
  delete: null,
  replace: null,
};

describe("PlanPanelChangesDiff", () => {
  test("renders a controlled row using UIControlledTermList with coerced items (array)", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-subject",
          method: "add",
          path: "descriptive_metadata.subject",
          label: "Subject",
          value: { term: { id: "id1", label: "Label 1" } }, // coerced to array
          controlled: true,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    expect(screen.getByTestId("tag")).toHaveTextContent("Add");
    const ctl = screen.getByTestId("ctl");
    expect(ctl).toHaveAttribute("data-title", "Subject");
    expect(ctl).toHaveAttribute("data-count", "1");
    expect(mockToArray).toHaveBeenCalledTimes(1);
  });

  test("renders non-controlled primitive values directly", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-title",
          method: "add",
          path: "descriptive_metadata.title",
          label: "Title",
          value: "St. Denis",
          controlled: false,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    const row = screen.getByRole("row", { name: /add title st\. denis/i });
    const cells = within(row).getAllByRole("cell");
    expect(cells[0]).toHaveTextContent("Add");
    expect(cells[1]).toHaveTextContent("Title");
    expect(cells[2]).toHaveTextContent("St. Denis");
    expect(screen.queryByTestId("ctl")).not.toBeInTheDocument();
  });

  test("renders non-controlled arrays of primitives as bullet list", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-description",
          method: "add",
          path: "descriptive_metadata.description",
          label: "Description",
          value: ["One", "Two", "Three"],
          controlled: false,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    const list = screen.getByRole("list");
    const items = within(list).getAllByRole("listitem");
    expect(items.map((li) => li.textContent)).toEqual(["One", "Two", "Three"]);
  });

  test("renders non-controlled arrays of objects as bullet list of JSON items", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-notes",
          method: "add",
          path: "descriptive_metadata.notes",
          label: "Notes",
          value: [{ foo: 1 }, { bar: 2 }],
          controlled: false,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    const items = within(screen.getByRole("list")).getAllByRole("listitem");
    expect(items[0]).toHaveTextContent('{"foo":1}');
    expect(items[1]).toHaveTextContent('{"bar":2}');
  });

  test("renders non-controlled plain objects as JSON", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-generic-obj",
          method: "add",
          path: "descriptive_metadata.generic",
          label: "Generic",
          value: { a: 1, b: "x" },
          controlled: false,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    const row = screen.getByRole("row", { name: /add generic/i });
    const cells = within(row).getAllByRole("cell");
    expect(cells[2]).toHaveTextContent('{"a":1,"b":"x"}');
  });

  test("renders Date values as ISO string", () => {
    const dt = new Date("2020-01-02T03:04:05Z");
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-date",
          method: "add",
          path: "descriptive_metadata.date_created",
          label: "Date Created",
          value: dt,
          controlled: false,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);
    expect(screen.getByText(dt.toISOString())).toBeInTheDocument();
  });

  test("renders em dash for null/undefined and empty array", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "add-null",
          method: "add",
          path: "descriptive_metadata.abstract",
          label: "Abstract",
          value: null,
          controlled: false,
        },
      ])
      .mockReturnValueOnce([
        {
          id: "add-empty",
          method: "add",
          path: "descriptive_metadata.caption",
          label: "Caption",
          value: [],
          controlled: false,
        },
      ])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);
    expect(screen.getAllByText("—")).toHaveLength(2);
  });

  test("sorts rows by label then method", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "1",
          method: "replace",
          path: "dm.b",
          label: "B Label",
          value: "x",
          controlled: false,
        },
      ])
      .mockReturnValueOnce([
        {
          id: "2",
          method: "add",
          path: "dm.a",
          label: "A Label",
          value: "y",
          controlled: false,
        },
      ])
      .mockReturnValueOnce([
        {
          id: "3",
          method: "delete",
          path: "dm.a",
          label: "A Label",
          value: "z",
          controlled: false,
        },
      ]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    const bodyRows = screen.getAllByRole("row").slice(1);
    const labels = bodyRows.map(
      (r) => within(r).getAllByRole("cell")[1].textContent,
    );
    const methods = bodyRows.map(
      (r) => within(r).getAllByRole("cell")[0].textContent,
    );

    expect(labels).toEqual(["A Label", "A Label", "B Label"]);
    expect(methods).toEqual(["Add", "Delete", "Replace"]);
  });

  test("renders one UIControlledTermList per controlled row", () => {
    mockToRows
      .mockReturnValueOnce([
        {
          id: "c1",
          method: "add",
          path: "descriptive_metadata.subject",
          label: "Subject",
          value: [{ term: { id: "t1", label: "L1" } }],
          controlled: true,
        },
        {
          id: "c2",
          method: "add",
          path: "descriptive_metadata.creator",
          label: "Creator",
          value: [{ term: { id: "t2", label: "L2" } }],
          controlled: true,
        },
      ])
      .mockReturnValueOnce([])
      .mockReturnValueOnce([]);

    render(<PlanPanelChangesDiff proposedChanges={baseProposed} />);

    const ctls = screen.getAllByTestId("ctl");
    expect(ctls).toHaveLength(2);

    const titles = ctls.map((el) => el.getAttribute("data-title"));
    expect(titles).toEqual(expect.arrayContaining(["Subject", "Creator"]));
  });

  // -----------------------------------------------------------------------
  // APPROVED state: before→after diff table
  // -----------------------------------------------------------------------
  describe("approved diff view (status !== PROPOSED)", () => {
    const approvedProposed = {
      status: "APPROVED",
      add: {},
      delete: null,
      replace: null,
    };

    test("renders Current value / New value column headers instead of Proposed Value", () => {
      mockToRows
        .mockReturnValueOnce([])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      expect(
        screen.getByRole("columnheader", { name: /current value/i }),
      ).toBeInTheDocument();
      expect(
        screen.getByRole("columnheader", { name: /new value/i }),
      ).toBeInTheDocument();
      expect(
        screen.queryByRole("columnheader", { name: /proposed value/i }),
      ).not.toBeInTheDocument();
    });

    test("does not render edit/delete action buttons", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "replace-title",
            method: "replace",
            path: "descriptive_metadata.title",
            label: "Title",
            value: "New Title",
            controlled: false,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "scalar",
        current: "Old Title",
        resulting: "New Title",
        changed: true,
      });

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      expect(
        screen.queryByTestId("button-edit-plan-change-row"),
      ).not.toBeInTheDocument();
      expect(
        screen.queryByTestId("button-delete-plan-change-row"),
      ).not.toBeInTheDocument();
    });

    test("renders scalar diff: current and new values in separate cells", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "replace-title",
            method: "replace",
            path: "descriptive_metadata.title",
            label: "Title",
            value: "New Title",
            controlled: false,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "scalar",
        current: "Old Title",
        resulting: "New Title",
        changed: true,
      });

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      const rows = screen.getAllByRole("row");
      const dataRow = rows[1]; // skip header
      const cells = within(dataRow).getAllByRole("cell");
      expect(cells[2]).toHaveTextContent("Old Title");
      expect(cells[3]).toHaveTextContent("New Title");
    });

    test("renders list diff: added items carry data-diff-status=added", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "add-subject",
            method: "add",
            path: "descriptive_metadata.subject",
            label: "Subject",
            value: [{ term: { id: "s2", label: "Photographs" } }],
            controlled: true,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "list",
        current: [{ key: "s1", display: "Maps", status: "unchanged" }],
        resulting: [
          { key: "s1", display: "Maps", status: "unchanged" },
          { key: "s2", display: "Photographs", status: "added" },
        ],
      });

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      const addedItems = document.querySelectorAll(
        '[data-diff-status="added"]',
      );
      expect(addedItems).toHaveLength(1);
      expect(addedItems[0]).toHaveTextContent("Photographs");
    });

    test("renders list diff: removed items carry data-diff-status=removed", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "delete-subject",
            method: "delete",
            path: "descriptive_metadata.subject",
            label: "Subject",
            value: [{ term: { id: "s1", label: "Maps" } }],
            controlled: true,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "list",
        current: [{ key: "s1", display: "Maps", status: "removed" }],
        resulting: [],
      });

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      const removedItems = document.querySelectorAll(
        '[data-diff-status="removed"]',
      );
      expect(removedItems).toHaveLength(1);
      expect(removedItems[0]).toHaveTextContent("Maps");
    });

    test("renders authority URI in parentheses for items with an id", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "add-subject",
            method: "add",
            path: "descriptive_metadata.subject",
            label: "Subject",
            value: [
              {
                term: {
                  id: "http://vocab.getty.edu/aat/300127173",
                  label: "Aerial photographs",
                },
              },
            ],
            controlled: true,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "list",
        current: [],
        resulting: [
          {
            key: "http://vocab.getty.edu/aat/300127173",
            display: "Aerial photographs",
            id: "http://vocab.getty.edu/aat/300127173",
            status: "added",
          },
        ],
      });

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      expect(
        screen.getByText("http://vocab.getty.edu/aat/300127173", {
          exact: false,
        }),
      ).toBeInTheDocument();
      // id is wrapped in parens
      expect(
        screen.getByText(/\(http:\/\/vocab\.getty\.edu\/aat\/300127173\)/),
      ).toBeInTheDocument();
    });

    test("does not render a parenthetical id for non-controlled items (no id field)", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "add-description",
            method: "add",
            path: "descriptive_metadata.description",
            label: "Description",
            value: ["New line"],
            controlled: false,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "list",
        current: [],
        resulting: [{ key: "New line", display: "New line", status: "added" }],
      });

      render(<PlanPanelChangesDiff proposedChanges={approvedProposed} />);

      // The term id span should not appear
      expect(
        document.querySelector(".plan-diff-term-id"),
      ).not.toBeInTheDocument();
    });

    test("calls getCurrentValue with the row path and currentWork", () => {
      mockToRows
        .mockReturnValueOnce([
          {
            id: "replace-title",
            method: "replace",
            path: "descriptive_metadata.title",
            label: "Title",
            value: "New",
            controlled: false,
          },
        ])
        .mockReturnValueOnce([])
        .mockReturnValueOnce([]);

      mockComputeRowDiff.mockReturnValue({
        kind: "scalar",
        current: "Old",
        resulting: "New",
        changed: true,
      });

      const currentWork = { descriptiveMetadata: { title: "Old" } };
      render(
        <PlanPanelChangesDiff
          proposedChanges={approvedProposed}
          currentWork={currentWork}
        />,
      );

      expect(mockGetCurrentValue).toHaveBeenCalledWith(
        "descriptive_metadata.title",
        currentWork,
      );
    });
  });
});
