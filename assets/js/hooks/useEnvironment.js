export default function useEnvironment() {
  switch (__HONEYBADGER_ENVIRONMENT__?.toUpperCase()) {
    case "PRODUCTION":
      return "PRODUCTION";
    case "STAGING":
      return "STAGING";
    default:
      return "DEV";
  }
}
