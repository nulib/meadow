import React from "react";
import PropTypes from "prop-types";
import UIAlert from "./Alert";

// Render runtime errors, including GraphQL errors and network errors.
//
// The error passed as a prop to this component is an Apollo Client
// 'QueryResult' object that has 'graphQLErrors' and 'networkError' properties.

const Error = ({ error }) => {
  if (!error.message) return null;

  const isNetworkError =
    error.networkError &&
    error.networkError.message &&
    error.networkError.statusCode;

  const hasGraphQLErrors = error.graphQLErrors && error.graphQLErrors.length;

  let errorMessage;

  if (isNetworkError) {
    if (error.networkError.statusCode === 404) {
      return (
        <UIAlert type="is-danger" title="Network Error" body="404: Not Found" />
      );
    } else {
      return (
        <UIAlert
          type="is-danger"
          title="Network Error"
          body={`${error.networkError.statusCode}: ${error.networkError.message}`}
        />
      );
    }
  } else if (hasGraphQLErrors) {
    errorMessage = (
      <>
        <ul>
          {error.graphQLErrors.map(({ message, details }, i) => (
            <li key={i}>
              <span className="message">{message}</span>
              {details && (
                <ul>
                  {Object.keys(details).map((key) => (
                    <li key={key}>
                      {key} {details[key]}
                    </li>
                  ))}
                </ul>
              )}
            </li>
          ))}
        </ul>
      </>
    );
    return (
      <UIAlert type="is-danger" title="GraphQL Error" body={errorMessage} />
    );
  } else {
    return <UIAlert type="is-danger" title="Whoops!" body={error.message} />;
  }
};

Error.propTypes = {
  error: PropTypes.shape({
    message: PropTypes.string,
  }),
};

Error.defaultProps = {
  error: {},
};

export default Error;
