import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import EditDiffRowForm from "./EditDiffRowForm";

// ---- Mocks ----
jest.mock("@js/context/code-list-context", () => ({
  useCodeLists: () => ({
    licenseData: {
      codeList: [
        { id: "http://creativecommons.org/licenses/by/4.0/", label: "CC BY", scheme: "license" },
      ],
    },
    rightsStatementData: {
      codeList: [
        { id: "http://rightsstatements.org/vocab/InC/1.0/", label: "In Copyright", scheme: "rights_statement" },
      ],
    },
    authorityData: { codeList: [] },
    marcData: { codeList: [] },
    subjectRoleData: { codeList: [] },
    notesData: { codeList: [] },
    relatedUrlData: { codeList: [] },
  }),
}));

jest.mock("@js/components/Plan/Panel/diff-helpers", () => ({
  isCodedTerm: (path) =>
    path === "descriptive_metadata.rights_statement" ||
    path === "descriptive_metadata.license",
  isTextSingle: (path) => path === "descriptive_metadata.title",
  isTextArray: (path) =>
    path === "descriptive_metadata.description" ||
    path === "descriptive_metadata.date_created",
}));

jest.mock("@js/services/metadata", () => ({
  prepFieldArrayItemsForPost: (values) => values.map((v) => v.metadataItem),
  prepEDTFforPost: (values) => values.map((v) => v.metadataItem),
  prepNotes: (v) => v,
  prepRelatedUrl: (v) => v,
  prepControlledTermInput: (_meta, values) => values,
  CONTROLLED_METADATA: [
    { name: "subject", scheme: "FAST_TOPIC" },
    { name: "contributor", scheme: "MARC_RELATOR" },
  ],
}));

jest.mock("@nulib/design-system", () => ({
  Button: ({ children, onClick, type, disabled, ...rest }) => (
    <button onClick={onClick} type={type || "button"} disabled={disabled} {...rest}>
      {children}
    </button>
  ),
}));

jest.mock("@js/components/UI/Form/Input", () => ({ name, placeholder, ...rest }) => (
  <input name={name} placeholder={placeholder} data-testid={`input-${name}`} {...rest} />
));

jest.mock("@js/components/UI/Form/Field", () => ({ label, children }) => (
  <div>
    <label>{label}</label>
    {children}
  </div>
));

jest.mock("@js/components/UI/Form/FieldArray", () => ({ name, label }) => (
  <div data-testid={`field-array-${name}`} data-label={label} />
));

jest.mock("@js/components/UI/Form/Select", () => ({ name, options, defaultValue }) => (
  <select name={name} data-testid={`select-${name}`} defaultValue={defaultValue}>
    {(options || []).map((o) => (
      <option key={o.id} value={o.id}>
        {o.label}
      </option>
    ))}
  </select>
));

jest.mock("@js/components/UI/Form/Note", () => () => <div data-testid="form-note" />);
jest.mock("@js/components/UI/Form/RelatedURL", () => () => <div data-testid="form-related-url" />);
jest.mock("@js/components/UI/Form/ControlledTermArray", () => ({ name, authorities }) => (
  <div data-testid={`controlled-term-array-${name}`} data-authority-count={authorities?.length ?? 0} />
));
jest.mock("@js/components/Icon", () => ({
  IconTrashCan: () => <span data-testid="icon-trash" />,
}));

const noop = jest.fn();

