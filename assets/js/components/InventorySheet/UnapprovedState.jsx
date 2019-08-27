import React from "react";
import PropTypes from "prop-types";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";
import CheckMarkIcon from "../../../css/fonts/zondicons/checkmark.svg";
import CloseIcon from "../../../css/fonts/zondicons/close.svg";

const mockData = [
  {
    workAccessionNumber: "Donohue_001",
    filesets: [
      {
        accessionNumber: "Donohue_001_01",
        content: "painting1.JPG, Letter, page 1, Dear Sir, recto"
      },
      {
        accessionNumber: "Donohue_001_02",
        content: "painting2.JPG, Letter, page 1, Dear Sir, verso, blank"
      },
      {
        accessionNumber: "Donohue_001_03",
        content: "painting3.JPG, Letter, page 2, If these papers, recto"
      }
    ]
  },
  {
    workAccessionNumber: "Donohue_002",
    filesets: [
      {
        accessionNumber: "Donohue_002_01",
        content: "painting7.JPG, Photo, two children praying"
      },
      {
        accessionNumber: "Donohue_002_02",
        content: "painting6.JPG, Verso"
      },
      {
        accessionNumber: "Donohue_002_03",
        content: "painting7.JPG, Photo, two children praying"
      }
    ]
  }
];

const InventorySheetUnapprovedState = ({ validations }) => {
  return (
    <>
      {validations.map(validation => (
        <div key={validation.row}>{validation.fields.map(field => field.value).join("; ")}</div>
      ))}

      <h2>What it might look like...?</h2>

      {mockData.map(work => (
        <table key={work.workAccessionNumber} className="mb-6">
          <thead>
            <tr>
              <th colSpan="2">{work.workAccessionNumber}</th>
            </tr>
          </thead>
          <tbody>
            {work.filesets.map(fileset => (
              <tr key={fileset.accessionNumber}>
                <td className="w-3/12 pl-3">{fileset.accessionNumber}</td>
                <td>{fileset.content}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ))}

      <ButtonGroup>
        <UIButton>
          <CheckMarkIcon className="icon" />
          Approve inventory sheet
        </UIButton>
        <UIButton classes="btn-clear">
          <CloseIcon className="icon" />
          Delete job and re-upload inventory sheet
        </UIButton>
      </ButtonGroup>
    </>
  );
};

InventorySheetUnapprovedState.propTypes = {
  validations: PropTypes.arrayOf(PropTypes.object)
};

export default InventorySheetUnapprovedState;
