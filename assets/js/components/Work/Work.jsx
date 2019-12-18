import React from "react";
import { Link } from "react-router-dom";
import UICard from "../UI/Card";
import EditIcon from "../../../css/fonts/zondicons/edit-pencil.svg";
import UISelect from "../UI/Select";

const Work = ({ work }) => {
  const handleSelectChange = e => {
    console.log("changed", e.target.value);
  };

  const buildGallery = (count = 3) => {
    let images = [];
    do {
      images.push(
        <img
          key={count}
          src="/images/placeholder-content.png"
          className="w-40 cursor-pointer"
        />
      );
      count--;
    } while (count !== 0);
    return images;
  };

  return (
    <div data-testid="work">
      <header className="flex justify-between mb-8">
        <h1>{work.accessionNumber}</h1>
        <button to="/" className="btn">
          <EditIcon className="icon" /> Edit Work
        </button>
      </header>
      <section className="mb-16">
        <UISelect
          data-testid="work-select"
          onChange={handleSelectChange}
          options={[
            { value: "", label: "Select one..." },
            { value: 1, label: "some option" },
            { value: 2, label: "another option" },
            { value: 3, label: "ho ho ho" }
          ]}
        />
        <img src="/images/placeholder-content.png" />
        <div className="flex justify-around">{buildGallery(5)}</div>
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
