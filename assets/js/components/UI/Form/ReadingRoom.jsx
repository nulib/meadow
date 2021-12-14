import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import { useFormContext } from "react-hook-form";
import UIFormReadingRoomHelperText from "@js/components/UI/Form/ReadingRoomHelperText";

function UIFormReadingRoom({ value = false, isEditing = false }) {
  const context = useFormContext();

  return (
    <UIFormField label="Reading Room">
      <>
        <input
          data-testid="checkbox-reading-room"
          {...context.register("readingRoom")}
          className="is-checkradio"
          id={`reading-room`}
          type="checkbox"
          disabled={!isEditing}
          defaultChecked={value}
        />
        <label
          className="pl-0"
          htmlFor={`reading-room`}
          data-testid="label-reading-room"
        ></label>
        <UIFormReadingRoomHelperText />
      </>
    </UIFormField>
  );
}

UIFormReadingRoom.propTypes = {
  value: PropTypes.bool,
  isEditing: PropTypes.bool,
};

export default UIFormReadingRoom;
