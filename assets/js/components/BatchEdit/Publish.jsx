import React from "react";
import PropTypes from "prop-types";

function BatchEditPublish({ batchPublish, setBatchPublish }) {
  const { publish, unpublish } = batchPublish;

  return (
    <div data-testid="batch-edit-publish-wrapper" className="is-flex">
      <div className="field mt-3">
        <input
          className="is-checkradio"
          id={`publish`}
          type="checkbox"
          name={`publish`}
          onChange={() =>
            setBatchPublish({ publish: !publish, unpublish: false })
          }
          checked={publish}
        />
        <label htmlFor={`publish`}>Published</label>
      </div>

      <div className="field mt-3">
        <input
          className="is-checkradio"
          id={`unpublish`}
          type="checkbox"
          name={`unpublish`}
          onChange={() =>
            setBatchPublish({ publish: false, unpublish: !unpublish })
          }
          checked={unpublish}
        />
        <label htmlFor={`unpublish`}>Unpublished</label>
      </div>
    </div>
  );
}

BatchEditPublish.propTypes = {
  batchPublish: PropTypes.object,
  setBatchPublish: PropTypes.func,
};

export default BatchEditPublish;
