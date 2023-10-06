import { DragDropContext, Droppable } from "react-beautiful-dnd";
import { FormProvider, useForm } from "react-hook-form";

import { MockedProvider } from "@apollo/client/testing";
import React from "react";
import { Router } from "react-router-dom";
import { createMemoryHistory } from "history";
import { render } from "@testing-library/react";
import { resolvers } from "../client-local";

type UI = React.ReactElement<any, string | React.JSXElementConstructor<any>>;
type ReactChildren = React.ReactNode | React.ReactNodeArray;

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
  ui: UI,
  { defaultValues = {}, toPassBack = [] } = {},
) {
  let reactHookFormMethods = {};

  const Wrapper = ({ children }: { children: ReactChildren }) => {
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

type RenderWithRouterObject = {
  route?: string;
  history?: any;
  state?: {
    [key: string]: any;
  };
};

/**
 * Testing Library utility function to wrap tested component in React Router history
 * @param {ReactElement} ui A React element
 * @param objectParameters
 * @param objectParameters.route Starting route to feed React Router's history
 * @param objectParameters.history Override the history object if desired
 */
export function renderWithRouter(
  ui: UI,
  {
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] }),
    state = {},
  }: RenderWithRouterObject = {},
) {
  if (Object.keys(state).length > 0) {
    history.push(route, state);
  }

  const Wrapper = ({ children }: { children: ReactChildren }) => (
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

type RenderWithRouterApolloObject = {
  mocks?: any[];
  route?: string;
  history?: any;
  state?: {
    [key: string]: any;
  };
};

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
  ui: UI,
  {
    mocks = [],
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] }),
    state = {},
  }: RenderWithRouterApolloObject = {},
) {
  // This allows us to pass in history state variables in tests,
  // like we do in the real application
  if (Object.keys(state).length > 0) {
    history.push(route, state);
  }

  const Wrapper = ({ children }: { children: ReactChildren }) => (
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

export function renderWithApollo(ui: UI, { mocks = [] }) {
  const Wrapper = ({ children }: { children: ReactChildren }) => (
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
export function withReactBeautifulDND(
  WrappedComponent: React.FC,
  restProps: {
    [key: string]: any;
  } = {},
) {
  return (
    <DragDropContext onDragEnd={() => jest.fn()}>
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
export function withReactHookForm(
  WrappedComponent: React.FC,
  restProps: {
    [key: string]: any;
  },
) {
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
