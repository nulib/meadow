import React from "react";
import PropTypes from "prop-types";

function UIWorkImage({ imageUrl, size = 128 }) {
  if (!imageUrl) {
    return (
      <img
        data-testid="image-source"
        src={`https://bulma.io/images/placeholders/${size}x${size}.png`}
      />
    );
  }

  return (
    <img
      data-testid="image-source"
      src={`${imageUrl}/square/${size},${size}/0/default.jpg`}
    />
  );
}

UIWorkImage.propTypes = {
  imageUrl: PropTypes.string.isRequired,
  size: PropTypes.number,
};

export default UIWorkImage;
