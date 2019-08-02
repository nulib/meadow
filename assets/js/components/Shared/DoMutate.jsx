import React from 'react';
import { Mutation } from 'react-apollo';

export default class DoMutation extends React.Component {
  componentDidMount() {
    const { mutate } = this.props;
    mutate();
  };

  render() {
    return null;
  };
};