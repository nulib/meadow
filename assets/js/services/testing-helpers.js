import React from "react";
import { Router } from "react-router-dom";
import { render } from "@testing-library/react";
import { createMemoryHistory } from "history";
import { MockedProvider } from "@apollo/client/testing";
import { ReactiveBase } from "@appbaseio/reactivesearch";
import { resolvers } from "../client-local";
import { useForm } from "react-hook-form";

/**
 * Testing Library utility function to wrap tested component in React Router history
 * @param {ReactElement} ui A React element
 * @param objectParameters
 * @param objectParameters.route Starting route to feed React Router's history
 * @param objectParameters.history Override the history object if desired
 */
export function renderWithRouter(
  ui,
  {
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] }),
    state = {},
  } = {}
) {
  if (Object.keys(state).length > 0) {
    history.push(route, state);
  }

  const Wrapper = ({ children }) => (
    <Router history={history}>{children}</Router>
  );

  return {
    ...render(ui, { wrapper: Wrapper }),
    // adding `history` to the returned utilities to allow us
    // to reference it in our tests (just try to avoid using
    // this to test implementation details).
    history,
  };
}

/**
 * Testing Library utility function to wrap tested component in Apollo Client's
 * MockProvider along with React Router
 * @param {ReactElement} ui React element
 * @param {Object} objectParameters
 * @param {Array} objectParameters.mocks Apollo Client MockProvider mock
 * @param {String} objectParameters.route Starting route to feed React Router's history
 * @param objectParameters.history Override the history object if desired
 */
export function renderWithRouterApollo(
  ui,
  {
    mocks = [],
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] }),
    state = {},
  } = {}
) {
  // This allows us to pass in history state variables in tests,
  // like we do in the real application
  if (Object.keys(state).length > 0) {
    history.push(route, state);
  }

  const Wrapper = ({ children }) => (
    <MockedProvider
      mocks={mocks}
      addTypename={false}
      //resolvers={resolvers}
      defaultOptions={{
        watchQuery: { fetchPolicy: "no-cache" },
        query: { fetchPolicy: "no-cache" },
      }}
    >
      <Router history={history}>{children}</Router>
    </MockedProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper }),
  };
}

export function renderWithApollo(ui, { mocks = [] }) {
  const Wrapper = ({ children }) => (
    <MockedProvider
      mocks={mocks}
      addTypename={false}
      resolvers={resolvers}
      defaultOptions={{
        watchQuery: { fetchPolicy: "no-cache" },
        query: { fetchPolicy: "no-cache" },
      }}
    >
      {children}
    </MockedProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper }),
  };
}

export function withReactHookFormControl(WrappedComponent, restProps) {
  const HOC = () => {
    const { control, register } = useForm({
      defaultValues: {
        imaMulti: [{ value: "New Ima Multi" }],
      },
    });
    return (
      <WrappedComponent control={control} register={register} {...restProps} />
    );
  };

  return HOC;
}
