import React from "react";
import { Link } from "react-router-dom";

import Main from "../components/Main";

export default class FetchDataPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = { languages: [], loading: true };

    // Get the data from our API.
    fetch("/api/languages")
      .then(response => response.json())
      .then(data => {
        this.setState({ languages: data.data, loading: false });
      });
  }

  renderLanguagesTable(languages) {
    return (
      <table>
        <thead>
          <tr>
            <th>Language</th>
            <th>Example proverb</th>
          </tr>
        </thead>
        <tbody>
          {languages.map(language => (
            <tr key={language.id}>
              <td>{language.name}</td>
              <td>{language.proverb}</td>
            </tr>
          ))}
        </tbody>
      </table>
    );
  }

  render() {
    const content = this.state.loading ? (
      <p>
        <em>Loading...</em>
      </p>
    ) : (
      this.renderLanguagesTable(this.state.languages)
    );

    return (
      <Main>
        <h1>Fetch Data</h1>
        <p>
          This component demonstrates fetching data from the Phoenix API
          endpoint.
        </p>
        {content}
        <br />
        <br />
        <p>
          <Link to="/">Back to home</Link>
        </p>
      </Main>
    );
  }
}
