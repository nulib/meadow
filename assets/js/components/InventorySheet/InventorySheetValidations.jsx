import React from "react";
import gql from "graphql-tag";
import { Mutation } from "react-apollo";
import PropTypes from "prop-types";
import DoMutation from "../DoMutate";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";

const SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS = gql`
  subscription IngestJobValidationUpdate($ingestJobId: String!) {
    ingestJobValidationUpdate(ingestJobId: $ingestJobId) {
      id
      object {
        content
        errors
        status
      }
    }
  }
`;

const START_VALIDATION = gql`
  mutation ValidateIngestJob($id: String!) {
    validateIngestJob(ingestJobId: $id) {
      message
    }
  }
`;

class InventorySheetValidations extends React.Component {
  static propTypes = {
    inventorySheetId: PropTypes.string.isRequired,
    ingestJobValidations: PropTypes.object.isRequired,
    subscribeToInventorySheetValidations: PropTypes.func.isRequired
  };

  state = { hasErrors: true, showAllRows: false };

  componentDidMount() {
    this.props.subscribeToInventorySheetValidations({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS,
      variables: { ingestJobId: this.props.inventorySheetId },
      updateQuery: this.handleValidationUpdate
    });
  }

  jobHasErrors = ({ validations }) => {
    return validations.filter(row => row.object.status === "fail").length > 0;
  };

  handleShowAllRowsClick = e => {
    this.setState({ showAllRows: !this.state.showAllRows });
  };

  handleValidationUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;
    const newValidation = subscriptionData.data.ingestJobValidationUpdate;

    const index = prev.ingestJobValidations.validations.findIndex(
      ({ id }) => id === newValidation.id
    );

    let updatedValidations;
    if (index === -1) {
      updatedValidations = [
        newValidation,
        ...prev.ingestJobValidations.validations
      ];
    } else {
      updatedValidations = prev.ingestJobValidations.validations;
      updatedValidations[index] = newValidation;
    }

    const ingestJobValidations = {
      ...prev.ingestJobValidations,
      validations: updatedValidations
    };

    this.setState({ hasErrors: this.jobHasErrors(ingestJobValidations) });

    return {
      ingestJobValidations
    };
  };

  render() {
    const { ingestJobValidations, inventorySheetId } = this.props;
    const { hasErrors, showAllRows } = this.state;

    const rowHasErrors = object =>
      object && object.errors && object.errors.length > 0;

    return (
      <>
        <Mutation
          mutation={START_VALIDATION}
          variables={{ id: inventorySheetId }}
        >
          {(mutate, { data, loading, error }) => <DoMutation mutate={mutate} />}
        </Mutation>

        <div className="text-sm py-4">
          <input type="checkbox" /> Show all rows
        </div>

        <table>
          <thead>
            <tr>
              <th>Job Id</th>
              <th>Status</th>
              <th>Content</th>
              <th>Errors</th>
            </tr>
          </thead>
          <tbody>
            {ingestJobValidations.validations.map(({ id, object }) => (
              <tr key={id} className={rowHasErrors(object) ? "error" : ""}>
                <td>{id}</td>
                <td>{object && object.status}</td>
                <td>{object && object.content}</td>
                <td>
                  {rowHasErrors(object)
                    ? object.errors.map((error, index) => (
                        <span key={index}>{error}</span>
                      ))
                    : ""}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <ButtonGroup>
          {!hasErrors && <UIButton label="Approve inventory sheet groupings" />}
          <UIButton
            classes="btn-warning"
            label="Delete job and re-upload inventory sheet"
          />
        </ButtonGroup>
      </>
    );
  }
}

export default InventorySheetValidations;
