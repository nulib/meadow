import React from "react";

const BatchStateContext = React.createContext();
const BatchDispatchContext = React.createContext();

const defaultState = {
  editAndViewWorks: [],
  filteredQuery: null,
  parsedAggregations: null,
  removeItems: null,
  resultStats: null,
};

/**
 * Update the list of Batch Edit remove items
 *
 * @param {Object} state BatchEdit state
 * @param {Object} action Action object
 * @param {String} action.fieldName Name of the controlledTerm metadata field ie. "contributor" or "subject"
 * @param {String} action.key The faceted valued used to identify a unique Controlled Term value
 *
 * @returns {Object} And object with one property (fieldName value), and holds an array of updated items
 */
function calculateItemList(state, action) {
  const { fieldName, key } = action;
  if (!fieldName) return {};

  const previousItems =
    state.removeItems && state.removeItems[fieldName]
      ? [...state.removeItems[fieldName]]
      : [];
  const index = previousItems.indexOf(key);

  // Add new value to the list
  if (index === -1) {
    return { [fieldName]: [...previousItems, key] };
  }

  // Remove value from list
  previousItems.splice(index, 1);
  return { [fieldName]: previousItems };
}

function batchReducer(state, action) {
  switch (action.type) {
    case "clear": {
      return {
        ...state,
        ...defaultState,
      };
    }
    case "clearRemoveItems": {
      return {
        ...state,
        removeItems: {},
      };
    }
    case "updateRemoveItem": {
      return {
        ...state,
        removeItems: {
          ...state.removeItems,
          ...calculateItemList(state, action),
        },
      };
    }
    // This is new
    case "updateEditAndViewWorks": {
      return {
        ...state,
        editAndViewWorks: [...action.items],
      };
    }
    case "updateSearchResults": {
      return {
        ...state,
        filteredQuery: action.filteredQuery,
        resultStats: action.resultStats,
        parsedAggregations: action.parsedAggregations,
      };
    }
    default: {
      throw new Error(`Unhandled action type: ${action.type}`);
    }
  }
}

// By allowing "initialState" as a prop, we can pass in values in tests
function BatchProvider({ initialState = defaultState, children }) {
  const [state, dispatch] = React.useReducer(batchReducer, initialState);
  return (
    <BatchStateContext.Provider value={state}>
      <BatchDispatchContext.Provider value={dispatch}>
        {children}
      </BatchDispatchContext.Provider>
    </BatchStateContext.Provider>
  );
}

function useBatchState() {
  const context = React.useContext(BatchStateContext);
  if (context === undefined) {
    throw new Error("useBatchState must be used within a BatchProvider");
  }
  return context;
}

function useBatchDispatch() {
  const context = React.useContext(BatchDispatchContext);
  if (context === undefined) {
    throw new Error("useBatchDispatch must be used within a BatchProvider");
  }
  return context;
}
export { BatchProvider, useBatchState, useBatchDispatch };
