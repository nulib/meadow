module.exports = {
  theme: {
    container: {
      padding: "1rem"
    },
    extend: {
      colors: {
        "blue-gray": "102a43",
        "danger-dark": "#ef4e4e",
        "danger-light": "#ffe3e3"
      }
    },
    fontFamily: {
      display: ["AkkuratPro-Regular", "sans-serif"],
      body: ["AkkuratPro-Regular", "sans-serif"]
    },
    spinner: theme => ({
      default: {
        color: "#686d70", // color you want to make the spinner
        size: "4em", // size of the spinner (used for both width and height)
        border: "3px", // border-width of the spinner (shouldn't be bigger than half the spinner's size)
        speed: "500ms" // the speed at which the spinner should rotate
      }
    })
  },
  variants: {
    spinner: ["responsive"],
    tableLayout: ["responsive"]
  },
  plugins: [
    require("tailwindcss-spinner")() // no options to configure
  ]
};
