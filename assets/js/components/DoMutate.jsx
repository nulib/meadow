import React from "react";

export default class DoMutation extends React.Component {
  componentDidMount() {
    const { mutate } = this.props;
    mutate();
  }

  render() {
    return null;
  }
}
