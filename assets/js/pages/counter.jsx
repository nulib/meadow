import React from "react";
import { Link } from "react-router-dom";

import Main from "../components/Main";

const initialState = { currentCount: 0 };

export default class CounterPage extends React.Component {
  constructor(props) {
    super(props);

    // Set the initial state of the component in a constructor.
    this.state = initialState;
  }

  render() {
    return (
      <Main>
        <h1>Counter</h1>
        <p>
          The Counter is the simplest example of what you can do with a React
          component.
        </p>
        <p>
          Current count: <strong>{this.state.currentCount}</strong>
        </p>
        {/* We apply an onClick event to these buttons to their corresponding functions */}
        <button className="button" onClick={this.incrementCounter}>
          Increment counter
        </button>{" "}
        <button
          className="button button-outline"
          onClick={this.decrementCounter}
        >
          Decrement counter
        </button>{" "}
        <button className="button button-clear" onClick={this.resetCounter}>
          Reset counter
        </button>
        <br />
        <br />
        <p>
          <Link to="/">Back to home</Link>
        </p>
      </Main>
    );
  }

  incrementCounter = () => {
    this.setState({
      currentCount: this.state.currentCount + 1
    });
  };

  decrementCounter = () => {
    this.setState({
      currentCount: this.state.currentCount - 1
    });
  };

  resetCounter = () => {
    this.setState({
      currentCount: 0
    });
  };
}
