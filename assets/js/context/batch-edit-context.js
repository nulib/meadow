import React from "react";

const BatchStateContext = React.createContext();
const BatchDispatchContext = React.createContext();

function batchReducer(state, action) {
  switch (action.type) {
    case "clear": {
      return {
        ...state,
        filteredQuery: null,
        resultStats: null,
        parsedAggregations: null,
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

function BatchProvider({ children }) {
  const [state, dispatch] = React.useReducer(batchReducer, {
    filteredQuery: null,
    resultStats: null,
    parsedAggregations: null,
  });
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
