import React from "react";
import { Link } from "react-router-dom";
import UICard from "../UI/Card";
import EditIcon from "../../../css/fonts/zondicons/edit-pencil.svg";
import OpenSeadragonViewer from "openseadragon-react-viewer";

const Work = ({ work }) => {
  return (
    <div data-testid="work">
      <header className="flex justify-between mb-8">
        <h1>{work.accessionNumber}</h1>
        <button to="/" className="btn">
          <EditIcon className="icon" /> Edit Work
        </button>
      </header>
      <section className="mb-16">
        <OpenSeadragonViewer manifestUrl="https://iiif.stack.rdc.library.northwestern.edu/public/06/20/ea/ca/-5/4e/6-/41/81/-a/85/8-/39/dd/ea/0b/b1/c5-manifest.json" />
      </section>
      <section className="mb-12">
        <ul className="nav-tabs">
          <li className="tab active">
            <a href="#">Descriptive</a>
          </li>
          <li className="tab">
            <a href="#">Administrative</a>
          </li>
          <li className="tab">
            <a href="#">Preservation</a>
          </li>
          <li className="tab">
            <a href="#">Files</a>
          </li>
        </ul>
        <div className="nav-tabs-body">
          <h3>Description</h3>
          <p>
            For my birthday I got a humidifier and a de-humidifier. I put them
            in the same room and let them fight it out.For my birthday I got a
            humidifier and a de-humidifier. I put them in the same room and let
            them fight it out. For my birthday I got a humidifier and a
            de-humidifier. I put them in the same room and let them fight it
            out.For my birthday I got a humidifier and a de-humidifier. I put
            them in the same room and let them fight it out. For my birthday I
            got a humidifier and a de-humidifier. I put them in the same room
            and let them fight it out
          </p>
        </div>
      </section>
      <section>
        <UICard>
          <div className="mb-4">
            <h3>Date Created</h3>
            <p>2019-01-01</p>
          </div>
          <div className="mb-4">
            <h3>Creators</h3>
            <ul>
              <li>
                <Link to="/">Creator 1 as a link</Link>
              </li>
              <li>
                <Link to="/">Creator 2 as a link</Link>
              </li>
              <li>
                <Link to="/">Creator 3 as a link</Link>
              </li>
            </ul>
          </div>
          <div className="mb-4">
            <h3>Contributors</h3>
            <ul>
              <li>
                <Link to="/">Contributor 1 as a link</Link>
              </li>
              <li>
                <Link to="/">Contributor 2 as a link</Link>
              </li>
              <li>
                <Link to="/">Contributor 3 as a link</Link>
              </li>
            </ul>
          </div>
          <div className="mb-4">
            <h3>Subject</h3>
            <ul>
              <li>
                <Link to="/">Subject 1 as a link</Link>
              </li>
              <li>
                <Link to="/">Subject 2 as a link</Link>
              </li>
              <li>
                <Link to="/">Subject 3 as a link</Link>
              </li>
            </ul>
          </div>
        </UICard>
      </section>
    </div>
  );
};

export default Work;
