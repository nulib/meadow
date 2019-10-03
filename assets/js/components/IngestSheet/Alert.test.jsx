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
      state: "FAIL"
    },
    {
      name: "rows",
      state: "PENDING"
    },
    {
      name: "overall",
      state: "FAIL"
    }
  ],
  status: "FILE_FAIL"
};

it("renders without crashing", () => {
  const { debug } = render(<IngestSheetAlert />);
});

it("displays danger alert with file fail message when the Ingest Sheet status is FILE_FAIL", () => {
  const { debug, getByTestId, getByText } = render(
    <IngestSheetAlert ingestSheet={fileFail} />
  );
  // This will show you the rendered UI output, which is helpful to debug or see what's going on.  Remove before committing.
  debug();

  const alertElement = getByTestId("ui-alert");

  expect(alertElement).toBeInTheDocument();
  expect(alertElement).toHaveClass("danger");
  expect(getByText("File errors")).toBeInTheDocument();
  expect(
    getByText("Invalid csv file: unexpected escape character...")
  ).toBeInTheDocument();
});
