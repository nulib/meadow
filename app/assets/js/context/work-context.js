import React from "react";

const WorkStateContext = React.createContext();
const WorkDispatchContext = React.createContext();

const defaultState = {
  activeMediaFileSet: null,
  webVttModal: {
    fileSetId: null,
    isOpen: false,
    webVttString: "",
  },
  workTypeId: null,
};

function workReducer(state, action) {
  switch (action.type) {
    case "toggleWebVttModal": {
      return {
        ...state,
        webVttModal: {
          fileSetId: action.fileSetId,
          isOpen: Boolean(action.fileSetId),
          webVttString: action.webVttString,
        },
      };
    }
    case "updateActiveMediaFileSet": {
      const workTypeId = action.workTypeId || state.workTypeId;
      return {
        ...state,
        activeMediaFileSet: { ...action.fileSet },
      };
    }
    case "updateWorkType": {
      return {
        ...state,
        workTypeId: action.workTypeId,
      };
    }
    default: {
      throw new Error(`Unhandled action type: ${action.type}`);
    }
  }
}

function WorkProvider({ initialState = defaultState, children }) {
  const [state, dispatch] = React.useReducer(workReducer, initialState);
  return (
    <WorkStateContext.Provider value={state}>
      <WorkDispatchContext.Provider value={dispatch}>
        {children}
      </WorkDispatchContext.Provider>
    </WorkStateContext.Provider>
  );
}

function useWorkState() {
  const context = React.useContext(WorkStateContext);
  if (context === undefined) {
    throw new Error("useWorkState must be used within a WorkProvider");
  }
  return context;
}

function useWorkDispatch() {
  const context = React.useContext(WorkDispatchContext);
  if (context === undefined) {
    throw new Error("useWorkDispatch must be used within a WorkProvider");
  }
  return context;
}

export { WorkProvider, useWorkState, useWorkDispatch };
