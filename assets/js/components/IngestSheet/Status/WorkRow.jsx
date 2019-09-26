import React from "react";

const IngestSheetStatusWorkRow = () => {
  return (
    <>
      <div className="w-full flex py-4">
        <div className="w-1/3">
          <img src="/images/placeholder-content.png" />
        </div>
        <div className="w-2/3 pl-4">
          <dl className="inline">
            <dt>Id:</dt>
            <dd>01DNQ5CV19D622172JNKM3XB82</dd>
            <dt>Accession Number:</dt>
            <dd>ABC123</dd>
            <dt>File Sets:</dt>
            <dd>
              <ul>
                <li>098722345-23452345.tif</li>
                <li>0987098we2345-2345.tif</li>
                <li>23452345-23452345.tif</li>
              </ul>
            </dd>
          </dl>
        </div>
      </div>
    </>
  );
};

export default IngestSheetStatusWorkRow;
