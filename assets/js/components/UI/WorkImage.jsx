import React from "react";
import PropTypes from "prop-types";

function UIWorkImage({ imageUrl = "", size = 128 }) {
  const src = imageUrl
    ? `${imageUrl}/square/${size},${size}/0/default.jpg`
    : `/images/placeholder.png`;

  return (
    <figure data-testid="work-image" className={`image is-${size}x${size}`}>
      <img src={src} data-testid="image-source" />
    </figure>
  );
}

UIWorkImage.propTypes = {
  imageUrl: PropTypes.string.isRequired,
  size: PropTypes.number,
};

export default UIWorkImage;
