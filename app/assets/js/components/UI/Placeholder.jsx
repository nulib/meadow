import PropTypes from "prop-types";
import React from "react";

function UIPlaceholder({ workTypeId }) {
  let path = <></>;

  switch (workTypeId) {
    case "AUDIO":
      path = audioPath;
      break;
    case "IMAGE":
      path = imagePath;
      break;
    case "VIDEO":
      path = videoPath;
      break;
    default:
      break;
  }

  return (
    <div
      className="has-background-light is-flex is-justify-content-center"
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width: "100%",
        height: "100%",
      }}
    >
      <svg
        className="image is-48x48 is-align-self-center is-align-items-center"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 512 512"
        data-testid="placeholder-svg"
      >
        <title>{workTypeId} Placeholder</title>
        {path}
      </svg>
    </div>
  );
}

const fill = "#716c6b";

const audioPath = (
  <>
    <path
      fill={fill}
      d="M232 416a23.88 23.88 0 01-14.2-4.68 8.27 8.27 0 01-.66-.51L125.76 336H56a24 24 0 01-24-24V200a24 24 0 0124-24h69.75l91.37-74.81a8.27 8.27 0 01.66-.51A24 24 0 01256 120v272a24 24 0 01-24 24zm-106.18-80zm-.27-159.86zM320 336a16 16 0 01-14.29-23.19c9.49-18.87 14.3-38 14.3-56.81 0-19.38-4.66-37.94-14.25-56.73a16 16 0 0128.5-14.54C346.19 208.12 352 231.44 352 256c0 23.86-6 47.81-17.7 71.19A16 16 0 01320 336z"
    />
    <path
      fill={fill}
      d="M368 384a16 16 0 01-13.86-24C373.05 327.09 384 299.51 384 256c0-44.17-10.93-71.56-29.82-103.94a16 16 0 0127.64-16.12C402.92 172.11 416 204.81 416 256c0 50.43-13.06 83.29-34.13 120a16 16 0 01-13.87 8z"
    />
    <path
      fill={fill}
      d="M416 432a16 16 0 01-13.39-24.74C429.85 365.47 448 323.76 448 256c0-66.5-18.18-108.62-45.49-151.39a16 16 0 1127-17.22C459.81 134.89 480 181.74 480 256c0 64.75-14.66 113.63-50.6 168.74A16 16 0 01416 432z"
    />
  </>
);

const imagePath = (
  <path
    fill={fill}
    d="M416 64H96a64.07 64.07 0 00-64 64v256a64.07 64.07 0 0064 64h320a64.07 64.07 0 0064-64V128a64.07 64.07 0 00-64-64zm-80 64a48 48 0 11-48 48 48.05 48.05 0 0148-48zM96 416a32 32 0 01-32-32v-67.63l94.84-84.3a48.06 48.06 0 0165.8 1.9l64.95 64.81L172.37 416zm352-32a32 32 0 01-32 32H217.63l121.42-121.42a47.72 47.72 0 0161.64-.16L448 333.84z"
  />
);

const videoPath = (
  <path
    fill={fill}
    d="M464 384.39a32 32 0 01-13-2.77 15.77 15.77 0 01-2.71-1.54l-82.71-58.22A32 32 0 01352 295.7v-79.4a32 32 0 0113.58-26.16l82.71-58.22a15.77 15.77 0 012.71-1.54 32 32 0 0145 29.24v192.76a32 32 0 01-32 32zM268 400H84a68.07 68.07 0 01-68-68V180a68.07 68.07 0 0168-68h184.48A67.6 67.6 0 01336 179.52V332a68.07 68.07 0 01-68 68z"
  />
);

UIPlaceholder.propTypes = {
  workTypeId: PropTypes.string,
};

export default UIPlaceholder;
