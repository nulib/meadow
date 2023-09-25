import React from "react";
import { Router } from "react-router-dom";
import { render } from "@testing-library/react";
import { createMemoryHistory } from "history";
import { MockedProvider } from "@apollo/client/testing";
import { resolvers } from "../client-local";
import { useForm, FormProvider } from "react-hook-form";
import { DragDropContext, Droppable } from "react-beautiful-dnd";

/**
 * Testing Library utility function to wrap tested component in React Hook Form
 * @param {ReactElement} ui A React component
 * @param objectParameters
 * @param {Object} objectParameters.defaultValues Initial form values to pass into
 * React Hook Form, which you can then assert against
 * @param {Array} objectParameters.toPassBack React Hook Form method names which we'd
 * like to pass back and use in tests.  A primary use case is sending back 'setError',
 * so we can manually setErrors on React Hook Form components and test error handling
 */
export function renderWithReactHookForm(
  ui,
  { defaultValues = {}, toPassBack = [] } = {},
) {
  let reactHookFormMethods = {};

  const Wrapper = ({ children }) => {
    const methods = useForm({ defaultValues });
    for (let reactHookFormItem of toPassBack) {
      reactHookFormMethods[reactHookFormItem] = methods[reactHookFormItem];
    }
    return <FormProvider {...methods}>{children}</FormProvider>;
  };

  return {
    ...render(ui, { wrapper: Wrapper }),
    reactHookFormMethods,
  };
}

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
  } = {},
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
  } = {},
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
      //resolvers={resolvers}
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

/**
 * Higher order helper function which wraps a component w/ React Beautiful DND
 * @param {React Component} WrappedComponent to pass into
 * @param {*} restProps any other remaining props
 * @returns {React Component}
 */
export function withReactBeautifulDND(WrappedComponent, restProps) {
  return (
    <DragDropContext>
      <Droppable droppableId="list">
        {(provided) => (
          <div ref={provided.innerRef} {...provided.droppableProps}>
            <WrappedComponent {...restProps} />
          </div>
        )}
      </Droppable>
    </DragDropContext>
  );
}

/**
 * Higher order helper function which wraps a component w/ React Hook Form
 * @param {React Component} WrappedComponent to pass into
 * @param {*} restProps any other remaining props
 * @returns {React Component}
 */
export function withReactHookForm(WrappedComponent, restProps) {
  const HOC = () => {
    const methods = useForm();

    return (
      <FormProvider {...methods}>
        <WrappedComponent {...restProps} />
      </FormProvider>
    );
  };

  return HOC;
}
