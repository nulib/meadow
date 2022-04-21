import React from "react";
import PropTypes from "prop-types";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

function MediaPlayerSwitcher({ fileSets }) {
  const workState = useWorkState();
  const dispatch = useWorkDispatch();

  const handleSelectChange = (e) => {
    dispatch({
      type: "updateActiveMediaFileSet",
      fileSet: fileSets.find((fs) => fs.id === e.target.value),
    });
  };

  return (
    <div className="block">
      <div className="field">
        <div className="control">
          <div className="select">
            <select
              value={workState?.activeMediaFileSet?.id}
              onChange={handleSelectChange}
              data-testid="media-player-switcher"
            >
              {fileSets.map((option) => (
                <option
                  key={option.id}
                  value={option.id}
                  data-testid="switcher-option"
                >
                  {option.coreMetadata?.label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>
    </div>
  );
}

MediaPlayerSwitcher.propTypes = {
  fileSets: PropTypes.array,
};

export default MediaPlayerSwitcher;