describe("EditDiffRowForm", () => {
  beforeEach(() => jest.clearAllMocks());

  test("renders nothing when change is null", () => {
    const { container } = render(
      <EditDiffRowForm change={null} isOpen={true} onSave={noop} onCancel={noop} />
    );
    expect(container).toBeEmptyDOMElement();
  });

  test("renders modal with title for plain text single field", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "1",
          method: "replace",
          path: "descriptive_metadata.title",
          label: "Title",
          value: "My Title",
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByText("Edit - Title")).toBeInTheDocument();
    expect(screen.getByTestId("input-value")).toBeInTheDocument();
  });

  test("modal is inactive when isOpen is false", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "1",
          method: "replace",
          path: "descriptive_metadata.title",
          label: "Title",
          value: "My Title",
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={false}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByRole("form")).not.toHaveClass("is-active");
  });

  test("renders UIFormFieldArray for plain text array field", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "2",
          method: "add",
          path: "descriptive_metadata.description",
          label: "Description",
          value: ["One", "Two"],
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByTestId("field-array-values")).toBeInTheDocument();
  });

  test("renders select with rights_statement options using camelCase code list key", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "3",
          method: "replace",
          path: "descriptive_metadata.rights_statement",
          label: "Rights Statement",
          value: { id: "http://rightsstatements.org/vocab/InC/1.0/", label: "In Copyright" },
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    const select = screen.getByTestId("select-value");
    expect(select).toBeInTheDocument();
    expect(screen.getByRole("option", { name: "In Copyright" })).toBeInTheDocument();
  });

  test("renders select with license options", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "4",
          method: "replace",
          path: "descriptive_metadata.license",
          label: "License",
          value: { id: "http://creativecommons.org/licenses/by/4.0/", label: "CC BY" },
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByRole("option", { name: "CC BY" })).toBeInTheDocument();
  });

  test("renders UIFormControlledTermArray for controlled field", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "5",
          method: "add",
          path: "descriptive_metadata.subject",
          label: "Subject",
          value: [],
          controlled: true,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByTestId("controlled-term-array-subject")).toBeInTheDocument();
  });

  test("delete mode renders items with remove buttons and warning for non-controlled field", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "6",
          method: "delete",
          path: "descriptive_metadata.description",
          label: "Description",
          value: ["Item A", "Item B"],
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByText("Review deletions - Description")).toBeInTheDocument();
    expect(screen.getByText("Item A")).toBeInTheDocument();
    expect(screen.getByText("Item B")).toBeInTheDocument();
    // Warning shown for non-controlled deletes
    expect(screen.getByText(/Deletions are only supported for controlled vocabulary fields/)).toBeInTheDocument();
  });

  test("delete mode: removing an item updates the list", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "7",
          method: "delete",
          path: "descriptive_metadata.subject",
          label: "Subject",
          value: [
            { term: { id: "t1", label: "Topic One" } },
            { term: { id: "t2", label: "Topic Two" } },
          ],
          controlled: true,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByText("Topic One")).toBeInTheDocument();
    // No warning for controlled field
    expect(screen.queryByText(/Deletions are only supported/)).not.toBeInTheDocument();

    const trashButtons = screen.getAllByTestId("icon-trash");
    fireEvent.click(trashButtons[0].closest("button"));

    expect(screen.queryByText("Topic One")).not.toBeInTheDocument();
    expect(screen.getByText("Topic Two")).toBeInTheDocument();
  });

  test("delete mode: removing all items shows empty message", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "8",
          method: "delete",
          path: "descriptive_metadata.subject",
          label: "Subject",
          value: [{ term: { id: "t1", label: "Only Item" } }],
          controlled: true,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    fireEvent.click(screen.getByTestId("icon-trash").closest("button"));
    expect(screen.getByText(/All items removed/)).toBeInTheDocument();
  });

  test("calls onCancel when close button clicked", () => {
    const onCancel = jest.fn();
    render(
      <EditDiffRowForm
        change={{
          id: "9",
          method: "replace",
          path: "descriptive_metadata.title",
          label: "Title",
          value: "Hello",
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={onCancel}
      />
    );

    fireEvent.click(screen.getByLabelText("close"));
    expect(onCancel).toHaveBeenCalledTimes(1);
  });

  test("Save changes button is disabled when form is not dirty", () => {
    render(
      <EditDiffRowForm
        change={{
          id: "10",
          method: "replace",
          path: "descriptive_metadata.title",
          label: "Title",
          value: "Hello",
          controlled: false,
          nestedCoded: false,
        }}
        isOpen={true}
        onSave={noop}
        onCancel={noop}
      />
    );

    expect(screen.getByTestId("submit-button")).toBeDisabled();
  });
});
