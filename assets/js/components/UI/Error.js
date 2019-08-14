import React from "react";
import PropTypes from "prop-types";

// Render runtime errors, including GraphQL errors and network errors.
//
// The error passed as a prop to this component is an Apollo Client
// 'QueryResult' object that has 'graphQLErrors' and 'networkError' properties.

const Error = ({ error }) => {
  if (!error || !error.message) return null;

  const isNetworkError =
    error.networkError &&
    error.networkError.message &&
    error.networkError.statusCode;

  const hasGraphQLErrors = error.graphQLErrors && error.graphQLErrors.length;

  let errorMessage;

  if (isNetworkError) {
    if (error.networkError.statusCode === 404) {
      errorMessage = (
        <h3>
          <code>404: Not Found</code>
        </h3>
      );
    } else {
      errorMessage = (
        <>
          <h3>Network Error!</h3>
          <code>
            {error.networkError.statusCode}: {error.networkError.message}
          </code>
        </>
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
                  {Object.keys(details).map(key => (
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
  } else {
    errorMessage = (
      <>
        <h3>Whoops!</h3>
        <p>{error.message}</p>
      </>
    );
  }

  return <div className="errors">{errorMessage}</div>;
};

Error.propTypes = {
  error: PropTypes.object
};

Error.defaultProps = {
  error: {}
};

export default Error;
