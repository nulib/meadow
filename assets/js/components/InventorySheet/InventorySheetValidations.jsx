import React, { useState } from "react";
import gql from "graphql-tag";
import { Mutation } from "react-apollo";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import PropTypes from "prop-types";
import DoMutation from "../Shared/DoMutate"


const SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS = gql`
  subscription IngestJobValidationUpdate($ingestJobId: String!) {
    ingestJobValidationUpdate(ingestJobId:$ingestJobId) { 
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
    validateIngestJob(ingestJobId:$id){
      message
    }
  }
`;



class InventorySheetValidations extends React.Component {
  static propTypes = {
    inventorySheetId: PropTypes.string.isRequired,
    ingestJobValidations: PropTypes.object.isRequired,
    subscribeToInventorySheetValidations: PropTypes.func.isRequired,
  };

  componentDidMount() {
    this.props.subscribeToInventorySheetValidations({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS,
      variables: { ingestJobId: this.props.inventorySheetId },
      updateQuery: this.handleValidationUpdate
    });
  }

  handleValidationUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;
    const newValidation = subscriptionData.data.ingestJobValidationUpdate;

    const index = prev.ingestJobValidations.validations.findIndex(({ id }) => id === newValidation.id)

    let updatedValidations;
    if (index === -1) {
      updatedValidations = [newValidation, ...prev.ingestJobValidations.validations]
    } else {
      updatedValidations = prev.ingestJobValidations.validations;
      updatedValidations[index] = newValidation;
    }

    return {
      ingestJobValidations: {
        ...prev.ingestJobValidations,
        validations: updatedValidations
      }
    };
  }

  render() {
    const { ingestJobValidations, inventorySheetId } = this.props;

    return (
      <>
        <Mutation mutation={START_VALIDATION} variables={{ id: inventorySheetId }}>
          {(mutate, { data, loading, error }) => (
            <DoMutation mutate={mutate} />
          )}
        </Mutation>
        <div>
          {ingestJobValidations.validations.map(({ id, object }) => (
            <p key={id}><strong>{id}</strong> :
              : {object && object.status} :
              : [{object && object.content}] :
              : [{object.errors && object.errors.length ? object.errors.map((error, index) => <span key={index}>{error}</span>) : ""}]
            </p>
          ))}
        </div>
      </>
    );
  }
}

export default InventorySheetValidations;