import React from "react";
import IngestSheetAlert from "./Alert";
import { render } from "@testing-library/react";

const fileFail = {
  fileErrors: ["Invalid csv file: unexpected escape character..."],
  filename: "s3://dev-uploads/ingest_sheets/01DP6H30V4XV3Z5W4H782N2BXM.csv",
  id: "01DP6H3JWC6VGE7EH5KW1GHNQZ",
  ingestSheetRows: [],
  name: "Illegal file",
  state: [
    {
      name: "file",
      state: "FAIL",
    },
    {
      name: "rows",
      state: "PENDING",
    },
    {
      name: "overall",
      state: "FAIL",
    },
  ],
  status: "FILE_FAIL",
};

it("renders without crashing", () => {
  const { debug } = render(<IngestSheetAlert />);
});

it("displays danger alert with file fail message when the Ingest Sheet status is FILE_FAIL", () => {
  const { debug, getByTestId, getByText } = render(
    <IngestSheetAlert ingestSheet={fileFail} />
  );

  const alertElement = getByTestId("ui-alert");

  expect(alertElement).toBeInTheDocument();
  expect(alertElement).toHaveClass("is-danger");
  expect(getByText("File errors", { exact: false })).toBeInTheDocument();
  expect(
    getByText("Invalid csv file: unexpected escape character...", {
      exact: false,
    })
  ).toBeInTheDocument();
});

const rowFail = {
  fileErrors: ["Invalid header: something"],
  filename: "s3://dev-uploads/ingest_sheets/01DP6H30V4XV3Z5W4H782N2BXM.csv",
  id: "01DP6H3JWC6VGE7EH5KW1GHNQZ",
  ingestSheetRows: [],
  name: "Illegal header",
  state: [
    {
      name: "file",
      state: "PASS",
    },
    {
      name: "rows",
      state: "FAIL",
    },
    {
      name: "overall",
      state: "FAIL",
    },
  ],
  status: "ROW_FAIL",
};

it("renders without crashing", () => {
  render(<IngestSheetAlert />);
});

it("displays danger alert with row fail message when the Ingest Sheet status is ROW_FAIL", () => {
  const { getByTestId, getByText } = render(
    <IngestSheetAlert ingestSheet={rowFail} />
  );

  const alertElement = getByTestId("ui-alert");

  expect(alertElement).toBeInTheDocument();
  expect(alertElement).toHaveClass("is-danger");
  expect(
    getByText("File has failing rows", { exact: false })
  ).toBeInTheDocument();
});

const valid = {
  fileErrors: [],
  filename: "s3://dev-uploads/ingest_sheets/01DP6H30V4XV3Z5W4H782N2BXM.csv",
  id: "01DP6H3JWC6VGE7EH5KW1GHNQZ",
  ingestSheetRows: [],
  name: "Valid File",
  state: [
    {
      name: "file",
      state: "PASS",
    },
    {
      name: "rows",
      state: "PASS",
    },
    {
      name: "overall",
      state: "PASS",
    },
  ],
  status: "VALID",
};

it("renders without crashing", () => {
  const { debug } = render(<IngestSheetAlert />);
});

it("displays success alert with valid file message when the Ingest Sheet status is VALID", () => {
  const { debug, getByTestId, getByText } = render(
    <IngestSheetAlert ingestSheet={valid} />
  );

  const alertElement = getByTestId("ui-alert");

  expect(alertElement).toBeInTheDocument();
  expect(alertElement).toHaveClass("is-success");
  expect(
    getByText("the ingest sheet is valid", { exact: false })
  ).toBeInTheDocument();
  expect(
    getByText("All checks have passed and the ingest sheet is valid.", {
      exact: false,
    })
  ).toBeInTheDocument();
});

const approved = {
  fileErrors: [],
  filename: "s3://dev-uploads/ingest_sheets/01DP6H30V4XV3Z5W4H782N2BXM.csv",
  id: "01DP6H3JWC6VGE7EH5KW1GHNQZ",
  ingestSheetRows: [],
  name: "Approved File",
  state: [
    {
      name: "file",
      state: "PASS",
    },
    {
      name: "rows",
      state: "PASS",
    },
    {
      name: "overall",
      state: "PASS",
    },
  ],
  status: "APPROVED",
};

it("renders without crashing", () => {
  const { debug } = render(<IngestSheetAlert />);
});

const completed = {
  fileErrors: [],
  filename: "s3://dev-uploads/ingest_sheets/01DP6H30V4XV3Z5W4H782N2BXM.csv",
  id: "01DP6H3JWC6VGE7EH5KW1GHNQZ",
  ingestSheetRows: [],
  name: "Completed File",
  state: [
    {
      name: "file",
      state: "PASS",
    },
    {
      name: "rows",
      state: "PASS",
    },
    {
      name: "overall",
      state: "PASS",
    },
  ],
  status: "COMPLETED",
};

it("renders without crashing", () => {
  const { debug } = render(<IngestSheetAlert />);
});

it("displays success alert with completed message when the Ingest Sheet status is COMPLETED", () => {
  const { debug, getByTestId, getByText } = render(
    <IngestSheetAlert ingestSheet={completed} />
  );

  const alertElement = getByTestId("ui-alert");

  expect(alertElement).toBeInTheDocument();
  expect(alertElement).toHaveClass("is-success");
  expect(getByText("Ingestion Complete", { exact: false })).toBeInTheDocument();
  expect(
    getByText("Ingestion complete, and all Works have been created.", {
      exact: false,
    })
  ).toBeInTheDocument();
});

const deleted = {
  fileErrors: [],
  filename: "s3://dev-uploads/ingest_sheets/01DP6H30V4XV3Z5W4H782N2BXM.csv",
  id: "01DP6H3JWC6VGE7EH5KW1GHNQZ",
  ingestSheetRows: [],
  name: "Deleted File",
  state: [
    {
      name: "file",
      state: "PASS",
    },
    {
      name: "rows",
      state: "PASS",
    },
    {
      name: "overall",
      state: "PASS",
    },
  ],
  status: "DELETED",
};

it("renders without crashing", () => {
  const { debug } = render(<IngestSheetAlert />);
});

it("displays success alert with completed message when the Ingest Sheet status is DELETED", () => {
  const { debug, getByTestId, getByText } = render(
    <IngestSheetAlert ingestSheet={deleted} />
  );

  const alertElement = getByTestId("ui-alert");

  expect(alertElement).toBeInTheDocument();
  expect(alertElement).toHaveClass("is-danger");
  expect(
    getByText("Ingest sheet no longer exists", { exact: false })
  ).toBeInTheDocument();
});
