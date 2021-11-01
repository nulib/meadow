import React from "react";
import PropTypes from "prop-types";
import UIPlaceholder from "./Placeholder";

function UIWorkImage({ imageUrl = "", size = 128, workTypeId }) {
  const figure = imageUrl ? (
    <img
      src={`${imageUrl}/square/${size},${size}/0/default.jpg`}
      data-testid="image-source"
    />
  ) : (
    <UIPlaceholder workTypeId={workTypeId} />
  );

  return (
    <figure data-testid="work-image" className={`image is-square`}>
      {figure}
    </figure>
  );
}

UIWorkImage.propTypes = {
  imageUrl: PropTypes.string.isRequired,
  size: PropTypes.number,
  workTypeId: PropTypes.oneOf(["AUDIO", "IMAGE", "VIDEO"]).isRequired,
};

export default UIWorkImage;
