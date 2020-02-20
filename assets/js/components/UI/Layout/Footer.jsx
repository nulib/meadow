import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const styles = {
  span: {
    paddingLeft: "1rem"
  }
};

const UILayoutFooter = () => {
  return (
    <footer className="footer">
      <div className="content has-text-centered">
        <p>
          <span className="icon">
            <FontAwesomeIcon icon="leaf" />
          </span>
          <strong>Meadow v1.0</strong> by{" "}
          <a href="https://github.com/nulib" target="_blank">
            @nulib
          </a>
          .{" "}
          <span style={styles.span}>
            An{" "}
            <a href="https://elixir-lang.org/" target="_blank">
              Elixir
            </a>
            /
            <a href="https://reactjs.org/" target="_blank">
              React
            </a>{" "}
            repository application.{" "}
          </span>
        </p>
      </div>
    </footer>
  );
};

export default UILayoutFooter;
