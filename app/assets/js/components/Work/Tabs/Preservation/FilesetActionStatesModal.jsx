import * as Dialog from "@radix-ui/react-dialog";

import {
  DialogClose,
  DialogContent,
  DialogOverlay,
  DialogTitle,
  DialogTrigger,
} from "@js/components/UI/Dialog/Dialog.styled";
import { Icon, Tag } from "@nulib/design-system";
import React, { useEffect } from "react";
import { useLazyQuery, useQuery } from "@apollo/client/react";

import { ACTION_STATES } from "@js/components/Work/work.gql";
import UIDate from "@js/components/UI/Date";

const FilesetActionsStatesModal = ({ closeModal, id, isVisible }) => {
  const [getActionStates, { data, error, loading }] =
    useLazyQuery(ACTION_STATES);

  useEffect(() => {
    if (id) {
      getActionStates({
        variables: {
          objectId: id,
        },
      });
    }
  }, [id]);

  if (loading) return <p>Loading ...</p>;
  if (error) return `Error! ${error}`;

  const columns = ["action", "outcome", "notes", "inserted at", "updated at"];
  const getTagProps = (actionState) => {
    return {
      isSuccess: actionState.outcome === "OK",
      isDanger: actionState?.outcome === "ERROR",
    };
  };

  return (
    <Dialog.Root open={isVisible} onOpenChange={closeModal}>
      <Dialog.Portal>
        <DialogOverlay />
        <DialogContent data-testid="fileset-action-states">
          <DialogClose>
            <Icon isSmall aria-label="Close">
              <Icon.Close />
            </Icon>
          </DialogClose>
          <DialogTitle css={{ textAlign: "left" }}>
            Fileset Action States
          </DialogTitle>
          {id && (
            <>
              <p className="mt-3 mb-3">Fileset Id: {id}</p>
              <table className="table" data-testid="action-states">
                <thead>
                  <tr>
                    {columns.map((column) => (
                      <th key={column} style={{ textTransform: "capitalize" }}>
                        {column}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data &&
                    data.actionStates.map((actionState, idx) => (
                      <tr key={idx} data-testid="action-state-row">
                        <td>{actionState.action}</td>
                        <td>
                          <Tag {...getTagProps(actionState)}>
                            {actionState.outcome}
                          </Tag>
                        </td>
                        <td>{actionState.notes}</td>
                        <td>
                          <UIDate dateString={actionState.insertedAt} />
                        </td>
                        <td>
                          <UIDate dateString={actionState.updatedAt} />
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </>
          )}
        </DialogContent>
      </Dialog.Portal>
    </Dialog.Root>
  );
};

export default FilesetActionsStatesModal;
