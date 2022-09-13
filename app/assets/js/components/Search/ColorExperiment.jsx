import React, { useState } from "react";
import { HslColorPicker } from "react-colorful";

export default function ColorExperiment() {
  const styles = {
    reactColorful: {
      width: 500,
      height: 500,
    },
  };
  const [color, setColor] = useState({ h: 0, s: 0, l: 100 });
  const [results, setResults] = useState([]);

  const handleColorChange = (color) => {
    setColor(color);
    console.log(color);

    fetch(
      "https://devbox.library.northwestern.edu:3001/elasticsearch/meadow/_search",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(query(color.h, color.s, color.l)),
      }
    )
      .then((response) => {
        return response.json();
      })
      .then((results) => {
        console.log(results.hits.hits);
        setResults(results.hits.hits);
      });
  };

  const query = (h, _s, _l) => {
    return {
      _source: {
        includes: ["id", "title", "representativeFileSet", "color"],
      },
      query: {
        nested: {
          path: "color",
          query: {
            bool: {
              must: [
                {
                  range: {
                    "color.h": {
                      gte: h - 20 < 0 ? 0 : h - 20,
                      lte: h + 20 > 360 ? 360 : h + 20,
                    },
                  },
                },
                {
                  range: {
                    "color.s": {
                      gte: 0,
                      lte: 100,
                    },
                  },
                },
                {
                  range: {
                    "color.l": {
                      gte: 0,
                      lte: 100,
                    },
                  },
                },
              ],
            },
          },
        },
      },
    };
  };

  return (
    <div>
      <HslColorPicker
        style={styles.reactColorful}
        color={color}
        onChange={handleColorChange}
      />
      <hr />
      <p>Selected Color: {JSON.stringify(color)}</p>
      <p>Results: {results && results.length}</p>
      <hr />
      {results &&
        results.map((result, index) => {
          return (
            <div
              id={index}
              className="card is-shadowless"
              style={{ width: "30%", float: "left", margin: 20 }}
            >
              <div className="card-image">
                <figure className="image is-square">
                  <img
                    src={`${result._source.representativeFileSet.url}/square/300,300/0/default.jpg`}
                  />
                </figure>
                <p>{result._source.title}</p>
                <p>{JSON.stringify(result._source.color)}</p>
              </div>
            </div>
          );
        })}
    </div>
  );
}
