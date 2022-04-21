function handler(event) {
  var request = event.request;
  var response = event.response;
  var origin = request.headers.origin ? request.headers.origin.value : "*";
  response.headers['access-control-allow-origin'] = { value: origin };
  return response;
}