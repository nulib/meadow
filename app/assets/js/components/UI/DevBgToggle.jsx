import React from "react";

// Default color light blue
// You can update this in your browser's console by setting a new hex value for "devBg" property
const BG_HEX_VALUE = "#7fcecd";
function UIDevBgToggle(props) {
  const toggleRef = React.useRef();
  const [devBg, setDevBg] = React.useState(localStorage.getItem("devBg") || "");

  function handleChange(e) {
    const val = toggleRef.current.checked ? BG_HEX_VALUE : "";
    localStorage.setItem("devBg", val);
    setDevBg(val);
    location.reload();
  }

  return (
    <div className="navbar-item">
      <input
        ref={toggleRef}
        id="devBgToggle"
        type="checkbox"
        name="devBgToggle"
        className="switch"
        checked={devBg}
        onChange={handleChange}
      />
      <label htmlFor="devBgToggle">Dev bg color?</label>
    </div>
  );
}

UIDevBgToggle.propTypes = {};

export default UIDevBgToggle;
