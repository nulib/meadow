import React, { useState, useEffect } from "react";
import UIButton from "../UI/Button";
import { useChannel } from "use-phoenix-channel";
import isNumber from 'is-number';

const InventorySheetStatus = (props) => {
  const initialState = {
    job: {status: 'pending', errors: []},
    csv: {status: 'pending', errors: []},
    headers: {status: 'pending', errors: []},
    row: []
  }

  const channelName = `job:${props.inventorySheetId}`;

  const statusReducer = (state, {event, payload}) => {
    switch(event) {
      case 'joined':
        try {
          broadcast("validate", { job_id: payload.channel });
        } catch {
          // TODO: Figure out if we're even ready to process messages
          // before we get here.
        }
        return state;
      case 'update':
        var step = state[payload.id[0]];
        var row = payload.id[1];
        if (isNumber(row)) {
          step[row] = payload.object;
        } else {
          step = payload.object;
        }
        return { 
          ...state, 
          [payload.id[0]]: step
        };
      default:
        return state;
    }
  }

  const [state, broadcast] = useChannel(channelName, statusReducer, initialState);

  const requestValidation = () => {
    broadcast("validate", { job_id: channelName })
  }

  return (
    <div>
      <ul className="validate">
      <li key="job" className={state.job.status}>Overall</li>
      <li key="csv" className={state.csv.status}>Inventory Sheet is a CSV</li>
      <li key="headers" className={state.headers.status}>Inventory Sheet has all required headers</li>
      {
        state.row.map((row, index) => {
          var content = row.content || {}
          return <li key={"row-"+index} className={row.status}>
            Row: { content.work_accession_number } { content.accession_number } { content.filename } { content.description }
          </li>
        })
      }
      </ul>
    </div>
  )
}

export default InventorySheetStatus;